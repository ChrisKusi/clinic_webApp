import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/auth_gate.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/nurse/nurse_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDWj0DM8fBB00c5FvuTLCvDDiIQbRhnDOU",
      authDomain: "pentecost-clinic.firebaseapp.com",
      projectId: "pentecost-clinic",
      storageBucket: "pentecost-clinic.firebasestorage.app",
      messagingSenderId: "272709137362",
      appId: "1:272709137362:web:93b6bc3f76e5191827ce0b",
    ),
  );
  runApp(const ClinicWebDashboard());
}

class ClinicWebDashboard extends StatelessWidget {
  const ClinicWebDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pentecost University Clinic Dashboard',
      theme: ThemeData(
        primaryColor: const Color(0xFF808000), // Olive green
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF808000),
          primary: const Color(0xFF808000),
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const LoginScreen();
        }
        return FutureBuilder<String>(
          future: _getUserRole(snapshot.data!.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (userDoc.data() as Map<String, dynamic>?)?['role'] ?? 'nurse';
  }
}