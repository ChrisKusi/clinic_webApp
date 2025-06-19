// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:intl/intl.dart';

// class AppointmentsScreen extends StatefulWidget {
//   const AppointmentsScreen({super.key});

//   @override
//   State<AppointmentsScreen> createState() => _AppointmentsScreenState();
// }

// class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
//   DateTime? _selectedDate;
//   String? _selectedDoctor;
//   String? _selectedStatus;
//   Map<String, Map<String, dynamic>> _usersCache = {};
//   List<Map<String, dynamic>> _doctors = [];
//   bool _isLoading = true;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 600),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _fetchDoctors();
//     _setupUsersListener();
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchDoctors() async {
//     try {
//       final snapshot = await FirebaseFirestore.instance
//           .collection('doctors')
//           .get();
//       setState(() {
//         _doctors = snapshot.docs.map((doc) => {
//           'id': doc.id,
//           'name': doc['name'],
//         }).toList();
//         _isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error fetching doctors: $e')),
//       );
//     }
//   }

//   void _setupUsersListener() {
//     FirebaseFirestore.instance
//         .collectionGroup('users')
//         .where('role', whereIn: ['doctor', 'patient'])
//         .snapshots()
//         .listen((snapshot) {
//       setState(() {
//         _usersCache = {for (var doc in snapshot.docs) doc.id: doc.data()};
//       });
//     }, onError: (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error listening to users: $e')),
//       );
//     });
//   }

//   Stream<QuerySnapshot> _getAppointmentsStream() {
//     Query query = FirebaseFirestore.instance.collection('appointments');

//     if (_selectedDate != null) {
//       final startOfDay = Timestamp.fromDate(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day));
//       final endOfDay = Timestamp.fromDate(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59));
//       query = query
//           .where('date', isGreaterThanOrEqualTo: startOfDay)
//           .where('date', isLessThanOrEqualTo: endOfDay);
//     }
//     if (_selectedDoctor != null) {
//       query = query.where('doctorId', isEqualTo: _selectedDoctor);
//     }
//     if (_selectedStatus != null) {
//       query = query.where('status', isEqualTo: _selectedStatus);
//     }

//     return query.orderBy('date').snapshots();
//   }

//   void _clearFilters() {
//     setState(() {
//       _selectedDate = null;
//       _selectedDoctor = null;
//       _selectedStatus = null;
//     });
//   }

//   Color _getStatusColor(String status) {
//     switch (status.toLowerCase()) {
//       case 'scheduled':
//         return const Color(0xFF808000);
//       case 'completed':
//         return const Color(0xFF4CAF50);
//       case 'canceled':
//         return const Color(0xFFF44336);
//       default:
//         return const Color(0xFFB0BEC5);
//     }
//   }

//   String _formatDate(DateTime date) {
//     return DateFormat('dd/MM/yyyy').format(date);
//   }

//   String _formatTime(String time) {
//     try {
//       final parsedTime = DateFormat('HH:mm').parse(time);
//       return DateFormat('h:mm a').format(parsedTime);
//     } catch (_) {
//       return time;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F0),
//       appBar: AppBar(
//         title: Text(
//           'Appointments Management',
//           style: GoogleFonts.inter(
//             fontSize: 22,
//             fontWeight: FontWeight.w700,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: const Color(0xFF808000),
//         elevation: 4,
//         centerTitle: true,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
//             onPressed: () {
//               setState(() {
//                 _isLoading = true;
//                 _fetchDoctors();
//               });
//             },
//           ),
//         ],
//       ),
//       body: FadeTransition(
//         opacity: _fadeAnimation,
//         child: Column(
//           children: [
//             Container(
//               width: double.infinity,
//               margin: const EdgeInsets.all(16),
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [const Color(0xFFC2A50A).withOpacity(0.2), Colors.white],
//                 ),
//                 borderRadius: BorderRadius.circular(24),
//                 boxShadow: [
//                   BoxShadow(
//                     color: const Color(0xFF808000).withOpacity(0.15),
//                     blurRadius: 20,
//                     offset: const Offset(0, 6),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.filter_list_rounded,
//                         color: const Color(0xFF808000),
//                         size: 28,
//                       ),
//                       const SizedBox(width: 16),
//                       Text(
//                         'Filter Appointments',
//                         style: GoogleFonts.inter(
//                           fontSize: 20,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF1A1A1A),
//                         ),
//                       ),
//                       const Spacer(),
//                       if (_selectedDate != null || _selectedDoctor != null || _selectedStatus != null)
//                         ElevatedButton(
//                           onPressed: _clearFilters,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: const Color(0xFFC2A50A),
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                           ),
//                           child: Text(
//                             'Clear All',
//                             style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
//                           ),
//                         ),
//                     ],
//                   ),
//                   const SizedBox(height: 20),
//                   LayoutBuilder(
//                     builder: (context, constraints) {
//                       if (constraints.maxWidth > 600) {
//                         return Row(
//                           children: [
//                             Expanded(child: _buildDateFilter()),
//                             const SizedBox(width: 20),
//                             Expanded(child: _buildDoctorFilter()),
//                             const SizedBox(width: 20),
//                             Expanded(child: _buildStatusFilter()),
//                           ],
//                         );
//                       } else {
//                         return Column(
//                           children: [
//                             _buildDateFilter(),
//                             const SizedBox(height: 16),
//                             _buildDoctorFilter(),
//                             const SizedBox(height: 16),
//                             _buildStatusFilter(),
//                           ],
//                         );
//                       }
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: Container(
//                 margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(24),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF808000).withOpacity(0.1),
//                       blurRadius: 20,
//                       offset: const Offset(0, 6),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [const Color(0xFFC2A50A).withOpacity(0.2), Colors.white],
//                         ),
//                         borderRadius: const BorderRadius.only(
//                           topLeft: Radius.circular(24),
//                           topRight: Radius.circular(24),
//                         ),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.event_note_rounded,
//                             color: const Color(0xFF808000),
//                             size: 28,
//                           ),
//                           const SizedBox(width: 16),
//                           Text(
//                             'Appointments List',
//                             style: GoogleFonts.inter(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w600,
//                               color: const Color(0xFF1A1A1A),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: _isLoading
//                           ? const Center(
//                               child: CircularProgressIndicator(
//                                 valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF808000)),
//                               ),
//                             )
//                           : StreamBuilder<QuerySnapshot>(
//                               stream: _getAppointmentsStream(),
//                               builder: (context, snapshot) {
//                                 if (snapshot.connectionState == ConnectionState.waiting) {
//                                   return const Center(
//                                     child: CircularProgressIndicator(
//                                       valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF808000)),
//                                     ),
//                                   );
//                                 }
//                                 if (snapshot.hasError) {
//                                   return _buildErrorState();
//                                 }
//                                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                                   return _buildEmptyState();
//                                 }
//                                 final appointments = snapshot.data!.docs;
//                                 return ListView.builder(
//                                   padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//                                   itemCount: appointments.length,
//                                   itemBuilder: (context, index) {
//                                     return _buildAppointmentCard(appointments[index]);
//                                   },
//                                 );
//                               },
//                             ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDateFilter() {
//     return InkWell(
//       onTap: () async {
//         final date = await showDatePicker(
//           context: context,
//           initialDate: _selectedDate ?? DateTime.now(),
//           firstDate: DateTime(2020),
//           lastDate: DateTime(2030),
//           builder: (context, child) {
//             return Theme(
//               data: Theme.of(context).copyWith(
//                 colorScheme: const ColorScheme.light(
//                   primary: Color(0xFF808000),
//                 ),
//               ),
//               child: child!,
//             );
//           },
//         );
//         setState(() => _selectedDate = date);
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           border: Border.all(
//             color: _selectedDate != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
//             width: 2,
//           ),
//           borderRadius: BorderRadius.circular(12),
//           color: _selectedDate != null ? const Color(0xFFC2A50A).withOpacity(0.1) : Colors.transparent,
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.calendar_today_rounded,
//               size: 20,
//               color: _selectedDate != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
//             ),
//             const SizedBox(width: 10),
//             Text(
//               _selectedDate == null ? 'Select Date' : _formatDate(_selectedDate!),
//               style: GoogleFonts.inter(
//                 fontSize: 16,
//                 fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.w400,
//                 color: _selectedDate != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDoctorFilter() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: _selectedDoctor != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
//           width: 2,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         color: _selectedDoctor != null ? const Color(0xFFC2A50A).withOpacity(0.1) : Colors.transparent,
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           hint: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.local_hospital_rounded,
//                 size: 20,
//                 color: Color(0xFFC2A50A),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 'Select Doctor',
//                 style: GoogleFonts.inter(
//                   fontSize: 16,
//                   color: const Color(0xFFC2A50A),
//                 ),
//               ),
//             ],
//           ),
//           value: _selectedDoctor,
//           isExpanded: true,
//           items: _doctors.map<DropdownMenuItem<String>>((doctor) {
//             return DropdownMenuItem<String>(
//               value: doctor['id'] as String,
//               child: Text(
//                 doctor['name'] as String,
//                 style: GoogleFonts.inter(fontSize: 16),
//               ),
//             );
//           }).toList(),
//           onChanged: (value) => setState(() => _selectedDoctor = value),
//           selectedItemBuilder: (context) {
//             return _doctors.map<Widget>((doctor) {
//               return Row(
//                 children: [
//                   const Icon(
//                     Icons.local_hospital_rounded,
//                     size: 20,
//                     color: Color(0xFF808000),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     doctor['name'] as String,
//                     style: GoogleFonts.inter(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: const Color(0xFF808000),
//                     ),
//                   ),
//                 ],
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusFilter() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//       decoration: BoxDecoration(
//         border: Border.all(
//           color: _selectedStatus != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
//           width: 2,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         color: _selectedStatus != null ? const Color(0xFFC2A50A).withOpacity(0.1) : Colors.transparent,
//       ),
//       child: DropdownButtonHideUnderline(
//         child: DropdownButton<String>(
//           hint: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.info_outline_rounded,
//                 size: 20,
//                 color: Color(0xFFC2A50A),
//               ),
//               const SizedBox(width: 10),
//               Text(
//                 'Select Status',
//                 style: GoogleFonts.inter(
//                   fontSize: 16,
//                   color: const Color(0xFFC2A50A),
//                 ),
//               ),
//             ],
//           ),
//           value: _selectedStatus,
//           isExpanded: true,
//           items: ['scheduled', 'completed', 'canceled'].map((status) {
//             return DropdownMenuItem(
//               value: status,
//               child: Text(
//                 status.toUpperCase(),
//                 style: GoogleFonts.inter(fontSize: 16),
//               ),
//             );
//           }).toList(),
//           onChanged: (value) => setState(() => _selectedStatus = value),
//           selectedItemBuilder: (context) {
//             return ['scheduled', 'completed', 'canceled'].map<Widget>((status) {
//               return Row(
//                 children: [
//                   const Icon(
//                     Icons.info_outline_rounded,
//                     size: 20,
//                     color: Color(0xFF808000),
//                   ),
//                   const SizedBox(width: 10),
//                   Text(
//                     status.toUpperCase(),
//                     style: GoogleFonts.inter(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: const Color(0xFF808000),
//                     ),
//                   ),
//                 ],
//               );
//             }).toList();
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.error_outline_rounded,
//               size: 60,
//               color: const Color(0xFFF44336),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Error Loading Appointments',
//               style: GoogleFonts.inter(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: const Color(0xFF1A1A1A),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Please check your connection and try again.',
//               style: GoogleFonts.inter(
//                 fontSize: 16,
//                 color: const Color(0xFF666666),
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   _isLoading = true;
//                   _fetchDoctors();
//                 });
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF808000),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//               ),
//               child: Text(
//                 'Retry',
//                 style: GoogleFonts.inter(fontSize: 16),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.event_busy_rounded,
//               size: 80,
//               color: const Color(0xFFB0BEC5),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'No Appointments Found',
//               style: GoogleFonts.inter(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w600,
//                 color: const Color(0xFF1A1A1A),
//               ),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Try adjusting your filters or check back later.',
//               style: GoogleFonts.inter(
//                 fontSize: 16,
//                 color: const Color(0xFF666666),
//               ),
//               textAlign: TextAlign.center,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAppointmentCard(QueryDocumentSnapshot appointmentDoc) {
//     final appointment = appointmentDoc.data() as Map<String, dynamic>;
//     final doctorName = _usersCache[appointment['doctorId']]?['name'] ?? 'Unknown Doctor';
//     final patientName = _usersCache[appointment['patientId']]?['name'] ?? 'Unknown Patient';
//     final date = (appointment['date'] as Timestamp?)?.toDate() ?? DateTime.now();
//     final time = appointment['time'] as String? ?? 'N/A';
//     final status = appointment['status'] as String? ?? 'Unknown';
//     final appointmentType = appointment['type'] as String? ?? 'Not specified';
//     final notes = appointment['notes'] as String? ?? '';

//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       elevation: 0,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [const Color(0xFFF5F5F0), const Color(0xFFC2A50A).withOpacity(0.1)],
//           ),
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: [
//             BoxShadow(
//               color: const Color(0xFF808000).withOpacity(0.15),
//               blurRadius: 12,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: _getStatusColor(status).withOpacity(0.2),
//                     borderRadius: BorderRadius.circular(20),
//                     border: Border.all(
//                       color: _getStatusColor(status).withOpacity(0.5),
//                     ),
//                   ),
//                   child: Text(
//                     status.toUpperCase(),
//                     style: GoogleFonts.inter(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                       color: _getStatusColor(status),
//                     ),
//                   ),
//                 ),
//                 Text(
//                   _formatDate(date),
//                   style: GoogleFonts.inter(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: const Color(0xFF808000),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Doctor',
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: const Color(0xFF666666),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         doctorName,
//                         style: GoogleFonts.inter(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF1A1A1A),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Patient',
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: const Color(0xFF666666),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         patientName,
//                         style: GoogleFonts.inter(
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF1A1A1A),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 12),
//             Row(
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Time',
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: const Color(0xFF666666),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFC2A50A).withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color: const Color(0xFFC2A50A).withOpacity(0.5),
//                           ),
//                         ),
//                         child: Text(
//                           _formatTime(time),
//                           style: GoogleFonts.inter(
//                             fontSize: 14,
//                             fontWeight: FontWeight.w600,
//                             color: const Color(0xFFC2A50A),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'Type',
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: const Color(0xFF666666),
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         appointmentType,
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w600,
//                           color: const Color(0xFF1A1A1A),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//             if (notes.isNotEmpty) ...[
//               const SizedBox(height: 12),
//               Text(
//                 'Notes',
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   color: const Color(0xFF666666),
//                 ),
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 notes,
//                 style: GoogleFonts.inter(
//                   fontSize: 14,
//                   color: const Color(0xFF1A1A1A),
//                 ),
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> with TickerProviderStateMixin {
  DateTime? _selectedDate;
  String? _selectedDoctor;
  String? _selectedStatus;
  Map<String, Map<String, dynamic>> _doctorsCache = {};
  List<Map<String, dynamic>> _doctors = [];
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
    _fetchDoctors();
    _setupDoctorsListener();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _fetchDoctors() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('doctors')
          .get();
      
      setState(() {
        _doctors = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name'],
          'specialization': doc['specialization'] ?? 'Not specified',
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching doctors: $e')),
      );
    }
  }

  void _setupDoctorsListener() {
    FirebaseFirestore.instance
        .collection('doctors')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _doctorsCache = {for (var doc in snapshot.docs) doc.id: doc.data()};
      });
    }, onError: (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error listening to doctors: $e')),
      );
    });
  }

  Stream<QuerySnapshot> _getAppointmentsStream() {
    Query query = FirebaseFirestore.instance.collection('appointments');
    
    if (_selectedDate != null) {
      final startOfDay = Timestamp.fromDate(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day));
      final endOfDay = Timestamp.fromDate(_selectedDate!.add(const Duration(days: 1)));
      query = query
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay);
    }
    if (_selectedDoctor != null && _selectedDoctor!.isNotEmpty) {
      query = query.where('doctorId', isEqualTo: _selectedDoctor);
    }
    if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    
    return query.orderBy('date', descending: true).snapshots();
  }

  void _clearFilters() {
    setState(() {
      _selectedDate = null;
      _selectedDoctor = null;
      _selectedStatus = null;
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return const Color(0xFF808000);
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'cancelled':
        return const Color(0xFFF44336);
      default:
        return const Color(0xFFB0BEC5);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(String timeSlot) {
    return timeSlot; // e.g., "04:00 PM"
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        title: Text(
          'Appointments Management',
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF808000),
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 24),
            onPressed: () {
              setState(() {
                _fetchDoctors();
              });
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxHeight: 300), // Limit filter height
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF808000).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          color: const Color(0xFF808000),
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Filter Appointments',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const Spacer(),
                        if (_selectedDate != null || _selectedDoctor != null || _selectedStatus != null)
                          ElevatedButton(
                            onPressed: _clearFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFC2A50A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            child: const Text(
                              'Clear All',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: _buildFilterCard(_buildDateFilter(), 'Date')),
                              const SizedBox(width: 20),
                              Expanded(child: _buildFilterCard(_buildDoctorFilter(), 'Doctor')),
                              const SizedBox(width: 20),
                              Expanded(child: _buildFilterCard(_buildStatusFilter(), 'Status')),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildFilterCard(_buildDateFilter(), 'Date'),
                              const SizedBox(height: 16),
                              _buildFilterCard(_buildDoctorFilter(), 'Doctor'),
                              const SizedBox(height: 16),
                              _buildFilterCard(_buildStatusFilter(), 'Status'),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF808000).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [const Color(0xFFC2A50A).withOpacity(0.2), Colors.white],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_note_rounded,
                            color: const Color(0xFF808000),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Appointments List',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF808000)),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                              child: StreamBuilder<QuerySnapshot>(
                                stream: _getAppointmentsStream(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF808000)),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    print('Stream Error: ${snapshot.error}'); // Debug log
                                    return _buildErrorState(snapshot.error.toString());
                                  }
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return _buildEmptyState();
                                  }
                                  final appointments = snapshot.data!.docs;
                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    padding: EdgeInsets.zero,
                                    itemCount: appointments.length,
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

  Widget _buildFilterCard(Widget filterWidget, String label) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF808000),
              ),
            ),
            const SizedBox(height: 8),
            filterWidget,
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return InkWell(
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
                  primary: Color(0xFF808000),
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) setState(() => _selectedDate = date);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedDate != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(10),
          color: _selectedDate != null ? const Color(0xFFC2A50A).withOpacity(0.1) : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: _selectedDate != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
            ),
            const SizedBox(width: 10),
            Text(
              _selectedDate == null ? 'Select Date' : _formatDate(_selectedDate!),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.w400,
                color: _selectedDate != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedDoctor != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
        color: _selectedDoctor != null ? const Color(0xFFC2A50A).withOpacity(0.1) : Colors.transparent,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_hospital_rounded,
                size: 20,
                color: Color(0xFFC2A50A),
              ),
              const SizedBox(width: 10),
              Text(
                'Select Doctor',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFFC2A50A),
                ),
              ),
            ],
          ),
          value: _selectedDoctor,
          isExpanded: true,
          items: _doctors.map<DropdownMenuItem<String>>((doctor) {
            return DropdownMenuItem<String>(
              value: doctor['id'] as String,
              child: Text(
                '${doctor['name']} (${doctor['specialization']})',
                style: GoogleFonts.inter(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedDoctor = value),
          selectedItemBuilder: (context) {
            return _doctors.map<Widget>((doctor) {
              return Row(
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    size: 20,
                    color: Color(0xFF808000),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${doctor['name']} (${doctor['specialization']})',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF808000),
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildStatusFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedStatus != null ? const Color(0xFF808000) : const Color(0xFFC2A50A),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
        color: _selectedStatus != null ? const Color(0xFFC2A50A).withOpacity(0.1) : Colors.transparent,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 20,
                color: Color(0xFFC2A50A),
              ),
              const SizedBox(width: 10),
              Text(
                'Select Status',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFFC2A50A),
                ),
              ),
            ],
          ),
          value: _selectedStatus,
          isExpanded: true,
          items: ['scheduled', 'completed', 'cancelled'].map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(
                status.toUpperCase(),
                style: GoogleFonts.inter(fontSize: 16),
              ),
            );
          }).toList(),
          onChanged: (value) => setState(() => _selectedStatus = value),
          selectedItemBuilder: (_) {
            return ['scheduled', 'completed', 'cancelled'].map<Widget>((status) {
              return Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: Color(0xFF808000),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF808000),
                    ),
                  ),
                ],
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: Color(0xFFF44336),
            ),
            const SizedBox(height: 20),
            Text(
              'Error loading appointments',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Error: $errorMessage\nPlease create the required index via the Firebase Console link above and try again.',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_busy_rounded,
              size: 80,
              color: Color(0xFFB0BEC5),
            ),
            const SizedBox(height: 20),
            Text(
              'No Appointments Found',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your filters or check back later',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(QueryDocumentSnapshot appointmentDoc) {
    final appointment = appointmentDoc.data() as Map<String, dynamic>;
    final doctorId = appointment['doctorId'] as String? ?? '';
    final userId = appointment['userId'] as String? ?? '';
    final doctorName = appointment['doctorName'] as String? ?? (_doctorsCache[doctorId]?['name'] ?? 'Unknown Doctor');
    final patientName = _doctorsCache[userId]?['name'] ?? 'Unknown Patient'; // Assuming userId links to patient
    final date = (appointment['date'] as Timestamp?)?.toDate() ?? DateTime.now();
    final timeSlot = appointment['timeSlot'] as String? ?? 'N/A';
    final status = appointment['status'] as String? ?? 'Unknown';
    final department = appointment['department'] as String? ?? 'Not specified';
    final type = appointment['type'] as String? ?? 'N/A';

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFFF5F5F0), const Color(0xFFC2A50A).withOpacity(0.1)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_formatDate(date)} ${_formatTime(timeSlot)}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF808000),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctorName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Patient',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        patientName,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Department',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        department,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Type',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}