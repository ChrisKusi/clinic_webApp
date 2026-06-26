import 'package:clinic_web_dashboard/constants/app_constants.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_dashboard.dart';

class PatientRecordsScreen extends StatefulWidget {
  const PatientRecordsScreen({super.key});

  @override
  State<PatientRecordsScreen> createState() => _PatientRecordsScreenAdminState();
}

class _PatientRecordsScreenAdminState extends State<PatientRecordsScreen>
    with TickerProviderStateMixin {
  List<Map<String, String>> _allPatients = [];
  List<Map<String, String>> _filteredPatients = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  Map<String, TextEditingController> _controllers = {};
  TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  // Enhanced color scheme with gradients
  final Color primaryColor = const Color(0xFF2E7D5B); // Deep forest green
  final Color accentColor = const Color(0xFF4CAF50); // Bright green
  final Color backgroundColor = const Color(0xFFF8FFFE); // Very light mint
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF1A1A1A);
  final Color textSecondary = const Color(0xFF666666);
  final Color successColor = const Color(0xFF10B981);
  final Color warningColor = const Color(0xFFFFB020);
  final Color errorColor = const Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchPatients();
    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _filterPatients);
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection(Collections.users).get();
      List<Map<String, String>> patients = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, 'name': _constructDisplayName(data)};
      }).toList();

      patients.sort((a, b) => a['name']!.compareTo(b['name']!));

      setState(() {
        _allPatients = patients;
        _filteredPatients = List.from(_allPatients);
        _isLoading = false;
      });

      _fadeController.forward();
      _slideController.forward();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch patients: $e';
        _isLoading = false;
      });
    }
  }

  String _constructDisplayName(Map<String, dynamic> data) {
    String firstName = (data['firstName']?.toString() ?? '').trim();
    String lastName = (data['lastName']?.toString() ?? '').trim();
    String name = (data['name']?.toString() ?? '').trim();
    String displayName = (data['displayName']?.toString() ?? '').trim();

    if (firstName.isNotEmpty && lastName.isNotEmpty) return '$firstName $lastName';
    if (name.isNotEmpty) return name;
    if (displayName.isNotEmpty) return displayName;
    if (firstName.isNotEmpty) return firstName;
    if (lastName.isNotEmpty) return lastName;
    return 'Unknown Patient';
  }

  void _filterPatients() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredPatients = query.isEmpty
          ? List.from(_allPatients)
          : _allPatients.where((p) => p['name']!.toLowerCase().contains(query)).toList();
    });
  }

  void _selectPatient(String? id) {
    if (id == null) return;
    final selectedPatient = _allPatients.firstWhere((p) => p['id'] == id);
    setState(() {
      _selectedPatientId = id;
      _selectedPatientName = selectedPatient['name'];
      _controllers = {
        'allergies': TextEditingController(),
        'medicalConditions': TextEditingController(),
        'height': TextEditingController(),
        'weight': TextEditingController(),
        'bloodGroup': TextEditingController(),
      };
    });
    _slideController.reset();
    _slideController.forward();
    _loadPatientData(id);

  }



  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedPatientId = null;
      _selectedPatientName = null;
    });
  }

  Widget _buildAnimatedSearchSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.05),
                accentColor.withOpacity(0.08),
                Colors.white,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(-5, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [primaryColor, accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Search',
                          style: GoogleFonts.inter(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find and manage patient records',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _buildAnimatedSearchField(),
              const SizedBox(height: 24),
              if (_filteredPatients.isNotEmpty)
                _buildAnimatedDropdown()
              else if (_searchController.text.isNotEmpty)
                _buildNoResultsWidget(),
              if (_filteredPatients.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accentColor.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: accentColor, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '${_filteredPatients.length} patient(s) found',
                        style: GoogleFonts.inter(
                          color: accentColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedSearchField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by patient name...',
          hintStyle: GoogleFonts.inter(color: textSecondary.withOpacity(0.7), fontSize: 16),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: Icon(Icons.person_search_rounded, color: primaryColor, size: 24),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: textSecondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.clear_rounded, color: textSecondary, size: 18),
            ),
            onPressed: _clearSearch,
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 2.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
          ),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        style: GoogleFonts.inter(fontSize: 16, color: textPrimary, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildAnimatedDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: DropdownButtonFormField<String>(
          value: _selectedPatientId,
          hint: Text(
            'Select Patient',
            style: GoogleFonts.inter(color: textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
          ),
          items: _filteredPatients.map((patient) {
            return DropdownMenuItem(
              value: patient['id'],
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      patient['name']!,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: _selectPatient,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: primaryColor, width: 2.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey[200]!, width: 1.5),
            ),
            labelText: 'Patient',
            labelStyle: GoogleFonts.inter(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            filled: true,
            fillColor: backgroundColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 28),
          dropdownColor: Colors.white,
          style: GoogleFonts.inter(color: textPrimary),
        ),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [warningColor.withOpacity(0.08), warningColor.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.search_off_rounded, color: warningColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No Results Found',
                  style: GoogleFonts.inter(
                    color: warningColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No patients match "${_searchController.text}"',
                  style: GoogleFonts.inter(
                    color: warningColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedPatientRecord(Map<String, dynamic> data) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
                blurRadius: 40,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 20,
                offset: const Offset(-8, -8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(),
              const SizedBox(height: 28),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      primaryColor.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildMedicalRecordsForm(data),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader() {
    return Row(
      children: [
        Hero(
          tag: 'patient-avatar-$_selectedPatientId',
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedPatientName ?? 'Unknown Patient',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: primaryColor.withOpacity(0.2)),
                ),
                child: Text(
                  'Medical Records',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMedicalRecordsForm(Map<String, dynamic> data) {
    return Form(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildRecordCard(
                  controller: _controllers['bloodGroup']!,
                  label: 'Blood Group',
                  icon: Icons.bloodtype_rounded,
                  color: const Color(0xFFDC2626),
                  hint: 'A+, B-, O+, AB-',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildRecordCard(
                  controller: _controllers['height']!,
                  label: 'Height (cm)',
                  icon: Icons.height_rounded,
                  color: const Color(0xFF2563EB),
                  hint: '175',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildRecordCard(
                  controller: _controllers['weight']!,
                  label: 'Weight (kg)',
                  icon: Icons.monitor_weight_rounded,
                  color: successColor,
                  hint: '70',
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
          const SizedBox(height: 16),
          _buildFullWidthRecordCard(
            controller: _controllers['allergies']!,
            label: 'Allergies',
            icon: Icons.warning_amber_rounded,
            color: warningColor,
            hint: 'List known allergies...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildFullWidthRecordCard(
            controller: _controllers['medicalConditions']!,
            label: 'Medical Conditions',
            icon: Icons.medical_information_rounded,
            color: const Color(0xFF7C3AED),
            hint: 'List current medical conditions...',
            maxLines: 4,
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildRecordCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    String? hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            readOnly: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: textSecondary.withOpacity(0.6),
                fontSize: 16,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthRecordCard({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    String? hint,
    int maxLines = 1,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.08), color.withOpacity(0.12)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            readOnly: true,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: textSecondary.withOpacity(0.6),
                fontSize: 16,
              ),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
            style: GoogleFonts.inter(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _loadPatientData(String patientId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(Collections.users)
          .doc(patientId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _controllers['allergies']!.text = data['allergies']?.toString() ?? '';
          _controllers['medicalConditions']!.text = data['conditions']?.toString() ?? '';
          _controllers['height']!.text = data['height']?.toString() ?? '';
          _controllers['weight']!.text = data['weight']?.toString() ?? '';
          _controllers['bloodGroup']!.text = data['bloodGroup']?.toString() ?? '';
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load patient data');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: errorColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.error_rounded, color: errorColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [errorColor.withOpacity(0.1), errorColor.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.error_outline_rounded, color: errorColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error',
                  style: GoogleFonts.inter(
                    color: errorColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.inter(
                    color: errorColor.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close_rounded, color: errorColor),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading patients...',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Patient Records',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: textPrimary,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.arrow_back_ios_rounded, color: primaryColor, size: 20),
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboard()),
            );
          },
        ),
        actions: [
          if (_selectedPatientId != null)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.refresh_rounded, color: primaryColor, size: 20),
              ),
              onPressed: () => _loadPatientData(_selectedPatientId!),
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingWidget()
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildErrorMessage(),
            _buildAnimatedSearchSection(),
            if (_selectedPatientId != null)
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection(Collections.users)
                    .doc(_selectedPatientId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Container(
                      margin: const EdgeInsets.all(20),
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: GoogleFonts.inter(color: errorColor),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                  return _buildAnimatedPatientRecord(data);
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}