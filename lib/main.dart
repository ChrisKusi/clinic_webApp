import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:clinic_web_dashboard/screens/auth/auth_gate.dart';
import 'package:clinic_web_dashboard/screens/auth/login_screen.dart';
import 'package:clinic_web_dashboard/screens/auth/forgot_password_screen.dart';
import 'package:clinic_web_dashboard/screens/admin/admin_dashboard.dart';
import 'package:clinic_web_dashboard/screens/doctor/doctor_dashboard.dart';
import 'package:clinic_web_dashboard/screens/admin/register_user_screen.dart';
import 'package:clinic_web_dashboard/screens/admin/appointments_screen.dart';
import 'package:clinic_web_dashboard/screens/admin/patient_records_screen.dart';
import 'package:clinic_web_dashboard/screens/admin/admin_profile_screen.dart';
import 'package:clinic_web_dashboard/screens/doctor/doctor_profile_screen.dart';
import 'package:clinic_web_dashboard/screens/doctor/doctor_appointment_screen.dart';
import 'package:clinic_web_dashboard/screens/doctor/doctor_PatientRecords_screen.dart';
import 'package:clinic_web_dashboard/screens/user_list_screen.dart';
import 'dart:ui' show ChannelBuffers;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ChannelBuffers().setListener('flutter/lifecycle', (message, reply) {
    print('Lifecycle message received: $message');
  });
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyDWj0DM8fBB00c5FvuTLCvDDiIQbRhnDOU",
      authDomain: "pentecost-clinic.firebaseapp.com",
      databaseURL: "https://pentecost-clinic-default-rtdb.firebaseio.com",
      projectId: "pentecost-clinic",
      storageBucket: "pentecost-clinic.firebasestorage.app",
      messagingSenderId: "272709137362",
      appId: "1:272709137362:web:93b6bc3f76e5191827ce0b",
    ),
  );
  print('Firebase initialized: ${Firebase.app().name}');
  runApp(const ClinicWebDashboard());
}

class ClinicWebDashboard extends StatelessWidget {
  const ClinicWebDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deseret Hospital Dashboard',
      theme: ThemeData(
        primaryColor: const Color(0xFF808000),
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
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/doctor': (context) => const DoctorDashboard(),
        '/register': (context) => const RegisterUserScreen(),
        '/appointments': (context) => const AppointmentsScreen(),
        '/patient-records': (context) => const PatientRecordsScreen(),
        '/admin-profile': (context) => const AdminProfileScreen(),
        '/doctor-profile': (context) => const DoctorProfileScreen(),
        '/doctor-appointments': (context) => const DoctorAppointmentScreen(),
        '/doctor-patient-records': (context) => const DoctorPatientRecordsScreen(),
        '/user-list': (context) => const UserListScreen(),
        '/forgotPassword': (context) => const ForgotPasswordScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const UnknownRouteScreen(),
        );
      },
    );
  }
}

class UnknownRouteScreen extends StatelessWidget {
  const UnknownRouteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: const Color(0xFF808000),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Color(0xFF808000)),
            const SizedBox(height: 16),
            const Text(
              'Page Not Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF808000),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'The page you are looking for does not exist.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF808000),
                foregroundColor: Colors.white,
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}