import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = true;
  bool _showPasswordChange = false;
  bool _showCurrentPassword = true;
  bool _showNewPassword = true;
  bool _showConfirmPassword = true;
  String? _originalName;
  String? _originalEmail;

  // Professional color scheme
  final Color primaryColor = const Color(0xFF808000); // Olive green
  final Color accentColor = const Color(0xFF4CAF50);
  final Color backgroundColor = const Color(0xFFF8F9FA);
  final Color cardColor = Colors.white;
  final Color textPrimary = const Color(0xFF212121);
  final Color textSecondary = const Color(0xFF757575);

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchUserData();
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
    _slideAnimation = Tween<Offset>(
            begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          _nameController.text = data['name'] ?? '';
          _emailController.text = data['email'] ?? '';
          _originalName = data['name'] ?? '';
          _originalEmail = data['email'] ?? '';
        }
      }
    } catch (e) {
      _showSnackBar('Unable to load profile. Please check your connection and try again.', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'name': _nameController.text.trim(),
            'email': _emailController.text.trim(),
          });
          _originalName = _nameController.text.trim();
          _originalEmail = _emailController.text.trim();
          _showSnackBar('Profile updated successfully!');
        }
      } catch (e) {
        _showSnackBar('Failed to update profile. Please try again later.', isError: true);
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _changePassword() async {
    // Client-side validation
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Please fill in all password fields.', isError: true);
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar('New password and confirmation do not match.', isError: true);
      return;
    }
    if (_newPasswordController.text.length < 8) {
      _showSnackBar('New password must be at least 8 characters long.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Validate current password
        final credential = EmailAuthProvider.credential(
            email: user.email!, password: _currentPasswordController.text);
        try {
          await user.reauthenticateWithCredential(credential);
        } on FirebaseAuthException catch (e) {
          print('Reauthentication error: ${e.code} - ${e.message}'); // Debug log
          if (e.code == 'wrong-password' || e.code == 'invalid-credential' || e.code == 'user-mismatch') {
            _showSnackBar('Current password is incorrect.', isError: true);
            setState(() => _isSaving = false);
            return;
          } else if (e.code == 'user-not-found' || e.code == 'invalid-email') {
            _showSnackBar('Authentication error. Please sign out and sign in again.', isError: true);
            setState(() => _isSaving = false);
            return;
          } else if (e.code == 'too-many-requests') {
            _showSnackBar('Too many attempts. Please try again later.', isError: true);
            setState(() => _isSaving = false);
            return;
          }
          throw e; // Rethrow unexpected Firebase errors
        }

        // Update password if reauthentication succeeds
        try {
          await user.updatePassword(_newPasswordController.text);
          _showSnackBar('Password updated successfully!');
          setState(() => _showPasswordChange = false);
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
        } on FirebaseAuthException catch (e) {
          String errorMessage;
          switch (e.code) {
            case 'weak-password':
              errorMessage = 'New password is too weak. Please use a stronger password.';
              break;
            case 'too-many-requests':
              errorMessage = 'Too many attempts. Please try again later.';
              break;
            default:
              errorMessage = 'Failed to update password. Please try again.';
          }
          _showSnackBar(errorMessage, isError: true);
        }
      } else {
        _showSnackBar('No user is signed in. Please sign in again.', isError: true);
      }
    } catch (e) {
      print('Unexpected error: $e'); // Debug log
      _showSnackBar('An unexpected error occurred. Please check your connection and try again.', isError: true);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _nameController.text = _originalName ?? '';
      _emailController.text = _originalEmail ?? '';
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red[600] : Colors.green[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                colors: [primaryColor, accentColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.admin_panel_settings,
              color: Colors.white, size: 28),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Profile',
                style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your account settings',
                style:
                    GoogleFonts.inter(fontSize: 14, color: textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    bool showToggle = false,
    int maxLines = 1,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.w500),
          hintText: hint,
          hintStyle: GoogleFonts.inter(
              color: textSecondary.withOpacity(0.7), fontSize: 14),
          prefixIcon: Container(
            padding: const EdgeInsets.all(14),
            child: Icon(icon, color: primaryColor, size: 22),
          ),
          suffixIcon: showToggle
              ? IconButton(
                  icon: Icon(
                      obscureText
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: primaryColor,
                      size: 22),
                  onPressed: onToggleVisibility,
                )
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
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        style: GoogleFonts.inter(color: textPrimary, fontSize: 16),
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
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.save_rounded, size: 20),
              label: Text(
                _isSaving ? 'Saving...' : 'Save Changes',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
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
              onPressed: _resetForm,
              icon: const Icon(Icons.cancel_rounded, size: 20),
              label: Text(
                'Cancel',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
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

  Widget _buildPasswordChangeSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: _showPasswordChange ? 400 : 0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              controller: _currentPasswordController,
              label: 'Current Password',
              icon: Icons.lock_outline,
              obscureText: _showCurrentPassword,
              showToggle: true,
              onToggleVisibility: () =>
                  setState(() => _showCurrentPassword = !_showCurrentPassword),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter your current password' : null,
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              controller: _newPasswordController,
              label: 'New Password',
              icon: Icons.lock,
              obscureText: _showNewPassword,
              showToggle: true,
              onToggleVisibility: () =>
                  setState(() => _showNewPassword = !_showNewPassword),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter a new password';
                if (value.length < 8) return 'Password must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildAnimatedFormField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              icon: Icons.lock,
              obscureText: _showConfirmPassword,
              showToggle: true,
              onToggleVisibility: () =>
                  setState(() => _showConfirmPassword = !_showConfirmPassword),
              validator: (value) {
                if (value!.isEmpty) return 'Please confirm your new password';
                if (value != _newPasswordController.text) return 'Passwords do not match';
                return null;
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _changePassword,
              icon: _isSaving
                  ? SizedBox(
                      width: 20,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : Icon(Icons.update_rounded, size: 20),
              label: Text(
                _isSaving ? 'Updating...' : 'Update Password',
                style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Admin Profile',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                  const SizedBox(height: 16),
                  Text('Loading profile...',
                      style: GoogleFonts.inter(
                          color: textSecondary, fontSize: 16)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Align(
                alignment: Alignment.topCenter,
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildProfileHeader(),
                                const SizedBox(height: 32),
                                Divider(color: Colors.grey[300], height: 1),
                                const SizedBox(height: 28),
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _buildAnimatedFormField(
                                        controller: _nameController,
                                        label: 'Name',
                                        icon: Icons.person_outline,
                                        validator: (value) {
                                          if (value?.isEmpty ?? true) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      _buildAnimatedFormField(
                                        controller: _emailController,
                                        label: 'Email Address',
                                        icon: Icons.email_outlined,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!value.contains('@')) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 32),
                                      _buildAnimatedActionButtons(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: () => setState(() => _showPasswordChange = !_showPasswordChange),
                                  child: Text(
                                    _showPasswordChange
                                        ? 'Hide Password Change'
                                        : 'Change Password',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 50),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                                _buildPasswordChangeSection(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}