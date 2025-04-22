import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:clinic_web_dashboard/screens/auth/login_screen.dart';
import 'package:clinic_web_dashboard/screens/admin/admin_dashboard.dart';
import 'package:clinic_web_dashboard/screens/nurse/nurse_dashboard.dart';

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
              color: Color(0xFF808000), // Olive green
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
              return const Center(
                child: Text(
                  'Error loading user role. Please try again.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }
            final role = roleSnapshot.data ?? 'nurse';
            if (role == 'admin') {
              return const AdminDashboard();
            } else {
              return const NurseDashboard();
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
      return (userDoc.data() as Map<String, dynamic>?)?['role'] ?? 'nurse';
    } catch (e) {
      throw Exception('Failed to fetch user role: $e');
    }
  }
}