// ignore_for_file: unused_import
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../constants.dart';
import '../../main.dart';
import '../../service/firebase_firestore_service.dart';
import '../../service/firebase_storage_service.dart';
import '../../service/media_service.dart';
import '../../service/notification_service.dart';

class SignUpWidget extends StatefulWidget {
  final Function() onClickedSignIn;
  const SignUpWidget({
    Key? key,
    required this.onClickedSignIn,
  }) : super(key: key);

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool isLoading = false;
  Uint8List? file;
  static final notifications = NotificationsService();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  final List<String> _steps = ['Profile Picture', 'Personal Info', 'Security'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.normalDuration,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade800,
            Colors.indigo.shade900,
          ],
          stops: const [0.2, 0.8],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: widget.onClickedSignIn,
          ),
          title: Row(
            children: List.generate(
              _steps.length,
              (index) => Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 3,
                  decoration: BoxDecoration(
                    color: index <= _currentStep
                        ? Colors.white
                        : Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          actions: [
            AnimatedSwitcher(
              duration: AppTheme.quickDuration,
              child: _currentStep == _steps.length - 1
                  ? Container(
                      height: 36,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.arrow_forward, color: Colors.white),
                      onPressed: () {
                        if (_validateCurrentStep()) {
                          setState(() => _currentStep++);
                        }
                      },
                    ),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Step Title
                        Text(
                          _steps[_currentStep],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Step Description
                        Text(
                          _getStepDescription(_currentStep),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Main Content with Animation
                        AnimatedSwitcher(
                          duration: AppTheme.normalDuration,
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.1, 0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
                          child: _buildCurrentStep(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Bottom Navigation
              if (_currentStep > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.arrow_back, color: Colors.white70),
                        SizedBox(width: 8),
                        Text(
                          'Previous Step',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_currentStep == _steps.length - 1) ...[
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AnimatedContainer(
                    duration: AppTheme.quickDuration,
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: !isLoading ? signUp : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                        shadowColor: Colors.blue.withOpacity(0.5),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline, size: 24),
                                SizedBox(width: 8),
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildProfilePictureStep();
      case 1:
        return _buildPersonalInfoStep();
      case 2:
        return _buildSecurityStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildProfilePictureStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Hero(
            tag: 'profile_picture',
            child: GestureDetector(
              onTap: () async {
                final pickedImage = await MediaService.pickImage();
                setState(() => file = pickedImage);
              },
              child: AnimatedContainer(
                duration: AppTheme.quickDuration,
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  border: Border.all(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    width: 3,
                  ),
                  image: file != null
                      ? DecorationImage(
                          image: MemoryImage(file!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: file == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add Photo',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: AppTheme.inputDecoration(
              label: 'Full Name',
              hint: 'John Doe',
              prefixIcon: Icons.person_outline,
            ),
            validator: (value) =>
                value != null && value.isEmpty ? 'Enter your name' : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: emailController,
            decoration: AppTheme.inputDecoration(
              label: 'Email',
              hint: 'name@example.com',
              prefixIcon: Icons.email_outlined,
            ),
            validator: (email) =>
                email != null && !EmailValidator.validate(email)
                    ? 'Enter a valid email'
                    : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityStep() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            spreadRadius: 5,
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          TextFormField(
            controller: passwordController,
            obscureText: !_isPasswordVisible,
            decoration: AppTheme.inputDecoration(
              label: 'Password',
              hint: '••••••',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
            ),
            validator: (value) =>
                value != null && value.length < 6
                    ? 'Enter min. 6 characters'
                    : null,
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: !_isConfirmPasswordVisible,
            decoration: AppTheme.inputDecoration(
              label: 'Confirm Password',
              hint: '••••••',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _isConfirmPasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => setState(
                    () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
            ),
            validator: (value) =>
                value != passwordController.text
                    ? 'Passwords do not match'
                    : null,
          ),
        ],
      ),
    );
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (file == null) {
          _showError('Please select a profile picture');
          return false;
        }
        return true;
      case 1:
        if (nameController.text.trim().isEmpty) {
          _showError('Please enter your name');
          return false;
        }
        if (!EmailValidator.validate(emailController.text.trim())) {
          _showError('Please enter a valid email');
          return false;
        }
        return true;
      case 2:
        if (passwordController.text.length < 6) {
          _showError('Password must be at least 6 characters');
          return false;
        }
        if (passwordController.text != confirmPasswordController.text) {
          _showError('Passwords do not match');
          return false;
        }
        return true;
      default:
        return false;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> signUp() async {
    if (!_validateCurrentStep()) return;

    try {
      setState(() => isLoading = true);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Print debug info
      print('Creating user with:');
      print('Name: ${nameController.text.trim()}');
      print('Email: ${emailController.text.trim()}');

      // Create user in Firebase Auth
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Upload profile picture
      final image = await FirebaseStorageService.uploadImage(
        file!,
        'image/profile/${userCredential.user!.uid}',
      );

      // Create user document in Firestore
      await FirebaseFirestoreService.createUser(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        uid: userCredential.user!.uid,
        image: image,
      );

      print('User created successfully with name: ${nameController.text.trim()}');

      // Setup notifications
      await notifications.requestPermission();
      await notifications.getToken();

      if (!mounted) return;
      Navigator.of(context).pop(); // Pop loading dialog
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Pop loading dialog
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getStepDescription(int step) {
    switch (step) {
      case 0:
        return 'Add a profile picture to personalize your account';
      case 1:
        return 'Tell us a bit about yourself';
      case 2:
        return 'Create a secure password to protect your account';
      default:
        return '';
    }
  }
}
