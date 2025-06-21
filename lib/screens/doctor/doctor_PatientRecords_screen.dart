import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

// DoctorPatientRecordsScreen: Displays patient records and allows doctors to manage prescriptions
class DoctorPatientRecordsScreen extends StatefulWidget {
  final String doctorId; // Added to support prescription submission
  const DoctorPatientRecordsScreen({super.key, required this.doctorId});

  @override
  State<DoctorPatientRecordsScreen> createState() => _DoctorPatientRecordsScreenState();
}

class _DoctorPatientRecordsScreenState extends State<DoctorPatientRecordsScreen>
    with TickerProviderStateMixin {
  // == State Variables ==
  List<Map<String, String>> _allPatients = [];
  List<Map<String, String>> _filteredPatients = [];
  String? _selectedPatientId;
  String? _selectedPatientName;
  TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _debounce;

  // Prescription-related state
  bool _showPrescriptionForm = false;
  bool _isSubmittingPrescription = false;
  String _selectedFrequencyType = 'times per day';
  String _selectedDurationType = 'days';
  final GlobalKey<FormState> _prescriptionFormKey = GlobalKey<FormState>();
  final TextEditingController _medicationController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _frequencyController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _prescriptionFormController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _prescriptionFormAnimation;

  // == Color Scheme ==
  final Color primaryColor = const Color(0xFF2E86AB);
  final Color accentColor = const Color(0xFF00BCD4);
  final Color backgroundColor = const Color(0xFFF0F8FF);
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF1A237E);
  final Color textSecondary = const Color(0xFF546E7A);
  final Color prescriptionColor = const Color(0xFF4CAF50); // Green for prescriptions
  final Color prescriptionAccent = const Color(0xFF81C784);

  // == Initialization ==
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchPatients();
    _searchController.addListener(_debouncedSearch);
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
    _prescriptionFormController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _prescriptionFormAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _prescriptionFormController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _slideController.forward();
  }

  void _debouncedSearch() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _medicationController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _durationController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _prescriptionFormController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // == Data Fetching and Filtering ==
  Future<void> _fetchPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<Map<String, String>> patients = snapshot.docs.map((doc) {
        final data = doc.data();
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
      _showPrescriptionForm = false; // Reset form when selecting new patient
    });
    _slideController.reset();
    _slideController.forward();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _selectedPatientId = null;
      _selectedPatientName = null;
      _showPrescriptionForm = false;
    });
  }

  // == Prescription Logic ==
  void _togglePrescriptionForm() {
    setState(() {
      _showPrescriptionForm = !_showPrescriptionForm;
    });

    if (_showPrescriptionForm) {
      _prescriptionFormController.forward();
    } else {
      _prescriptionFormController.reverse();
      _clearPrescriptionForm();
    }
  }

  void _clearPrescriptionForm() {
    _medicationController.clear();
    _dosageController.clear();
    _frequencyController.clear();
    _durationController.clear();
    _instructionsController.clear();
    _notesController.clear();
    setState(() {
      _selectedFrequencyType = 'times per day';
      _selectedDurationType = 'days';
    });
  }

  Future<void> _submitPrescription() async {
    if (!_prescriptionFormKey.currentState!.validate()) return;
    if (_selectedPatientId == null) return;

    setState(() {
      _isSubmittingPrescription = true;
    });

    try {
      final now = DateTime.now();
      final prescriptionData = {
        'patientId': _selectedPatientId,
        'patientName': _selectedPatientName,
        'doctorId': widget.doctorId,
        'medication': _medicationController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'frequency': '${_frequencyController.text.trim()} $_selectedFrequencyType',
        'duration': '${_durationController.text.trim()} $_selectedDurationType',
        'instructions': _instructionsController.text.trim(),
        'notes': _notesController.text.trim(),
        'prescribedAt': now,
        'status': 'active',
        'createdAt': now,
        'updatedAt': now,
      };

      // Add to global prescriptions collection and get auto-generated ID
      final docRef = await FirebaseFirestore.instance
          .collection('prescriptions')
          .add(prescriptionData);
      final prescriptionId = docRef.id;

      // Add ID to prescription data and set in patient's subcollection
      final prescriptionDataWithId = {
        ...prescriptionData,
        'id': prescriptionId,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_selectedPatientId)
          .collection('prescriptions')
          .doc(prescriptionId)
          .set(prescriptionDataWithId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Prescription added successfully!'),
            ],
          ),
          backgroundColor: prescriptionColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

      _clearPrescriptionForm();
      _togglePrescriptionForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to add prescription: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      setState(() {
        _isSubmittingPrescription = false;
      });
    }
  }

  Stream<QuerySnapshot> _getPrescriptionHistory() {
    if (_selectedPatientId == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(_selectedPatientId)
        .collection('prescriptions')
        .orderBy('prescribedAt', descending: true)
        .snapshots();
  }

  // == UI Widgets ==
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
            border: Border.all(color: primaryColor.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
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
              // Add prescription button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ElevatedButton.icon(
                  onPressed: _togglePrescriptionForm,
                  icon: Icon(Icons.add_circle_outline, color: Colors.white),
                  label: Text(
                    'Add Prescription',
                    style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: prescriptionColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _buildMedicalRecordsForm(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            const Expanded(child: SizedBox()),
          ],
        ),
        const SizedBox(height: 16),
        _buildFullWidthRecordCard(
          label: 'Allergies',
          value: data['allergies']?.toString() ?? 'None reported',
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildFullWidthRecordCard(
          label: 'Medical Conditions',
          value: data['conditions']?.toString() ?? 'None reported',
          icon: Icons.medical_information_rounded,
          color: Colors.purple,
        ),
      ],
    );
  }

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
              children: unit != null
                  ? [
                TextSpan(
                  text: ' $unit',
                  style: GoogleFonts.roboto(
                    color: textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ]
                  : [],
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildPrescriptionForm() {
    return AnimatedBuilder(
      animation: _prescriptionFormAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _prescriptionFormAnimation.value,
          child: Opacity(
            opacity: _prescriptionFormAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    prescriptionColor.withOpacity(0.05),
                    prescriptionAccent.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: prescriptionColor.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: prescriptionColor.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Form(
                key: _prescriptionFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            prescriptionColor.withOpacity(0.1),
                            prescriptionAccent.withOpacity(0.1),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [prescriptionColor, prescriptionAccent],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.receipt_long, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'New Prescription',
                                  style: GoogleFonts.roboto(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                Text(
                                  'for $_selectedPatientName',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _togglePrescriptionForm,
                            icon: Icon(Icons.close, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          _buildPrescriptionTextField(
                            controller: _medicationController,
                            label: 'Medication Name',
                            icon: Icons.medication,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter medication name' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildPrescriptionTextField(
                            controller: _dosageController,
                            label: 'Dosage (e.g., 500mg, 1 tablet)',
                            icon: Icons.science,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter dosage' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildPrescriptionTextField(
                                  controller: _frequencyController,
                                  label: 'Frequency',
                                  icon: Icons.schedule,
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter frequency' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: _buildFrequencyDropdown(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: _buildPrescriptionTextField(
                                  controller: _durationController,
                                  label: 'Duration',
                                  icon: Icons.calendar_today,
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter duration' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: _buildDurationDropdown(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildPrescriptionTextField(
                            controller: _instructionsController,
                            label: 'Instructions (e.g., Take with food)',
                            icon: Icons.info_outline,
                            maxLines: 2,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter instructions' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildPrescriptionTextField(
                            controller: _notesController,
                            label: 'Additional Notes (Optional)',
                            icon: Icons.note_add,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _isSubmittingPrescription ? null : _submitPrescription,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: prescriptionColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _isSubmittingPrescription
                                  ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Adding Prescription...'),
                                ],
                              )
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_circle_outline),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Add Prescription',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrescriptionTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.roboto(
          color: prescriptionColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, color: prescriptionColor, size: 20),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: prescriptionColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: GoogleFonts.roboto(
        fontSize: 16,
        color: textPrimary,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildFrequencyDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedFrequencyType,
      decoration: InputDecoration(
        labelText: 'Unit',
        labelStyle: GoogleFonts.roboto(
          color: prescriptionColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: prescriptionColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: [
        'times per day',
        'times per week',
        'times per month',
        'as needed',
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedFrequencyType = newValue!;
        });
      },
      icon: Icon(Icons.arrow_drop_down, color: prescriptionColor),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDurationType,
      decoration: InputDecoration(
        labelText: 'Unit',
        labelStyle: GoogleFonts.roboto(
          color: prescriptionColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: prescriptionColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: [
        'days',
        'weeks',
        'months',
        'until finished',
      ].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedDurationType = newValue!;
        });
      },
      icon: Icon(Icons.arrow_drop_down, color: prescriptionColor),
    );
  }

  Widget _buildPrescriptionHistory() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: prescriptionColor.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: prescriptionColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  prescriptionColor.withOpacity(0.05),
                  prescriptionAccent.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [prescriptionColor, prescriptionAccent],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.history, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Text(
                  'Prescription History',
                  style: GoogleFonts.roboto(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _getPrescriptionHistory(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(prescriptionColor),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading prescriptions...',
                          style: GoogleFonts.roboto(color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[400]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Error loading prescriptions: ${snapshot.error}',
                          style: GoogleFonts.roboto(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: prescriptionColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.medication_outlined,
                            size: 48,
                            color: prescriptionColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Prescriptions Yet',
                          style: GoogleFonts.roboto(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No prescriptions have been added for this patient.',
                          style: GoogleFonts.roboto(color: textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              final prescriptions = snapshot.data!.docs;
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: prescriptions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final prescription = prescriptions[index].data() as Map<String, dynamic>;
                  return _buildPrescriptionCard(prescription);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    final prescribedAt = (prescription['prescribedAt'] as Timestamp?)?.toDate();
    final status = prescription['status'] ?? 'active';
    final formattedDate = prescribedAt != null
        ? '${prescribedAt.day}/${prescribedAt.month}/${prescribedAt.year}'
        : 'Unknown Date';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: status == 'active'
            ? prescriptionColor.withOpacity(0.05)
            : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'active'
              ? prescriptionColor.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: status == 'active'
                ? prescriptionColor.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
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
                  color: prescriptionColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.medication, color: prescriptionColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  prescription['medication'] ?? 'Unknown Medication',
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'active'
                      ? prescriptionColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: status == 'active' ? prescriptionColor : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: textSecondary),
              const SizedBox(width: 8),
              Text(
                'Prescribed on: $formattedDate',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dosage: ${prescription['dosage'] ?? 'N/A'}',
            style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Frequency: ${prescription['frequency'] ?? 'N/A'}',
            style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Duration: ${prescription['duration'] ?? 'N/A'}',
            style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Instructions: ${prescription['instructions'] ?? 'None'}',
            style: GoogleFonts.roboto(fontSize: 14, color: textPrimary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (prescription['notes'] != null && prescription['notes'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Notes: ${prescription['notes']}',
              style: GoogleFonts.roboto(fontSize: 14, color: textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
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
            if (_selectedPatientId != null) ...[
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
                  return Column(
                    children: [
                      _buildAnimatedPatientRecord(data),
                      if (_showPrescriptionForm) _buildPrescriptionForm(),
                      _buildPrescriptionHistory(),
                    ],
                  );
                },
              ),
            ] else if (_allPatients.isEmpty && !_isLoading)
              _buildEmptyState(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}