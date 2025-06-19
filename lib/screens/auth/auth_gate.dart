import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clinic_web_dashboard/screens/auth/login_screen.dart';
import 'package:clinic_web_dashboard/screens/admin/admin_dashboard.dart';
import 'package:clinic_web_dashboard/screens/doctor/doctor_dashboard.dart';
import 'package:clinic_web_dashboard/services/presence_service.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  _AuthGateState createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final PresenceService _presenceService = PresenceService();

  @override
  void initState() {
    super.initState();
    _presenceService.setupPresence(); // Initialize once
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF808000)),
          );
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        return FutureBuilder<String>(
          future: _getUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF808000)),
              );
            }
            if (roleSnapshot.hasError || !roleSnapshot.hasData) {
              print('Error or no role data: ${roleSnapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Error loading user role. Please try again.',
                      style: TextStyle(color: Colors.red),
                    ),
                    TextButton(
                      onPressed: () => setState(() {}), // Retry
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            final role = roleSnapshot.data!;
            switch (role) {
              case 'admin':
                return const AdminDashboard();
              case 'doctor':
                return const DoctorDashboard();
              default:
              // Log out if role is invalid
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
            }
          },
        );
      },
    );
  }

  Future<String> _getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return (userDoc.data() as Map<String, dynamic>?)?['role'] ?? 'unknown';
      }
      DocumentSnapshot doctorDoc =
      await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
      if (doctorDoc.exists) {
        return (doctorDoc.data() as Map<String, dynamic>?)?['role'] ?? 'unknown';
      }
      return 'unknown'; // Explicitly mark as unknown
    } catch (e) {
      print('Failed to fetch user role: $e');
      return 'unknown';
    }
  }
}