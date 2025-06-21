import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:async';

class DoctorAppointmentScreen extends StatefulWidget {
  const DoctorAppointmentScreen({super.key});

  @override
  _DoctorAppointmentScreenState createState() => _DoctorAppointmentScreenState();
}

class _DoctorAppointmentScreenState extends State<DoctorAppointmentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime selectedDate = DateTime.now();
  DateTime? filterDate;
  User? _currentUser;
  String? _doctorId;
  bool _isLoading = true;
  bool _isSearching = false;
  String _searchQuery = '';
  Map<String, dynamic>? _doctorInfo;
  Timer? _debounce;
  final Map<String, String> _patientNameCache = {};

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(_onSearchChanged);
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _doctorId = _currentUser!.uid;
        await _loadDoctorInfo();
      } else {
        _showSnackBar('Please sign in to view appointments.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error initializing app: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDoctorInfo() async {
    try {
      final doc = await _firestore.collection('doctors').doc(_doctorId).get();
      if (doc.exists) {
        setState(() => _doctorInfo = doc.data());
      } else {
        _showSnackBar('Doctor profile not found.', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', isError: true);
    }
  }

  Future<String> _getPatientName(String userId) async {
    if (_patientNameCache.containsKey(userId)) {
      return _patientNameCache[userId]!;
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final firstName = data['firstName']?.toString() ?? '';
        final lastName = data['lastName']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        _patientNameCache[userId] = fullName.isEmpty ? 'Unknown Patient' : fullName;
        return _patientNameCache[userId]!;
      }
      _patientNameCache[userId] = 'Unknown Patient';
      return 'Unknown Patient';
    } catch (e) {
      _showSnackBar('Error fetching patient name: $e', isError: true);
      _patientNameCache[userId] = 'Unknown Patient';
      return 'Unknown Patient';
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.roboto(fontSize: 14)),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: _isSearching
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search by patient name...',
            hintStyle: GoogleFonts.roboto(color: Colors.white70),
            border: InputBorder.none,
          ),
        )
            : Text(
          'My Appointments',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF2E86AB),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
            tooltip: _isSearching ? 'Cancel Search' : 'Search Appointments',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2E86AB),
              indicatorWeight: 3,
              labelColor: const Color(0xFF2E86AB),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Today'),
                Tab(text: 'Upcoming'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildDoctorInfoCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildUpcomingTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInfoCard() {
    if (_doctorInfo == null) return const SizedBox.shrink();

    return Semantics(
      label: 'Doctor Profile',
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E86AB), Color(0xFF1A237E)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E86AB).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: const Icon(Icons.person, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dr. ${_doctorInfo!['name'] ?? 'Unknown'}',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _doctorInfo!['specialization'] ?? 'Doctor',
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'License: ${_doctorInfo!['licenseNumber'] ?? 'N/A'}',
                    style: GoogleFonts.roboto(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Today\'s Schedule'),
          const SizedBox(height: 15),
          _buildTodayStats(),
          const SizedBox(height: 25),
          _buildAppointmentsList(isToday: true),
        ],
      ),
    );
  }

  Widget _buildUpcomingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Filter by Date'),
          const SizedBox(height: 15),
          _buildDateFilter(),
          const SizedBox(height: 25),
          _buildSectionTitle('Upcoming Appointments'),
          const SizedBox(height: 15),
          _buildAppointmentsList(isUpcoming: true),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Filter by Date'),
          const SizedBox(height: 15),
          _buildDateFilter(),
          const SizedBox(height: 25),
          _buildSectionTitle('Appointment History'),
          const SizedBox(height: 15),
          _buildAppointmentsList(isHistory: true),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF1A237E),
      ),
    );
  }

  Widget _buildTodayStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTodayAppointmentsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final appointments = snapshot.data!.docs
            .where((doc) => _filterAppointment(doc))
            .toList();
        final total = appointments.length;
        final pending = appointments.where((doc) => doc['status'] == 'pending').length;
        final confirmed = appointments.where((doc) => doc['status'] == 'confirmed').length;
        final completed = appointments.where((doc) => doc['status'] == 'completed').length;

        return Row(
          children: [
            Expanded(child: _buildStatCard('Total', total.toString(), Icons.calendar_today, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Pending', pending.toString(), Icons.pending, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Confirmed', confirmed.toString(), Icons.check_circle, Colors.green)),
            const SizedBox(width: 10),
            Expanded(child: _buildStatCard('Completed', completed.toString(), Icons.done_all, Colors.purple)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Semantics(
      label: '$title: $value',
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A237E),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    final isSelected = filterDate != null;

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: filterDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF2E86AB),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                      ),
                      dialogBackgroundColor: Colors.white,
                    ),
                    child: child!,
                  ),
                );
                if (date != null) {
                  setState(() => filterDate = date);
                  HapticFeedback.selectionClick();
                }
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF2E86AB).withOpacity(0.08) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isSelected ? const Color(0xFF2E86AB) : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filterDate == null
                          ? 'Select Date'
                          : DateFormat('MMMM d, yyyy').format(filterDate!),
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? const Color(0xFF2E86AB) : const Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: TextButton.icon(
              onPressed: () {
                setState(() => filterDate = null);
                HapticFeedback.selectionClick();
              },
              icon: const Icon(Icons.clear, size: 14, color: Color(0xFFE53E3E)),
              label: Text(
                'Clear',
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE53E3E),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAppointmentsList({bool isToday = false, bool isUpcoming = false, bool isHistory = false}) {
    Stream<QuerySnapshot> stream;

    if (isToday) {
      stream = _getTodayAppointmentsStream();
    } else if (isUpcoming) {
      stream = _getUpcomingAppointmentsStream();
    } else {
      stream = _getHistoryAppointmentsStream();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.roboto(fontSize: 14)),
          );
        }
        final appointments = snapshot.data!.docs
            .where((doc) => _filterAppointment(doc))
            .toList();

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No appointments found.',
                  style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: appointments.length,
          itemBuilder: (context, index) {
            final doc = appointments[index];
            final appointment = doc.data() as Map<String, dynamic>;
            final userId = appointment['userId']?.toString() ?? '';
            return FutureBuilder<String>(
              future: _getPatientName(userId),
              builder: (context, nameSnapshot) {
                final patientName = nameSnapshot.data ?? 'Loading...';
                return _buildAppointmentCard(doc.id, appointment, patientName, isHistory);
              },
            );
          },
        );
      },
    );
  }

  bool _filterAppointment(DocumentSnapshot doc) {
    if (_searchQuery.isEmpty) return true;
    final appointment = doc.data() as Map<String, dynamic>;
    final userId = appointment['userId']?.toString() ?? '';
    final patientName = _patientNameCache[userId]?.toLowerCase() ?? '';
    return patientName.contains(_searchQuery);
  }

  Widget _buildAppointmentCard(String appointmentId, Map<String, dynamic> appointment, String patientName, bool isHistory) {
    final date = (appointment['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final status = appointment['status'] as String? ?? 'unknown';
    final symptoms = appointment['symptoms']?.toString() ?? '';

    Color statusColor;
    Color statusBgColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange[600]!;
        statusBgColor = Colors.orange[50]!;
        break;
      case 'confirmed':
        statusColor = Colors.green[600]!;
        statusBgColor = Colors.green[50]!;
        break;
      case 'completed':
        statusColor = Colors.blue[600]!;
        statusBgColor = Colors.blue[50]!;
        break;
      case 'canceled':
        statusColor = Colors.red[600]!;
        statusBgColor = Colors.red[50]!;
        break;
      default:
        statusColor = Colors.grey[600]!;
        statusBgColor = Colors.grey[50]!;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF2E86AB).withOpacity(0.1),
                child: const Icon(Icons.person, color: Color(0xFF2E86AB)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    Text(
                      appointment['type']?.toString() ?? 'Consultation',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM d, yyyy').format(date),
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(width: 20),
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Text(
                appointment['timeSlot']?.toString() ?? 'N/A',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          if (symptoms.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.medical_services, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Symptoms: $symptoms',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 15),
          _buildReportsSection(appointmentId),
          if (!isHistory && status == 'pending') ...[
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _updateAppointmentStatus(appointmentId, 'confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Confirm',
                      style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _updateAppointmentStatus(appointmentId, 'canceled'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!isHistory && status == 'confirmed') ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _updateAppointmentStatus(appointmentId, 'completed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E86AB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Mark as Completed',
                  style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportsSection(String appointmentId) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment, size: 18, color: Colors.grey[700]),
              const SizedBox(width: 8),
              Text(
                'Medical Reports',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showAddReportDialog(appointmentId),
                icon: const Icon(Icons.add, size: 16),
                label: Text(
                  'Add Report',
                  style: GoogleFonts.roboto(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF2E86AB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildReportsList(appointmentId),
        ],
      ),
    );
  }

  Widget _buildReportsList(String appointmentId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('appointments')
          .doc(appointmentId)
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(10),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No reports available',
                style: GoogleFonts.roboto(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final report = doc.data() as Map<String, dynamic>;
            return _buildReportItem(appointmentId, doc.id, report);
          }).toList(),
        );
      },
    );
  }

  Widget _buildReportItem(String appointmentId, String reportId, Map<String, dynamic> report) {
    final createdAt = (report['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final hasAttachment = report['attachmentUrl'] != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report['title']?.toString() ?? 'Medical Report',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A237E),
                  ),
                ),
              ),
              if (hasAttachment)
                Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditReportDialog(appointmentId, reportId, report);
                      break;
                    case 'delete':
                      _deleteReport(appointmentId, reportId);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
                icon: Icon(Icons.more_vert, size: 16, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('MMM d, yyyy - h:mm a').format(createdAt),
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          if (report['content']?.toString().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              report['content'],
              style: GoogleFonts.roboto(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (hasAttachment) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _openAttachment(report['attachmentUrl']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E86AB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.file_present, size: 14, color: const Color(0xFF2E86AB)),
                    const SizedBox(width: 4),
                    Text(
                      report['attachmentName']?.toString() ?? 'Attachment',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF2E86AB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showAddReportDialog(String appointmentId) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String? attachmentPath;
    String? attachmentName;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Add Medical Report',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Report Title',
                      border: const OutlineInputBorder(),
                      errorText: titleController.text.trim().isEmpty && isUploading
                          ? 'Title is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Report Content',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: isUploading
                            ? null
                            : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                          if (result != null) {
                            setState(() {
                              attachmentPath = result.files.single.path;
                              attachmentName = result.files.single.name;
                            });
                            HapticFeedback.selectionClick();
                          }
                        },
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: const Text('Attach PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E86AB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (attachmentName != null)
                        Expanded(
                          child: Text(
                            attachmentName!,
                            style: GoogleFonts.roboto(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                if (titleController.text.trim().isEmpty) {
                  setState(() => isUploading = true);
                  _showSnackBar('Please enter a report title', isError: true);
                  return;
                }

                setState(() => isUploading = true);

                try {
                  String? attachmentUrl;

                  if (attachmentPath != null) {
                    final file = File(attachmentPath!);
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$attachmentName';
                    final ref = _storage.ref().child('reports/$appointmentId/$fileName');
                    await ref.putFile(file);
                    attachmentUrl = await ref.getDownloadURL();
                  }

                  await _firestore
                      .collection('appointments')
                      .doc(appointmentId)
                      .collection('reports')
                      .add({
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'attachmentUrl': attachmentUrl,
                    'attachmentName': attachmentName,
                    'createdAt': Timestamp.now(),
                    'updatedAt': Timestamp.now(),
                    'doctorId': _doctorId,
                  });

                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _showSnackBar('Report added successfully');
                } catch (e) {
                  _showSnackBar('Error adding report: $e', isError: true);
                } finally {
                  setState(() => isUploading = false);
                }
              },
              child: isUploading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Add Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditReportDialog(String appointmentId, String reportId, Map<String, dynamic> report) {
    final titleController = TextEditingController(text: report['title']);
    final contentController = TextEditingController(text: report['content']);
    String? attachmentPath;
    String? attachmentName = report['attachmentName'];
    String? currentAttachmentUrl = report['attachmentUrl'];
    bool isUploading = false;
    bool removeCurrentAttachment = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(
            'Edit Medical Report',
            style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Report Title',
                      border: const OutlineInputBorder(),
                      errorText: titleController.text.trim().isEmpty && isUploading
                          ? 'Title is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Report Content',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 15),
                  if (currentAttachmentUrl != null && !removeCurrentAttachment) ...[
                    Row(
                      children: [
                        Icon(Icons.attach_file, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Current: ${attachmentName ?? 'Attachment'}',
                            style: GoogleFonts.roboto(fontSize: 12),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() => removeCurrentAttachment = true);
                            HapticFeedback.selectionClick();
                          },
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: 'Remove attachment',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: isUploading
                            ? null
                            : () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf'],
                          );
                          if (result != null) {
                            setState(() {
                              attachmentPath = result.files.single.path;
                              attachmentName = result.files.single.name;
                              removeCurrentAttachment = true;
                            });
                            HapticFeedback.selectionClick();
                          }
                        },
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: Text(currentAttachmentUrl != null ? 'Replace PDF' : 'Attach PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E86AB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (attachmentPath != null)
                        Expanded(
                          child: Text(
                            'New: $attachmentName',
                            style: GoogleFonts.roboto(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                if (titleController.text.trim().isEmpty) {
                  setState(() => isUploading = true);
                  _showSnackBar('Please enter a report title', isError: true);
                  return;
                }

                setState(() => isUploading = true);

                try {
                  String? newAttachmentUrl = currentAttachmentUrl;
                  String? newAttachmentName = attachmentName;

                  if (removeCurrentAttachment) {
                    newAttachmentUrl = null;
                    newAttachmentName = null;
                  }

                  if (attachmentPath != null) {
                    final file = File(attachmentPath!);
                    final fileName = '${DateTime.now().millisecondsSinceEpoch}_$attachmentName';
                    final ref = _storage.ref().child('reports/$appointmentId/$fileName');
                    await ref.putFile(file);
                    newAttachmentUrl = await ref.getDownloadURL();
                    newAttachmentName = attachmentName;
                  }

                  await _firestore
                      .collection('appointments')
                      .doc(appointmentId)
                      .collection('reports')
                      .doc(reportId)
                      .update({
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'attachmentUrl': newAttachmentUrl,
                    'attachmentName': newAttachmentName,
                    'updatedAt': Timestamp.now(),
                  });

                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  _showSnackBar('Report updated successfully');
                } catch (e) {
                  _showSnackBar('Error updating report: $e', isError: true);
                } finally {
                  setState(() => isUploading = false);
                }
              },
              child: isUploading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text('Update Report'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteReport(String appointmentId, String reportId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(
          'Delete Report',
          style: GoogleFonts.roboto(fontWeight: FontWeight.w600),
        ),
        content: const Text('Are you sure you want to delete this report? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _firestore
                    .collection('appointments')
                    .doc(appointmentId)
                    .collection('reports')
                    .doc(reportId)
                    .delete();

                Navigator.pop(context);
                HapticFeedback.lightImpact();
                _showSnackBar('Report deleted successfully');
              } catch (e) {
                _showSnackBar('Error deleting report: $e', isError: true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openAttachment(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        HapticFeedback.selectionClick();
      } else {
        _showSnackBar('Could not open attachment', isError: true);
      }
    } catch (e) {
      _showSnackBar('Error opening attachment: $e', isError: true);
    }
  }

  Stream<QuerySnapshot> _getTodayAppointmentsStream() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: _doctorId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .orderBy('date')
        .orderBy('timeSlot')
        .snapshots();
  }

  Stream<QuerySnapshot> _getUpcomingAppointmentsStream() {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final startOfTomorrow = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);

    Query query = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: _doctorId)
        .where('status', whereIn: ['pending', 'confirmed'])
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfTomorrow))
        .orderBy('date');

    if (filterDate != null) {
      final startOfDay = DateTime(filterDate!.year, filterDate!.month, filterDate!.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots();
  }

  Stream<QuerySnapshot> _getHistoryAppointmentsStream() {
    Query query = _firestore
        .collection('appointments')
        .where('doctorId', isEqualTo: _doctorId)
        .where('status', whereIn: ['completed', 'canceled'])
        .orderBy('date', descending: true);

    if (filterDate != null) {
      final startOfDay = DateTime(filterDate!.year, filterDate!.month, filterDate!.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      query = query
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay));
    }

    return query.snapshots();
  }

  void _updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await _firestore.collection('appointments').doc(appointmentId).update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      });

      HapticFeedback.lightImpact();
      _showSnackBar('Appointment ${newStatus.toLowerCase()} successfully.');
    } catch (e) {
      _showSnackBar('Error updating appointment: $e', isError: true);
    }
  }
}