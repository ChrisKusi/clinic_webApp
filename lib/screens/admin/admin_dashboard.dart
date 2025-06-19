// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'register_user_screen.dart';
// import 'appointments_screen.dart';
// import 'patient_records_screen.dart';
// import 'messages_screen.dart';
// import 'notifications_screen.dart';
// import 'admin_profile_screen.dart';
// import 'package:clinic_web_dashboard/screens/user_list_screen.dart';

// class AdminDashboard extends StatefulWidget {
//   const AdminDashboard({super.key});

//   @override
//   State<AdminDashboard> createState() => _AdminDashboardState();
// }

// class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
//   bool _isSidebarExpanded = false;
//   late AnimationController _animationController;
//   late Animation<double> _fadeAnimation;
//   int _selectedIndex = 0;

//   final List<Map<String, dynamic>> _sidebarItems = [
//     {'title': 'Overview', 'icon': Icons.home},
//     {'title': 'Register User', 'icon': Icons.person_add},
//     {'title': 'Appointments', 'icon': Icons.calendar_today},
//     {'title': 'Patient Records', 'icon': Icons.people},
//     {'title': 'Messages', 'icon': Icons.message},
//     {'title': 'Notifications', 'icon': Icons.notifications},
//     {'title': 'User List', 'icon': Icons.group},
//     {'title': 'Profile', 'icon': Icons.person},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 800),
//     );
//     _fadeAnimation = CurvedAnimation(
//       parent: _animationController,
//       curve: Curves.easeInOut,
//     );
//     _animationController.forward();
//   }

//   @override
//   void dispose() {
//     _animationController.dispose();
//     super.dispose();
//   }

//   void _onSidebarItemTap(int index) {
//     print('Tapped sidebar item: $index - ${_sidebarItems[index]['title']}');
//     setState(() {
//       _selectedIndex = index;
//       _isSidebarExpanded = false;
//     });
//   }

//   Future<void> _logout(BuildContext context) async {
//     try {
//       final userId = FirebaseAuth.instance.currentUser?.uid;
//       if (userId != null) {
//         await FirebaseFirestore.instance.collection('presence').doc(userId).update({
//           'online': false,
//           'lastSeen': FieldValue.serverTimestamp(),
//         });
//         print('Presence updated: offline for user $userId');
//       }
//       await FirebaseAuth.instance.signOut();
//       print('Logout successful');
//       Navigator.pushReplacementNamed(context, '/login');
//     } catch (e) {
//       print('Logout error: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Error logging out: $e',
//             style: GoogleFonts.roboto(color: Colors.white),
//           ),
//           backgroundColor: Colors.redAccent,
//         ),
//       );
//     }
//   }

//   Widget _getCurrentScreen() {
//     switch (_selectedIndex) {
//       case 0:
//         return const OverviewScreen();
//       case 1:
//         return const RegisterUserScreen();
//       case 2:
//         return const AppointmentsScreen();
//       case 3:
//         return const PatientRecordsScreen();
//       case 4:
//         return const MessagesScreen();
//       case 5:
//         return const NotificationsScreen();
//       case 6:
//         return const UserListScreen();
//       case 7:
//         return const AdminProfileScreen();
//       default:
//         return const OverviewScreen();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: LayoutBuilder(
//         builder: (context, constraints) {
//           final maxSidebarWidth = constraints.maxWidth > 600 ? 250.0 : 200.0;
//           final minSidebarWidth = constraints.maxWidth > 600 ? 70.0 : 60.0;
//           final isMobile = constraints.maxWidth < 768;

//           return Row(
//             children: [
//               AnimatedContainer(
//                 duration: const Duration(milliseconds: 300),
//                 width: _isSidebarExpanded ? maxSidebarWidth : minSidebarWidth,
//                 decoration: const BoxDecoration(
//                   color: Color(0xFF808000),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black12,
//                       blurRadius: 4,
//                       offset: Offset(2, 0),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
//                       child: _isSidebarExpanded
//                           ? Row(
//                               children: [
//                                 const Icon(
//                                   Icons.local_hospital,
//                                   size: 28,
//                                   color: Colors.white,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'Deseret Hospital',
//                                     style: GoogleFonts.roboto(
//                                       fontSize: 14,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                     ),
//                                     overflow: TextOverflow.ellipsis,
//                                     maxLines: 1,
//                                   ),
//                                 ),
//                               ],
//                             )
//                           : Center(
//                               child: IconButton(
//                                 icon: const Icon(Icons.menu, color: Colors.white, size: 24),
//                                 onPressed: () {
//                                   print('Toggled sidebar');
//                                   setState(() => _isSidebarExpanded = true);
//                                 },
//                                 tooltip: 'Expand Menu',
//                                 padding: EdgeInsets.zero,
//                               ),
//                             ),
//                     ),
//                     Container(
//                       height: 1,
//                       color: Colors.white24,
//                       margin: const EdgeInsets.symmetric(horizontal: 8),
//                     ),
//                     Expanded(
//                       child: ListView.builder(
//                         padding: const EdgeInsets.symmetric(vertical: 8),
//                         itemCount: _sidebarItems.length,
//                         itemBuilder: (context, index) {
//                           return _buildSidebarItem(
//                             icon: _sidebarItems[index]['icon'],
//                             title: _sidebarItems[index]['title'],
//                             isExpanded: _isSidebarExpanded,
//                             isSelected: _selectedIndex == index,
//                             onTap: () => _onSidebarItemTap(index),
//                           );
//                         },
//                       ),
//                     ),
//                     Container(
//                       height: 1,
//                       color: Colors.white24,
//                       margin: const EdgeInsets.symmetric(horizontal: 8),
//                     ),
//                     _buildSidebarItem(
//                       icon: Icons.logout,
//                       title: 'Logout',
//                       isExpanded: _isSidebarExpanded,
//                       isSelected: false,
//                       onTap: () => _showLogoutDialog(context),
//                     ),
//                     if (_isSidebarExpanded)
//                       Container(
//                         padding: const EdgeInsets.all(12.0),
//                         child: Text(
//                           'Deseret Hospital\nCaring for Your Health',
//                           style: GoogleFonts.roboto(
//                             fontSize: 10,
//                             color: Colors.white70,
//                             fontStyle: FontStyle.italic,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//               Expanded(
//                 child: Column(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//                       decoration: const BoxDecoration(
//                         color: Colors.white,
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black12,
//                             blurRadius: 2,
//                             offset: Offset(0, 1),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         children: [
//                           if (isMobile && !_isSidebarExpanded)
//                             IconButton(
//                               icon: const Icon(Icons.menu, color: Color(0xFF808000)),
//                               onPressed: () {
//                                 setState(() => _isSidebarExpanded = true);
//                               },
//                             ),
//                           if (isMobile && !_isSidebarExpanded) const SizedBox(width: 8),
//                           const CircleAvatar(
//                             radius: 24,
//                             backgroundColor: Color(0xFF808000),
//                             child: Icon(Icons.person, size: 24, color: Colors.white),
//                           ),
//                           const SizedBox(width: 16),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   'Admin Dashboard',
//                                   style: GoogleFonts.roboto(
//                                     fontSize: 20,
//                                     fontWeight: FontWeight.bold,
//                                     color: const Color(0xFF808000),
//                                   ),
//                                 ),
//                                 Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: const Color(0xFF808000),
//                                     borderRadius: BorderRadius.circular(12),
//                                   ),
//                                   child: Text(
//                                     'Administrator',
//                                     style: GoogleFonts.roboto(
//                                       fontSize: 12,
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           if (isMobile && _isSidebarExpanded)
//                             IconButton(
//                               icon: const Icon(Icons.close, color: Color(0xFF808000)),
//                               onPressed: () {
//                                 setState(() => _isSidebarExpanded = false);
//                               },
//                             ),
//                         ],
//                       ),
//                     ),
//                     Expanded(
//                       child: AnimatedSwitcher(
//                         duration: const Duration(milliseconds: 300),
//                         child: FadeTransition(
//                           key: ValueKey(_selectedIndex),
//                           opacity: _fadeAnimation,
//                           child: _getCurrentScreen(),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildSidebarItem({
//     required IconData icon,
//     required String title,
//     required bool isExpanded,
//     required bool isSelected,
//     required VoidCallback onTap,
//   }) {
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(8),
//           hoverColor: Colors.white.withOpacity(0.1),
//           child: Container(
//             padding: EdgeInsets.symmetric(
//               horizontal: isExpanded ? 12 : 8,
//               vertical: 12,
//             ),
//             decoration: BoxDecoration(
//               color: isSelected ? Colors.black.withOpacity(0.2) : Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   icon,
//                   color: isSelected ? Colors.yellow : Colors.white,
//                   size: 22,
//                 ),
//                 if (isExpanded) const SizedBox(width: 12),
//                 if (isExpanded)
//                   Expanded(
//                     child: Text(
//                       title,
//                       style: GoogleFonts.roboto(
//                         fontSize: 14,
//                         color: isSelected ? Colors.yellow : Colors.white,
//                         fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                       ),
//                       overflow: TextOverflow.ellipsis,
//                       maxLines: 1,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showLogoutDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Logout',
//             style: GoogleFonts.roboto(
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF808000),
//             ),
//           ),
//           content: Text(
//             'Are you sure you want to logout?',
//             style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[800]),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: Text(
//                 'Cancel',
//                 style: GoogleFonts.roboto(
//                   fontSize: 14,
//                   color: const Color(0xFF808000),
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 Navigator.of(context).pop();
//                 await _logout(context);
//               },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF808000),
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//               ),
//               child: Text(
//                 'Logout',
//                 style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
//               ),
//             ),
//           ],
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//           backgroundColor: Colors.white,
//           elevation: 8,
//         );
//       },
//     );
//   }
// }

// class OverviewScreen extends StatelessWidget {
//   const OverviewScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24.0),
//       color: Colors.grey[50],
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Hospital Overview',
//             style: GoogleFonts.roboto(
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//               color: const Color(0xFF808000),
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Welcome to your admin dashboard',
//             style: GoogleFonts.roboto(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//           const SizedBox(height: 24),
//           Expanded(
//             child: GridView.count(
//               crossAxisCount: MediaQuery.of(context).size.width > 1200
//                   ? 4
//                   : MediaQuery.of(context).size.width > 800
//                       ? 3
//                       : 2,
//               crossAxisSpacing: 16,
//               mainAxisSpacing: 16,
//               childAspectRatio: 1.3,
//               children: [
//                 _buildStatCard('Total Users', '150', Icons.people, Colors.blue),
//                 _buildStatCard('Appointments Today', '23', Icons.calendar_today, Colors.green),
//                 _buildStatCard('Active Nurses', '45', Icons.medical_services, Colors.purple),
//                 _buildStatCard('Pending Messages', '8', Icons.message, Colors.orange),
//                 _buildStatCard('Patient Records', '1,234', Icons.folder, Colors.indigo),
//                 _buildStatCard('Notifications Sent', '67', Icons.notifications, Colors.red),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color color) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         padding: const EdgeInsets.all(20.0),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(16),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               color.withOpacity(0.1),
//               color.withOpacity(0.05),
//             ],
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 40, color: color),
//             const SizedBox(height: 12),
//             Text(
//               title,
//               style: GoogleFonts.roboto(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: Colors.grey[700],
//               ),
//               textAlign: TextAlign.center,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               value,
//               style: GoogleFonts.roboto(
//                 fontSize: 24,
//                 color: color,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class PlaceholderScreen extends StatelessWidget {
//   final String title;
//   final IconData icon;

//   const PlaceholderScreen({
//     super.key,
//     required this.title,
//     required this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(24.0),
//       color: Colors.grey[50],
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               icon,
//               size: 80,
//               color: const Color(0xFF808000),
//             ),
//             const SizedBox(height: 24),
//             Text(
//               title,
//               style: GoogleFonts.roboto(
//                 fontSize: 32,
//                 fontWeight: FontWeight.bold,
//                 color: const Color(0xFF808000),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               'This screen is under development',
//               style: GoogleFonts.roboto(
//                 fontSize: 18,
//                 color: Colors.grey[600],
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed: () {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text('$title feature coming soon!'),
//                     backgroundColor: const Color(0xFF808000),
//                   ),
//                 );
//               },
//               icon: const Icon(Icons.build, color: Colors.white),
//               label: const Text('Learn More', style: TextStyle(color: Colors.white)),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color(0xFF808000),
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_user_screen.dart';
import 'appointments_screen.dart';
import 'patient_records_screen.dart';
// import 'messages_screen.dart';
// import 'notifications_screen.dart';
import 'admin_profile_screen.dart';
import 'package:clinic_web_dashboard/screens/user_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  bool _isSidebarExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _selectedIndex = 0;
  String _adminName = 'Loading...';
  bool _isNameLoaded = false;

  final List<Map<String, dynamic>> _sidebarItems = [
    {'title': 'Overview', 'icon': Icons.home},
    {'title': 'Register User', 'icon': Icons.person_add},
    {'title': 'Appointments', 'icon': Icons.calendar_today},
    {'title': 'Patient Records', 'icon': Icons.people},
    // {'title': 'Messages', 'icon': Icons.message},
    // {'title': 'Notifications', 'icon': Icons.notifications},
    {'title': 'User List', 'icon': Icons.group},
    {'title': 'Profile', 'icon': Icons.person},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    _pulseController.repeat(reverse: true);
    _loadAdminName();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminName() async {
    if (!_isNameLoaded) {
      try {
        final userId = FirebaseAuth.instance.currentUser!.uid;
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();
        final data = snapshot.data() as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _adminName = data?['name'] ?? 'Admin';
            _isNameLoaded = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _adminName = 'Error loading name';
          });
        }
      }
    }
  }

  void _onSidebarItemTap(int index) {
    setState(() {
      _selectedIndex = index;
      _isSidebarExpanded = false;
    });
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseFirestore.instance.collection('presence').doc(userId).update({
          'online': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        print('Presence updated: offline for user $userId');
      }
      await FirebaseAuth.instance.signOut();
      print('Logout successful');
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Logout error: $e');
      _showSnackBar(context, 'Error logging out: $e', isError: true);
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: GoogleFonts.roboto(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF455A64),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey[800]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: const Color(0xFF546E7A),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF455A64),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: Text(
                'Logout',
                style: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white,
          elevation: 8,
        );
      },
    );
  }

  Widget _getCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const AdminOverviewScreen();
      case 1:
        return const RegisterUserScreen();
      case 2:
        return const AppointmentsScreen();
      case 3:
        return const PatientRecordsScreen();
      // case 4:
      //   return const MessagesScreen();
      // case 5:
      //   return const NotificationsScreen();
      case 4:
        return const UserListScreen();
      case 5:
        return const AdminProfileScreen();
      default:
        return const AdminOverviewScreen();
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
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
        backgroundColor: isError ? const Color(0xFFE53E3E) : const Color(0xFF4DB6AC),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxSidebarWidth = constraints.maxWidth > 600 ? 250.0 : 200.0;
          final minSidebarWidth = constraints.maxWidth > 600 ? 70.0 : 60.0;
          final isMobile = constraints.maxWidth < 768;

          return Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: _isSidebarExpanded ? maxSidebarWidth : minSidebarWidth,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF808000), const Color(0xFF4DB6AC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF808000).withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(2, 0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                      child: _isSidebarExpanded
                          ? Row(
                              children: [
                                ScaleTransition(
                                  scale: _pulseAnimation,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                                    ),
                                    child: const Icon(
                                      Icons.local_hospital,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Deseret Hospital',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            )
                          : Center(
                              child: IconButton(
                                icon: const Icon(Icons.menu, color: Colors.white, size: 24),
                                onPressed: () {
                                  setState(() => _isSidebarExpanded = true);
                                },
                                tooltip: 'Expand Menu',
                                padding: EdgeInsets.zero,
                              ),
                            ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _sidebarItems.length,
                        itemBuilder: (context, index) {
                          return _buildSidebarItem(
                            icon: _sidebarItems[index]['icon'],
                            title: _sidebarItems[index]['title'],
                            isExpanded: _isSidebarExpanded,
                            isSelected: _selectedIndex == index,
                            onTap: () => _onSidebarItemTap(index),
                          );
                        },
                      ),
                    ),
                    Container(
                      height: 1,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    _buildSidebarItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      isExpanded: _isSidebarExpanded,
                      isSelected: false,
                      onTap: () => _showLogoutDialog(context),
                    ),
                    if (_isSidebarExpanded)
                      Container(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Deseret Hospital\nCaring for Your Health',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF9FAFC),
                  child: Stack(
                    children: [
                      // Minimalistic pattern overlay
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: const AssetImage('images/hospital.jpg'),
                            fit: BoxFit.cover,
                            opacity: 0.05,
                            onError: (exception, stackTrace) {
                              print('Pattern image failed to load: $exception');
                            },
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isMobile && !_isSidebarExpanded)
                                  IconButton(
                                    icon: const Icon(Icons.menu, color: const Color(0xFF455A64)),
                                    onPressed: () {
                                      setState(() => _isSidebarExpanded = true);
                                    },
                                  ),
                                if (isMobile && !_isSidebarExpanded) const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _adminName,
                                      style: GoogleFonts.roboto(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF4DB6AC),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4DB6AC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Administrator',
                                        style: GoogleFonts.roboto(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                if (isMobile && _isSidebarExpanded)
                                  IconButton(
                                    icon: const Icon(Icons.close, color: const Color(0xFF4DB6AC)),
                                    onPressed: () {
                                      setState(() => _isSidebarExpanded = false);
                                    },
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: FadeTransition(
                                key: ValueKey(_selectedIndex),
                                opacity: _fadeAnimation,
                                child: _getCurrentScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required bool isExpanded,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withOpacity(0.1),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isExpanded ? 12 : 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [const Color(0xFF455A64).withOpacity(0.6), Colors.white.withOpacity(0.4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF4DB6AC) : Colors.white,
                  size: 22,
                ),
                if (isExpanded) const SizedBox(width: 12),
                if (isExpanded)
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: isSelected ? const Color(0xFF4DB6AC) : Colors.white,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: const Color(0xFFF9FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF808000).withOpacity(0.1), const Color(0xFF4DB6AC).withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard Overview',
                  style: GoogleFonts.roboto(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF455A64),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome to your admin dashboard',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: const Color(0xFF78909C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _fetchDashboardData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF4DB6AC)));
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Error loading data: ${snapshot.error}',
                        style: GoogleFonts.roboto(color: const Color(0xFFE53E3E)),
                      ),
                    ),
                  );
                }
                final data = snapshot.data!;
                final lastLogin = (data['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: GridView.count(
                        crossAxisCount: MediaQuery.of(context).size.width > 1200
                            ? 4
                            : MediaQuery.of(context).size.width > 800
                                ? 3
                                : 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.3,
                        children: [
                          _buildStatCard(
                            'Total Users',
                            data['users']?.toString() ?? '0',
                            Icons.people,
                            const Color(0xFF4DB6AC),
                          ),
                          _buildStatCard(
                            'Appointments Today',
                            data['appointments']?.toString() ?? '0',
                            Icons.calendar_today,
                            const Color(0xFF808000),
                          ),
                          _buildStatCard(
                            'Active Staff',
                            data['staff']?.toString() ?? '0',
                            Icons.medical_services,
                            const Color(0xFF455A64),
                          ),
                          // _buildStatCard(
                          //   'Pending Messages',
                          //   data['messages']?.toString() ?? '0',
                          //   Icons.message,
                          //   const Color(0xFF607D8B),
                          // ),
                          _buildStatCard(
                            'Patient Records',
                            data['records']?.toString() ?? '0',
                            Icons.folder,
                            const Color(0xFF66BB6A),
                          ),
                          // _buildStatCard(
                          //   'Notifications Sent',
                          //   data['notifications']?.toString() ?? '0',
                          //   Icons.notifications,
                          //   const Color(0xFFEF6C00),
                          // ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16, right: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Last Login: ${lastLogin.toLocal().toString().split('.')[0]}',
                          style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF78909C)),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    final presenceSnapshot = await FirebaseFirestore.instance.collection('presence').doc(userId).get();

    final userData = userSnapshot.data() as Map<String, dynamic>? ?? {};
    final presenceData = presenceSnapshot.data() as Map<String, dynamic>? ?? {};

    return {
      'name': userData['name'] ?? 'Admin',
      'lastLogin': presenceData['lastSeen'],
      'users': 150,
      'appointments': 23,
      'staff': 45,
      // 'messages': 8,
      'records': 1234,
      // 'notifications': 67,
    };
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF78909C),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 24,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      color: const Color(0xFFF9FAFC),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 80,
                color: const Color(0xFF4DB6AC),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF455A64),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This screen is under development',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: const Color(0xFF78909C),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title feature coming soon!'),
                      backgroundColor: const Color(0xFF4DB6AC),
                    ),
                  );
                },
                icon: const Icon(Icons.build, color: Colors.white),
                label: const Text('Learn More', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4DB6AC),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}