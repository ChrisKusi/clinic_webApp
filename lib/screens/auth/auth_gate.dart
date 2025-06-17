import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clinic_web_dashboard/screens/auth/login_screen.dart';
import 'package:clinic_web_dashboard/screens/admin/admin_dashboard.dart';
import 'package:clinic_web_dashboard/screens/doctor/doctor_dashboard.dart';
import 'package:clinic_web_dashboard/services/presence_service.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF808000),
            ),
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
                child: CircularProgressIndicator(
                  color: Color(0xFF808000),
                ),
              );
            }
            if (roleSnapshot.hasError) {
              print('Error loading role: ${roleSnapshot.error}');
              return const Center(
                child: Text(
                  'Error loading user role. Please try again.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            final presenceService = PresenceService();
            presenceService.setupPresence();
            final role = roleSnapshot.data ?? 'admin'; // Default to admin if no role found
            switch (role) {
              case 'admin':
                return const AdminDashboard();
              case 'doctor':
                return const DoctorDashboard();
              default:
                return const LoginScreen(); // No nurse fallback
            }
          },
        );
      },
    );
  }

  Future<String> _getUserRole(String uid) async {
    try {
      // Check users collection first
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (userDoc.exists) {
        return (userDoc.data() as Map<String, dynamic>?)?['role'] ?? 'admin';
      }
      // Check doctors collection if not found in users
      DocumentSnapshot doctorDoc =
          await FirebaseFirestore.instance.collection('doctors').doc(uid).get();
      if (doctorDoc.exists) {
        return (doctorDoc.data() as Map<String, dynamic>?)?['role'] ?? 'doctor';
      }
      return 'admin'; // Default role if no match
    } catch (e) {
      print('Failed to fetch user role: $e');
      throw Exception('Failed to fetch user role: $e');
    }
  }
}