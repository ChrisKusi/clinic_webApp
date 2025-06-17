// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';

// class PatientRecordsScreen extends StatefulWidget {
//   const PatientRecordsScreen({super.key});

//   @override
//   State<PatientRecordsScreen> createState() => _PatientRecordsScreenState();
// }

// class _PatientRecordsScreenState extends State<PatientRecordsScreen>
//     with TickerProviderStateMixin {
//   List<Map<String, String>> _allPatients = [];
//   List<Map<String, String>> _filteredPatients = [];
//   String? _selectedPatientId;
//   String? _selectedPatientName;
//   Map<String, TextEditingController> _controllers = {};
//   TextEditingController _searchController = TextEditingController();
//   late AnimationController _fadeController;
//   late AnimationController _slideController;
//   late Animation<double> _fadeAnimation;
//   late Animation<Offset> _slideAnimation;
//   bool _isEditing = false;
//   bool _isLoading = false;
//   bool _isSaving = false;
//   String? _errorMessage;
//   Timer? _debounce;

//   // Professional color scheme
//   final Color primaryColor = const Color(0xFF808000); // Olive green
//   final Color accentColor = const Color(0xFF4CAF50);
//   final Color backgroundColor = const Color(0xFFF8F9FA);
//   final Color cardColor = Colors.white;
//   final Color textPrimary = const Color(0xFF212121);
//   final Color textSecondary = const Color(0xFF757575);

//   @override
//   void initState() {
//     super.initState();
//     _initializeAnimations();
//     _fetchPatients();
//     _searchController.addListener(() {
//       if (_debounce?.isActive ?? false) _debounce!.cancel();
//       _debounce = Timer(const Duration(milliseconds: 300), _filterPatients);
//     });
//   }

//   void _initializeAnimations() {
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     );

//     _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
//       CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
//     );

//     _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
//         .animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
//   }

//   @override
//   void dispose() {
//     for (var controller in _controllers.values) {
//       controller.dispose();
//     }
//     _searchController.dispose();
//     _fadeController.dispose();
//     _slideController.dispose();
//     _debounce?.cancel();
//     super.dispose();
//   }

//   void _fetchPatients() async {
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });

//     try {
//       final snapshot = await FirebaseFirestore.instance.collection('users').get();
//       List<Map<String, String>> patients = snapshot.docs.map((doc) {
//         final data = doc.data() as Map<String, dynamic>;
//         return {'id': doc.id, 'name': _constructDisplayName(data)};
//       }).toList();

//       patients.sort((a, b) => a['name']!.compareTo(b['name']!));

//       setState(() {
//         _allPatients = patients;
//         _filteredPatients = List.from(_allPatients);
//         _isLoading = false;
//       });

//       _fadeController.forward();
//       _slideController.forward();
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to fetch patients: $e';
//         _isLoading = false;
//       });
//     }
//   }

//   String _constructDisplayName(Map<String, dynamic> data) {
//     String firstName = (data['firstName']?.toString() ?? '').trim();
//     String lastName = (data['lastName']?.toString() ?? '').trim();
//     String name = (data['name']?.toString() ?? '').trim();
//     String displayName = (data['displayName']?.toString() ?? '').trim();

//     if (firstName.isNotEmpty && lastName.isNotEmpty) return '$firstName $lastName';
//     if (name.isNotEmpty) return name;
//     if (displayName.isNotEmpty) return displayName;
//     if (firstName.isNotEmpty) return firstName;
//     if (lastName.isNotEmpty) return lastName;
//     return 'Unknown Patient';
//   }

//   void _filterPatients() {
//     final query = _searchController.text.toLowerCase().trim();
//     setState(() {
//       _filteredPatients = query.isEmpty
//           ? List.from(_allPatients)
//           : _allPatients.where((p) => p['name']!.toLowerCase().contains(query)).toList();
//     });
//   }

//   void _selectPatient(String? id) {
//     if (id == null) return;
//     final selectedPatient = _allPatients.firstWhere((p) => p['id'] == id);
//     setState(() {
//       _selectedPatientId = id;
//       _selectedPatientName = selectedPatient['name'];
//       _isEditing = false;
//       _controllers = {
//         'allergies': TextEditingController(),
//         'medicalConditions': TextEditingController(),
//         'height': TextEditingController(),
//         'weight': TextEditingController(),
//         'bloodGroup': TextEditingController(),
//       };
//     });
//     _slideController.reset();
//     _slideController.forward();
//   }

//   void _clearSearch() {
//     _searchController.clear();
//     setState(() {
//       _selectedPatientId = null;
//       _selectedPatientName = null;
//     });
//   }

//   Widget _buildAnimatedSearchSection() {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: SlideTransition(
//         position: _slideAnimation,
//         child: Container(
//           margin: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: BorderRadius.circular(16),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 4))],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: primaryColor.withOpacity(0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Icon(Icons.search_rounded, color: primaryColor, size: 24),
//                     ),
//                     const SizedBox(width: 16),
//                     Text('Find Patient', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//                 _buildAnimatedSearchField(),
//                 const SizedBox(height: 20),
//                 if (_filteredPatients.isNotEmpty) _buildAnimatedDropdown() else if (_searchController.text.isNotEmpty) _buildNoResultsWidget(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildAnimatedSearchField() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       curve: Curves.easeInOut,
//       child: TextField(
//         controller: _searchController,
//         decoration: InputDecoration(
//           hintText: 'Search by patient name...',
//           hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 16),
//           prefixIcon: Container(
//             padding: const EdgeInsets.all(14),
//             child: Icon(Icons.person_search_rounded, color: primaryColor, size: 22),
//           ),
//           suffixIcon: _searchController.text.isNotEmpty
//               ? IconButton(icon: Icon(Icons.clear_rounded, color: textSecondary), onPressed: _clearSearch)
//               : null,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: primaryColor, width: 2),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
//           ),
//           filled: true,
//           fillColor: backgroundColor,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//         style: GoogleFonts.inter(fontSize: 16, color: textPrimary),
//       ),
//     );
//   }

//   Widget _buildAnimatedDropdown() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 400),
//       curve: Curves.easeInOut,
//       child: DropdownButtonFormField<String>(
//         value: _selectedPatientId,
//         hint: Text('Select Patient', style: GoogleFonts.inter(color: textSecondary, fontSize: 16)),
//         items: _filteredPatients.map((patient) {
//           return DropdownMenuItem(
//             value: patient['id'],
//             child: Text(patient['name']!, style: GoogleFonts.inter(fontSize: 16, color: textPrimary)),
//           );
//         }).toList(),
//         onChanged: _selectPatient,
//         decoration: InputDecoration(
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: primaryColor, width: 2),
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
//           ),
//           labelText: 'Patient',
//           labelStyle: GoogleFonts.inter(color: primaryColor, fontSize: 16),
//           filled: true,
//           fillColor: backgroundColor,
//           contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//         ),
//         isExpanded: true,
//         icon: Icon(Icons.keyboard_arrow_down_rounded, color: primaryColor, size: 24),
//       ),
//     );
//   }

//   Widget _buildNoResultsWidget() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.orange[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.orange[200]!),
//       ),
//       child: Row(
//         children: [
//           Icon(Icons.info_outline_rounded, color: Colors.orange[700]),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               'No patients found matching "${_searchController.text}"',
//               style: GoogleFonts.inter(color: Colors.orange[700], fontSize: 14),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnimatedPatientRecord(Map<String, dynamic> data) {
//     return SlideTransition(
//       position: _slideAnimation,
//       child: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Container(
//           margin: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 25, offset: const Offset(0, 8))],
//           ),
//           child: Padding(
//             padding: const EdgeInsets.all(28.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _buildPatientHeader(),
//                 const SizedBox(height: 24),
//                 Divider(color: Colors.grey[200], height: 1),
//                 const SizedBox(height: 28),
//                 _buildMedicalRecordsForm(data),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildPatientHeader() {
//     return Row(
//       children: [
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             gradient: LinearGradient(colors: [primaryColor, accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
//         ),
//         const SizedBox(width: 20),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 _selectedPatientName ?? 'Unknown Patient',
//                 style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
//               ),
//               const SizedBox(height: 4),
//               Text('Patient Medical Records', style: GoogleFonts.inter(fontSize: 14, color: textSecondary)),
//             ],
//           ),
//         ),
//         if (!_isEditing)
//           AnimatedContainer(
//             duration: const Duration(milliseconds: 200),
//             child: IconButton(
//               icon: Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
//                 child: Icon(Icons.edit_rounded, color: primaryColor, size: 20),
//               ),
//               onPressed: () => setState(() => _isEditing = true),
//               tooltip: 'Edit Records',
//             ),
//           ),
//       ],
//     );
//   }

//   Widget _buildMedicalRecordsForm(Map<String, dynamic> data) {
//     if (!_isEditing) {
//       _controllers['allergies']!.text = data['allergies']?.toString() ?? '';
//       _controllers['medicalConditions']!.text = data['medicalConditions']?.toString() ?? '';
//       _controllers['height']!.text = data['height']?.toString() ?? '';
//       _controllers['weight']!.text = data['weight']?.toString() ?? '';
//       _controllers['bloodGroup']!.text = data['bloodGroup']?.toString() ?? '';
//     }

//     return Form(
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: _buildAnimatedFormField(
//                   controller: _controllers['bloodGroup']!,
//                   label: 'Blood Group',
//                   icon: Icons.bloodtype_rounded,
//                   hint: 'A+, B-, O+, AB-',
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildAnimatedFormField(
//                   controller: _controllers['height']!,
//                   label: 'Height (cm)',
//                   icon: Icons.height_rounded,
//                   hint: '175',
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 20),
//           _buildAnimatedFormField(
//             controller: _controllers['weight']!,
//             label: 'Weight (kg)',
//             icon: Icons.monitor_weight_rounded,
//             hint: '70',
//           ),
//           const SizedBox(height: 20),
//           _buildAnimatedFormField(
//             controller: _controllers['allergies']!,
//             label: 'Allergies',
//             icon: Icons.warning_amber_rounded,
//             hint: 'List known allergies...',
//             maxLines: 3,
//           ),
//           const SizedBox(height: 20),
//           _buildAnimatedFormField(
//             controller: _controllers['medicalConditions']!,
//             label: 'Medical Conditions',
//             icon: Icons.medical_information_rounded,
//             hint: 'List current medical conditions...',
//             maxLines: 4,
//           ),
//           const SizedBox(height: 32),
//           if (_isEditing) _buildAnimatedActionButtons(),
//         ],
//       ),
//     );
//   }

//   Widget _buildAnimatedFormField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     String? hint,
//     int maxLines = 1,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         SizedBox(
//           width: 120,
//           child: Text(
//             label,
//             style: GoogleFonts.inter(color: _isEditing ? primaryColor : textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
//           ),
//         ),
//         const SizedBox(width: 16),
//         Expanded(
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             child: TextFormField(
//               controller: controller,
//               maxLines: maxLines,
//               readOnly: !_isEditing,
//               decoration: InputDecoration(
//                 hintText: hint,
//                 hintStyle: GoogleFonts.inter(color: textSecondary.withOpacity(0.7), fontSize: 16),
//                 prefixIcon: Container(
//                   padding: const EdgeInsets.all(14),
//                   child: Icon(icon, color: _isEditing ? primaryColor : textSecondary, size: 22),
//                 ),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: primaryColor, width: 2),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                   borderSide: BorderSide(color: _isEditing ? Colors.grey[300]! : Colors.grey[200]!, width: 1.5),
//                 ),
//                 filled: true,
//                 fillColor: _isEditing ? Colors.white : backgroundColor,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                 floatingLabelBehavior: FloatingLabelBehavior.always,
//               ),
//               style: GoogleFonts.inter(color: _isEditing ? textPrimary : textSecondary, fontSize: 16),
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildAnimatedActionButtons() {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 400),
//       curve: Curves.easeInOut,
//       child: Row(
//         children: [
//           Expanded(
//             child: ElevatedButton.icon(
//               onPressed: _isSaving ? null : _savePatientRecord,
//               icon: _isSaving
//                   ? SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                       ),
//                     )
//                   : Icon(Icons.save_rounded, size: 20),
//               label: Text(
//                 _isSaving ? 'Saving...' : 'Save Changes',
//                 style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
//               ),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: primaryColor,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 elevation: 2,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: OutlinedButton.icon(
//               onPressed: () => setState(() => _isEditing = false),
//               icon: const Icon(Icons.cancel_rounded, size: 20),
//               label: Text('Cancel', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
//               style: OutlinedButton.styleFrom(
//                 foregroundColor: textSecondary,
//                 side: BorderSide(color: Colors.grey[400]!, width: 1.5),
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _savePatientRecord() async {
//     setState(() => _isSaving = true);

//     try {
//       await FirebaseFirestore.instance.collection('users').doc(_selectedPatientId).update({
//         'allergies': _controllers['allergies']!.text.trim(),
//         'medicalConditions': _controllers['medicalConditions']!.text.trim(),
//         'height': _controllers['height']!.text.trim(),
//         'weight': _controllers['weight']!.text.trim(),
//         'bloodGroup': _controllers['bloodGroup']!.text.trim(),
//       });

//       setState(() {
//         _isEditing = false;
//         _isSaving = false;
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.check_circle_rounded, color: Colors.white),
//               const SizedBox(width: 12),
//               Text('Patient records updated successfully!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
//             ],
//           ),
//           backgroundColor: Colors.green[600],
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(16),
//         ),
//       );
//     } catch (e) {
//       setState(() => _isSaving = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: [
//               Icon(Icons.error_rounded, color: Colors.white),
//               const SizedBox(width: 12),
//               Expanded(child: Text('Failed to update records: $e', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500))),
//             ],
//           ),
//           backgroundColor: Colors.red[600],
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           behavior: SnackBarBehavior.floating,
//           margin: const EdgeInsets.all(16),
//         ),
//       );
//     }
//   }

//   Widget _buildEmptyState() {
//     return FadeTransition(
//       opacity: _fadeAnimation,
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(32),
//           padding: const EdgeInsets.all(40),
//           decoration: BoxDecoration(
//             color: cardColor,
//             borderRadius: BorderRadius.circular(20),
//             boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 4))],
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
//                 child: Icon(Icons.people_outline_rounded, size: 48, color: Colors.grey[400]),
//               ),
//               const SizedBox(height: 24),
//               Text('No Patients Found', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary)),
//               const SizedBox(height: 12),
//               Text('No patient records are available at the moment.', style: GoogleFonts.inter(fontSize: 16, color: textSecondary), textAlign: TextAlign.center),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: backgroundColor,
//       appBar: AppBar(
//         title: Text('Patient Records', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
//         backgroundColor: primaryColor,
//         elevation: 0,
//         centerTitle: true,
//         leading: null, // Removed back arrow
//         actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _fetchPatients)],
//       ),
//       body: _isLoading
//           ? Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
//                   const SizedBox(height: 16),
//                   Text('Loading patients...', style: GoogleFonts.inter(color: textSecondary, fontSize: 16)),
//                 ],
//               ),
//             )
//           : _errorMessage != null
//               ? Center(
//                   child: Container(
//                     margin: const EdgeInsets.all(32),
//                     padding: const EdgeInsets.all(32),
//                     decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
//                         const SizedBox(height: 16),
//                         Text('Something went wrong', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary)),
//                         const SizedBox(height: 8),
//                         Text(_errorMessage!, style: GoogleFonts.inter(color: Colors.red[700], fontSize: 14), textAlign: TextAlign.center),
//                         const SizedBox(height: 24),
//                         ElevatedButton.icon(
//                           onPressed: _fetchPatients,
//                           icon: const Icon(Icons.refresh_rounded),
//                           label: Text('Try Again', style: GoogleFonts.inter()),
//                           style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               : SingleChildScrollView(
//                   child: Column(
//                     children: [
//                       _buildAnimatedSearchSection(),
//                       if (_selectedPatientId != null)
//                         StreamBuilder<DocumentSnapshot>(
//                           stream: FirebaseFirestore.instance.collection('users').doc(_selectedPatientId).snapshots(),
//                           builder: (context, snapshot) {
//                             if (snapshot.connectionState == ConnectionState.waiting) {
//                               return Container(
//                                 margin: const EdgeInsets.all(16),
//                                 height: 200,
//                                 child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor))),
//                               );
//                             }
//                             if (snapshot.hasError) {
//                               return Container(
//                                 margin: const EdgeInsets.all(16),
//                                 padding: const EdgeInsets.all(16),
//                                 decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
//                                 child: Text('Error loading patient data: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)),
//                               );
//                             }
//                             if (!snapshot.hasData || !snapshot.data!.exists) {
//                               return Container(
//                                 margin: const EdgeInsets.all(16),
//                                 padding: const EdgeInsets.all(16),
//                                 decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
//                                 child: Text('Patient not found', style: GoogleFonts.inter()),
//                               );
//                             }
//                             final data = snapshot.data!.data() as Map<String, dynamic>;
//                             return _buildAnimatedPatientRecord(data);
//                           },
//                         )
//                       else if (_allPatients.isEmpty && !_isLoading)
//                         _buildEmptyState(),
//                       const SizedBox(height: 32),
//                     ],
//                   ),
//                 ),
//     );
//   }
// }


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  Timer? _debounce;

  // Admin color scheme
  final Color primaryColor = const Color(0xFF808000); // Olive green
  final Color accentColor = const Color(0xFFC2A50A); // Mustard yellow
  final Color backgroundColor = const Color(0xFFF5F5F0); // Beige background
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF1A1A1A);
  final Color textSecondary = const Color(0xFF666666);

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
    for (var controller in _controllers.values) {
      controller.dispose();
    }
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
      _isEditing = false;
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor.withOpacity(0.1), Colors.white],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 6))],
          ),
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
                  Text('Search Patients', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary)),
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
          hintStyle: GoogleFonts.inter(color: textSecondary, fontSize: 16),
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
        style: GoogleFonts.inter(fontSize: 16, color: textPrimary),
      ),
    );
  }

  Widget _buildAnimatedDropdown() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: DropdownButtonFormField<String>(
        value: _selectedPatientId,
        hint: Text('Select Patient', style: GoogleFonts.inter(color: textSecondary, fontSize: 16)),
        items: _filteredPatients.map((patient) {
          return DropdownMenuItem(
            value: patient['id'],
            child: Text(patient['name']!, style: GoogleFonts.inter(fontSize: 16, color: textPrimary)),
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
          labelStyle: GoogleFonts.inter(color: primaryColor, fontSize: 16),
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
        color: accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No patients found matching "${_searchController.text}"',
              style: GoogleFonts.inter(color: accentColor, fontSize: 14),
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
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.15), blurRadius: 25, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPatientHeader(),
              const SizedBox(height: 24),
              Divider(color: Colors.grey[200], height: 1),
              const SizedBox(height: 24),
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
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryColor, accentColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _selectedPatientName ?? 'Unknown Patient',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text('Admin Medical Records', style: GoogleFonts.inter(fontSize: 14, color: textSecondary)),
            ],
          ),
        ),
        if (!_isEditing)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.edit_rounded, color: primaryColor, size: 20),
              ),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Records',
            ),
          ),
      ],
    );
  }

  Widget _buildMedicalRecordsForm(Map<String, dynamic> data) {
    if (!_isEditing) {
      _controllers['allergies']!.text = data['allergies']?.toString() ?? '';
      _controllers['medicalConditions']!.text = data['medicalConditions']?.toString() ?? '';
      _controllers['height']!.text = data['height']?.toString() ?? '';
      _controllers['weight']!.text = data['weight']?.toString() ?? '';
      _controllers['bloodGroup']!.text = data['bloodGroup']?.toString() ?? '';
    }

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
                  color: Colors.red[200]!,
                  hint: 'A+, B-, O+, AB-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRecordCard(
                  controller: _controllers['height']!,
                  label: 'Height (cm)',
                  icon: Icons.height_rounded,
                  color: Colors.blue[200]!,
                  hint: '175',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRecordCard(
                  controller: _controllers['weight']!,
                  label: 'Weight (kg)',
                  icon: Icons.monitor_weight_rounded,
                  color: Colors.green[200]!,
                  hint: '70',
                ),
              ),
              const Expanded(child: SizedBox()), // Placeholder for symmetry
            ],
          ),
          const SizedBox(height: 12),
          _buildFullWidthRecordCard(
            controller: _controllers['allergies']!,
            label: 'Allergies',
            icon: Icons.warning_amber_rounded,
            color: Colors.orange[200]!,
            hint: 'List known allergies...',
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          _buildFullWidthRecordCard(
            controller: _controllers['medicalConditions']!,
            label: 'Medical Conditions',
            icon: Icons.medical_information_rounded,
            color: Colors.purple[200]!,
            hint: 'List current medical conditions...',
            maxLines: 4,
          ),
          const SizedBox(height: 32),
          if (_isEditing) _buildAnimatedActionButtons(),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: _isEditing ? primaryColor : textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            readOnly: !_isEditing,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: textSecondary.withOpacity(0.7), fontSize: 16),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
            style: GoogleFonts.inter(color: _isEditing ? textPrimary : textSecondary, fontSize: 16),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: _isEditing ? primaryColor : textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            readOnly: !_isEditing,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(color: textSecondary.withOpacity(0.7), fontSize: 16),
              border: InputBorder.none,
              filled: true,
              fillColor: Colors.transparent,
            ),
            style: GoogleFonts.inter(color: _isEditing ? textPrimary : textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedActionButtons() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _savePatientRecord,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _isEditing = false),
              icon: const Icon(Icons.cancel_rounded, size: 20),
              label: Text('Cancel', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: textSecondary,
                side: BorderSide(color: Colors.grey[400]!, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _savePatientRecord() async {
    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(_selectedPatientId).update({
        'allergies': _controllers['allergies']!.text.trim(),
        'medicalConditions': _controllers['medicalConditions']!.text.trim(),
        'height': _controllers['height']!.text.trim(),
        'weight': _controllers['weight']!.text.trim(),
        'bloodGroup': _controllers['bloodGroup']!.text.trim(),
      });

      setState(() {
        _isEditing = false;
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Text('Patient records updated successfully!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
            ],
          ),
          backgroundColor: Colors.green[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to update records: $e', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500))),
            ],
          ),
          backgroundColor: Colors.red[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    }
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
              Text('No Patients Found', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary)),
              const SizedBox(height: 12),
              Text('No patient records are available at the moment.', style: GoogleFonts.inter(fontSize: 16, color: textSecondary), textAlign: TextAlign.center),
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
        title: Text('Admin Patient Records', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        backgroundColor: primaryColor,
        elevation: 4,
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
                  Text('Loading patients...', style: GoogleFonts.inter(color: textSecondary, fontSize: 16)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[400]),
                        const SizedBox(height: 16),
                        Text('Something went wrong', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary)),
                        const SizedBox(height: 8),
                        Text(_errorMessage!, style: GoogleFonts.inter(color: Colors.red[700], fontSize: 14), textAlign: TextAlign.center),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _fetchPatients,
                          icon: const Icon(Icons.refresh_rounded),
                          label: Text('Try Again', style: GoogleFonts.inter()),
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
                                child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor))),
                              );
                            }
                            if (snapshot.hasError) {
                              return Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                                child: Text('Error loading patient data: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)),
                              );
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Container(
                                margin: const EdgeInsets.all(16),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12)),
                                child: Text('Patient not found', style: GoogleFonts.inter()),
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