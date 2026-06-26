import 'package:clinic_web_dashboard/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  String _role = 'doctor';
  String? _specialization;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _specializations = [
    'Cardiology', 'Dermatology','General Medicine', 'Neurology','Orthopedics', 'Pediatrics', 
    
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutExpo,
    ));
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutExpo,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {

// Save current admin credentials before registration (you must prompt for this securely)
        final currentAdminEmail = 'admin@deseret.com'; // Replace with actual admin email
        final currentAdminPassword = 'Admin1234'; // Replace with actual password

// Register user
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
// Set up user data in Firestore
        if (_role == 'doctor') {
          await FirebaseFirestore.instance
              .collection(Collections.doctors)
              .doc(credential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _role,
            'licenseNumber': _licenseController.text.trim(),
            'specialization': _specialization ?? 'Not specified',
            'createdAt': Timestamp.now(),
            'status': 'active',
          }, SetOptions(merge: true));
        } else if (_role == 'admin') {
          await FirebaseFirestore.instance
              .collection(Collections.users)
              .doc(credential.user!.uid)
              .set({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'role': _role,
            'createdAt': Timestamp.now(),
          }, SetOptions(merge: true));
        }

        // Show success message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User registered successfully!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
// Sign back in as admin
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: currentAdminEmail,
          password: currentAdminPassword,
        );

                // Reset form
        _resetForm();

      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = switch (e.code) {
            'email-already-in-use' => 'This email is already registered.',
            'invalid-email' => 'Please enter a valid email address.',
            'weak-password' => 'Password must be at least 6 characters long.',
            _ => 'Registration failed. Please try again.',
          };
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Unable to save user data. Please check your connection: $e';
        });
      } finally {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _passwordController.clear();
    _licenseController.clear();
    if (mounted) {
      setState(() {
        _role = 'doctor';
        _specialization = null;
        _obscurePassword = true;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppBar(
        title: Text(
          'User Registration',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.primary.withOpacity(0.2), const Color(0xFF4DB6AC).withOpacity(0.2)],
                              ),
                            ),
                            child: Icon(
                              Icons.person_add_rounded,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: Text(
                            'Create New Account',
                            style: GoogleFonts.inter(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'Please fill in the required information to register a new user.',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              color: const Color(0xFF666666),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'Personal Information',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter complete name',
                          validator: (value) => value!.isEmpty ? 'Full name is required' : null,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: _emailController,
                          label: 'Email Address',
                          hint: 'Enter valid email address',
                          validator: (value) {
                            if (value!.isEmpty) return 'Email address is required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          },
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter phone number with country code',
                          validator: (value) {
                            if (value!.isEmpty) return 'Phone number is required';
                            if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                              return 'Please enter a valid phone number';
                            }
                            return null;
                          },
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 18),

                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Minimum 6 characters',
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value!.isEmpty) return 'Password is required';
                            if (value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                          icon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: AppColors.primary,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        const SizedBox(height: 28),

                        Text(
                          'Professional Information',
                          style: GoogleFonts.inter(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCDCDC)),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _role,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              labelStyle: GoogleFonts.inter(
                                color: const Color(0xFF666666),
                                fontSize: 15,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(14),
                              prefixIcon: Icon(
                                Icons.work_outline_rounded,
                                color: AppColors.primary,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'doctor', child: Text('Doctor')),
                              DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _role = value!;
                                _licenseController.clear();
                                _specialization = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 18),

                        if (_role == 'doctor') ...[
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDCDCDC)),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _specialization,
                              decoration: InputDecoration(
                                labelText: 'Specialization',
                                hintText: 'Select medical specialization',
                                labelStyle: GoogleFonts.inter(
                                  color: const Color(0xFF666666),
                                  fontSize: 15,
                                ),
                                hintStyle: GoogleFonts.inter(
                                  color: const Color(0xFFBBBBBB),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.all(14),
                                prefixIcon: Icon(
                                  Icons.medical_services_outlined,
                                  color: AppColors.primary,
                                ),
                              ),
                              validator: (value) => _role == 'doctor' && value == null ? 'Please select a specialization' : null,
                              items: _specializations.map((specialization) {
                                return DropdownMenuItem<String>(
                                  value: specialization,
                                  child: Text(
                                    specialization,
                                    style: GoogleFonts.inter(fontSize: 15),
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) => setState(() => _specialization = value),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        _buildTextField(
                          controller: _licenseController,
                          label: 'License Number',
                          hint: _role == 'admin' ? 'Not required for administrators' : 'Enter professional license number',
                          validator: (value) {
                            if (_role != 'admin' && value!.isEmpty) return 'License number is required';
                            if (_role != 'admin' && !RegExp(r'^[A-Za-z0-9]{6,}$').hasMatch(value!)) {
                              return 'License must be at least 6 alphanumeric characters';
                            }
                            return null;
                          },
                          icon: Icons.card_membership_outlined,
                          enabled: _role != 'admin',
                        ),
                        const SizedBox(height: 28),

                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.red[800],
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: GoogleFonts.inter(
                                      color: Colors.red[800],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 3,
                              disabledBackgroundColor: const Color(0xFFD3D3D3),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    'Create Account',
                                    style: GoogleFonts.inter(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required String? Function(String?) validator,
    required IconData icon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? const Color(0xFFDCDCDC) : const Color(0xFFD3D3D3),
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: GoogleFonts.inter(
            color: const Color(0xFF666666),
            fontSize: 15,
          ),
          hintStyle: GoogleFonts.inter(
            color: const Color(0xFFBBBBBB),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
          prefixIcon: Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
        obscureText: obscureText,
        keyboardType: keyboardType,
        enabled: enabled,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
        ),
      ),
    );
  }
}