import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

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
  Map<String, dynamic>? _doctorInfo;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      _currentUser = FirebaseAuth.instance.currentUser;
      if (_currentUser != null) {
        _doctorId = _currentUser!.uid;
        await _loadDoctorInfo();
      }
      setState(() {
        _isLoading = _currentUser == null;
      });
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view appointments.')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing: $e')),
      );
    }
  }

  Future<void> _loadDoctorInfo() async {
    try {
      final doc = await _firestore.collection('doctors').doc(_doctorId).get();
      if (doc.exists) {
        setState(() {
          _doctorInfo = doc.data();
        });
      }
    } catch (e) {
      print('Error loading doctor info: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
        title: Text(
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
            },
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

    return Container(
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
                  'Dr. ${_doctorInfo!['name']}',
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

        final appointments = snapshot.data!.docs;
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
    return Container(
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
                      ),
                    ),
                    child: child!,
                  ),
                );
                setState(() => filterDate = date);
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
              onPressed: () => setState(() => filterDate = null),
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
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

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final appointment = doc.data() as Map<String, dynamic>;
            return _buildAppointmentCard(doc.id, appointment, isHistory);
          }).toList(),
        );
      },
    );
  }

  Widget _buildAppointmentCard(String appointmentId, Map<String, dynamic> appointment, bool isHistory) {
    final date = (appointment['date'] as Timestamp).toDate();
    final status = appointment['status'] as String;
    final patientName = appointment['patientName'] ?? 'Patient';
    final symptoms = appointment['symptoms'] ?? '';

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

    return Container(
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
                      appointment['type'] ?? 'Consultation',
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
                appointment['timeSlot'],
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment ${newStatus.toLowerCase()} successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating appointment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}