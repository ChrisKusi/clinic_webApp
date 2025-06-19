import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorPatientRecordsScreen extends StatefulWidget {
  const DoctorPatientRecordsScreen({super.key});

  @override
  State<DoctorPatientRecordsScreen> createState() => _DoctorPatientRecordsScreenState();
}

class _DoctorPatientRecordsScreenState extends State<DoctorPatientRecordsScreen>
    with TickerProviderStateMixin {
  List<Map<String, String>> _allPatients = [];
  List<Map<String, String>> _filteredPatients = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  TextEditingController _searchController = TextEditingController();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  // Doctor's color scheme
  final Color primaryColor = const Color(0xFF2E86AB);
  final Color accentColor = const Color(0xFF00BCD4);
  final Color backgroundColor = const Color(0xFFF0F8FF);
  final Color cardColor = Colors.white; // Changed to pure white for better visibility
  final Color textPrimary = const Color(0xFF1A237E);
  final Color textSecondary = const Color(0xFF546E7A);

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
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
    });
    _slideController.reset();
    _slideController.forward();
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
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.search_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text('Find Patient', style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
                  ],
                ),
                const SizedBox(height: 24),
                _buildAnimatedSearchField(),
                const SizedBox(height: 20),
                if (_filteredPatients.isNotEmpty) _buildAnimatedDropdown() else if (_searchController.text.isNotEmpty) _buildNoResultsWidget(),
              ],
            ),
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
          hintStyle: GoogleFonts.roboto(color: textSecondary, fontSize: 16),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: Icon(Icons.person_search_rounded, color: primaryColor, size: 22),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(icon: Icon(Icons.clear_rounded, color: textSecondary), onPressed: _clearSearch)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.roboto(fontSize: 16, color: textPrimary),
      ),
    );
  }

  Widget _buildAnimatedDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: DropdownButtonFormField<String>(
        value: _selectedPatientId,
        hint: Text('Select Patient', style: GoogleFonts.roboto(color: textSecondary, fontSize: 16)),
        items: _filteredPatients.map((patient) {
          return DropdownMenuItem(
            value: patient['id'],
            child: Text(patient['name']!, style: GoogleFonts.roboto(fontSize: 16, color: textPrimary)),
          );
        }).toList(),
        onChanged: _selectPatient,
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
          ),
          labelText: 'Patient',
          labelStyle: GoogleFonts.roboto(color: primaryColor, fontSize: 16),
          filled: true,
          fillColor: backgroundColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 24),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No patients found matching "${_searchController.text}"',
              style: GoogleFonts.roboto(color: Colors.blue[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Enhanced patient record section with better visibility
  Widget _buildAnimatedPatientRecord(Map<String, dynamic> data) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor.withOpacity(0.2), width: 2), // Added border for visibility
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.15), // Enhanced shadow
                blurRadius: 30,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor.withOpacity(0.3), accentColor.withOpacity(0.3)],
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: _buildMedicalRecordsForm(data),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Enhanced patient header with better styling
  Widget _buildPatientHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.05), accentColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
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
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedPatientName ?? 'Unknown Patient',
                  style: GoogleFonts.roboto(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accentColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Medical Records',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // UPDATED: Enhanced medical records form with better visibility
  Widget _buildMedicalRecordsForm(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            'Patient Information',
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // First row - Blood Group and Height
        Row(
          children: [
            Expanded(
              child: _buildRecordCard(
                label: 'Blood Group',
                value: data['bloodGroup']?.toString() ?? 'N/A',
                icon: Icons.bloodtype_rounded,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildRecordCard(
                label: 'Height',
                value: data['height']?.toString() ?? 'N/A',
                unit: 'cm',
                icon: Icons.height_rounded,
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Second row - Weight
        Row(
          children: [
            Expanded(
              child: _buildRecordCard(
                label: 'Weight',
                value: data['weight']?.toString() ?? 'N/A',
                unit: 'kg',
                icon: Icons.monitor_weight_rounded,
                color: Colors.green,
              ),
            ),
            const Expanded(child: SizedBox()), // Placeholder for symmetry
          ],
        ),
        const SizedBox(height: 16),
        
        // Full width cards for text data
        _buildFullWidthRecordCard(
          label: 'Allergies',
          value: data['allergies']?.toString() ?? 'None reported',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildFullWidthRecordCard(
          label: 'Medical Conditions',
          value: data['medicalConditions']?.toString() ?? 'None reported',
          icon: Icons.medical_information_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

  // NEW: Enhanced record card widget for better visibility
  Widget _buildRecordCard({
    required String label,
    required String value,
    String? unit,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    color: textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              text: value,
              style: GoogleFonts.roboto(
                color: textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              children: unit != null ? [
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.roboto(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ] : null,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Full width record card for longer text content
  Widget _buildFullWidthRecordCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.roboto(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordRow({
    required String label,
    required String value,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 130,
          child: Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.roboto(
                  color: textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.roboto(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor.withOpacity(0.1), accentColor.withOpacity(0.1)]),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.people_outline_rounded, size: 48, color: accentColor),
              ),
              const SizedBox(height: 24),
              Text('No Patients Found', style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 12),
              Text('No patient records are available for you at the moment.', style: GoogleFonts.roboto(fontSize: 16, color: textSecondary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Patient Records', style: GoogleFonts.roboto(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        leading: null,
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchPatients)],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                  const SizedBox(height: 16),
                  Text('Loading patients...', style: GoogleFonts.roboto(color: textSecondary, fontSize: 16)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Something went wrong', style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: GoogleFonts.roboto(color: Colors.red[700], fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchPatients,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('Try Again', style: GoogleFonts.roboto()),
                          style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildAnimatedSearchSection(),
                      if (_selectedPatientId != null)
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(_selectedPatientId).snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Container(
                                margin: const EdgeInsets.all(16),
                                height: 200,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                                      const SizedBox(height: 16),
                                      Text('Loading patient data...', style: GoogleFonts.roboto(color: textSecondary)),
                                    ],
                                  ),
                                ),
                              );
                            }
                            if (snapshot.hasError) {
                              return Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text('Error loading patient data: ${snapshot.error}', style: GoogleFonts.roboto(color: Colors.red)),
                              );
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Text('Patient not found', style: GoogleFonts.roboto(color: Colors.orange[700])),
                              );
                            }
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            return _buildAnimatedPatientRecord(data);
                          },
                        )
                      else if (_allPatients.isEmpty && !_isLoading)
                        _buildEmptyState(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }
}