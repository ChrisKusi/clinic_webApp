import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorsAppointmentScreen extends StatefulWidget {
  const DoctorsAppointmentScreen({super.key});

  @override
  State<DoctorsAppointmentScreen> createState() => _DoctorsAppointmentScreenState();
}

class _DoctorsAppointmentScreenState extends State<DoctorsAppointmentScreen> with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedStatus;
  Map<String, Map<String, dynamic>> _usersCache = {};
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _setupUsersListener();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupUsersListener() {
    FirebaseFirestore.instance
        .collection('users')
        .where('role', whereIn: ['doctor', 'patient'])
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _usersCache = {for (var doc in snapshot.docs) doc.id: doc.data()};
      });
    });
  }

  Stream<QuerySnapshot> _getAppointmentsStream() {
    final doctorId = FirebaseAuth.instance.currentUser!.uid;
    Query query = FirebaseFirestore.instance
        .collection('appointments')
        .where('doctorId', isEqualTo: doctorId);

    if (_selectedDate != null) {
      final startOfDay = Timestamp.fromDate(_selectedDate!);
      final endOfDay = Timestamp.fromDate(_selectedDate!.add(const Duration(days: 1)));
      query = query.where('date', isGreaterThanOrEqualTo: startOfDay)
                  .where('date', isLessThan: endOfDay);
    }
    if (_selectedStatus != null) {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query.orderBy('date').snapshots();
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedStatus = null;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return const Color(0xFF1976D2);
      case 'completed':
        return const Color(0xFF00C853);
      case 'canceled':
        return const Color(0xFFE53E3E);
      default:
        return const Color(0xFF757575);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _updateAppointmentStatus(String appointmentId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(appointmentId)
          .update({'status': newStatus});
      _showSnackBar('Appointment status updated to $newStatus');
    } catch (e) {
      _showSnackBar('Error updating status: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isError ? const Color(0xFFE53E3E) : const Color(0xFF00C853),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        elevation: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: Text(
          'My Appointments',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF2E86AB),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Enhanced Filter Card with reduced height
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12), // Reduced padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E86AB).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF2E86AB).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6), // Reduced padding
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E86AB).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.filter_list_rounded,
                          color: const Color(0xFF2E86AB),
                          size: 18, // Reduced size
                        ),
                      ),
                      const SizedBox(width: 8), // Reduced spacing
                      Text(
                        'Filter Appointments',
                        style: GoogleFonts.roboto(
                          fontSize: 16, // Reduced font size
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A237E),
                        ),
                      ),
                      const Spacer(),
                      if (_selectedDate != null || _selectedStatus != null)
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53E3E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_rounded, size: 14), // Reduced size
                            label: Text(
                              'Clear All',
                              style: GoogleFonts.roboto(
                                fontSize: 10, // Reduced font size
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFE53E3E),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), // Reduced padding
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12), // Reduced spacing
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateFilter(),
                      ),
                      const SizedBox(width: 12), // Reduced spacing
                      Expanded(
                        child: _buildStatusFilter(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.event_note_rounded,
                              color: const Color(0xFF00BCD4),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your Appointments',
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A237E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView( // Added to ensure scrollability
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _getAppointmentsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
                                ),
                              );
                            }

                            if (snapshot.hasError) {
                              return _buildErrorState();
                            }

                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return _buildEmptyState();
                            }

                            final appointments = snapshot.data!.docs;

                            return ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              itemCount: appointments.length,
                              shrinkWrap: true, // Added to work with SingleChildScrollView
                              physics: const NeverScrollableScrollPhysics(), // Let parent handle scrolling
                              itemBuilder: (context, index) {
                                return _buildAppointmentCard(appointments[index]);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    final isSelected = _selectedDate != null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: Color(0xFF2E86AB),
                  ),
                ),
                child: child!,
              );
            },
          );
          setState(() => _selectedDate = date);
        },
        borderRadius: BorderRadius.circular(12), // Reduced radius
        child: Container(
          padding: const EdgeInsets.all(10), // Reduced padding
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFF2E86AB).withOpacity(0.08)
                : const Color(0xFFF8F9FA),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF2E86AB)
                  : const Color(0xFFE1E5E9),
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12), // Reduced radius
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6), // Reduced padding
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E86AB)
                      : const Color(0xFF6C757D),
                  borderRadius: BorderRadius.circular(6), // Reduced radius
                ),
                child: Icon(
                  Icons.calendar_today_rounded,
                  size: 14, // Reduced size
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Filter',
                      style: GoogleFonts.roboto(
                        fontSize: 10, // Reduced font size
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF6C757D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : _formatDate(_selectedDate!),
                      style: GoogleFonts.roboto(
                        fontSize: 13, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF2E86AB)
                            : const Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                GestureDetector(
                  onTap: () => setState(() => _selectedDate = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E86AB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14, // Reduced size
                      color: const Color(0xFF2E86AB),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    final isSelected = _selectedStatus != null;
    
    return Container(
      padding: const EdgeInsets.all(10), // Reduced padding
      decoration: BoxDecoration(
        color: isSelected 
            ? const Color(0xFF00BCD4).withOpacity(0.08)
            : const Color(0xFFF8F9FA),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF00BCD4)
              : const Color(0xFFE1E5E9),
          width: isSelected ? 2 : 1.5,
        ),
        borderRadius: BorderRadius.circular(12), // Reduced radius
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00BCD4)
                  : const Color(0xFF6C757D),
              borderRadius: BorderRadius.circular(6), // Reduced radius
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 14, // Reduced size
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8), // Reduced spacing
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status Filter',
                  style: GoogleFonts.roboto(
                    fontSize: 10, // Reduced font size
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C757D),
                  ),
                ),
                const SizedBox(height: 2),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: Text(
                      'Select Status',
                      style: GoogleFonts.roboto(
                        fontSize: 13, // Reduced font size
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                    value: _selectedStatus,
                    isExpanded: true,
                    icon: const SizedBox.shrink(),
                    items: ['confirmed', 'completed', 'canceled'].map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6), // Reduced padding
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                status.toUpperCase(),
                                style: GoogleFonts.roboto(
                                  fontSize: 12, // Reduced font size
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedStatus = value),
                    selectedItemBuilder: (context) {
                      return ['confirmed', 'completed', 'canceled'].map<Widget>((status) {
                        return Row(
                          children: [
                            Text(
                              status.toUpperCase(),
                              style: GoogleFonts.roboto(
                                fontSize: 13, // Reduced font size
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF00BCD4)
                                    : const Color(0xFF1A237E),
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected)
                GestureDetector(
                  onTap: () => setState(() => _selectedStatus = null),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      size: 14, // Reduced size
                      color: const Color(0xFF00BCD4),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isSelected
                    ? const Color(0xFF00BCD4)
                    : const Color(0xFF6C757D),
                size: 18, // Reduced size
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 32,
              color: const Color(0xFFE53E3E),
            ),
            const SizedBox(height: 8),
            Text(
              'Error loading appointments',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Please try again later',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF546E7A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 40,
                color: const Color(0xFF00BCD4),
              ),
              const SizedBox(height: 8),
              Text(
                'No appointments found',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedDate != null || _selectedStatus != null
                    ? 'Try adjusting your filters'
                    : 'Check back later for new appointments',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: const Color(0xFF546E7A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(QueryDocumentSnapshot appointmentDoc) {
    final appointment = appointmentDoc.data() as Map<String, dynamic>;
    final appointmentId = appointmentDoc.id;

    final patientName = _usersCache[appointment['userId']] != null
        ? _usersCache[appointment['userId']]!['name']
        : 'Loading...';
    final date = (appointment['date'] as Timestamp).toDate();
    final time = appointment['time'] ?? 'N/A';
    String status = appointment['status'] ?? 'Confirmed';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF1F3F4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status.toLowerCase()).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getStatusColor(status.toLowerCase()).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: status,
                    items: ['Confirmed', 'Completed', 'Canceled'].map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          s,
                          style: GoogleFonts.roboto(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(s.toLowerCase()),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null && value != status) {
                        setState(() => status = value);
                        _updateAppointmentStatus(appointmentId, value.toLowerCase());
                      }
                    },
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status.toLowerCase()),
                    ),
                    dropdownColor: Colors.white,
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: _getStatusColor(status.toLowerCase()),
                      size: 18,
                    ),
                    iconSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E86AB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _formatDate(date),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2E86AB),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patient',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF666666),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      patientName,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A237E),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Time',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: const Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00BCD4).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      time,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF00BCD4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}