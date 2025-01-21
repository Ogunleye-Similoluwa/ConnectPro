import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> with SingleTickerProviderStateMixin {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  bool isLoading = false;
  bool emailSent = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: AppTheme.normalDuration,
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.gradientColors,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.cardDecoration,
                      child: Form(
                        key: formKey,
                        child: Column(
                          children: [
                            // Animated Icon
                            TweenAnimationBuilder<double>(
                              duration: AppTheme.slowDuration,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle: value * 2 * 3.14,
                                  child: child,
                                );
                              },
                              child: Icon(
                                emailSent ? Icons.check_circle : Icons.lock_reset,
                                size: 80,
                                color: emailSent ? Colors.green : AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Title with Animation
                            AnimatedSwitcher(
                              duration: AppTheme.normalDuration,
                              child: Text(
                                emailSent ? 'Email Sent!' : 'Reset Password',
                                key: ValueKey<bool>(emailSent),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Subtitle with Animation
                            AnimatedSwitcher(
                              duration: AppTheme.normalDuration,
                              child: Text(
                                emailSent
                                    ? 'Please check your email for reset instructions'
                                    : 'Enter your email to receive a password reset link',
                                key: ValueKey<bool>(emailSent),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            
                            // Email Input Field
                            if (!emailSent)
                              TextFormField(
                                controller: emailController,
                                enabled: !isLoading,
                                decoration: AppTheme.inputDecoration(
                                  label: 'Email',
                                  hint: 'name@example.com',
                                  prefixIcon: Icons.email_outlined,
                                ),
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (email) =>
                                    email != null && !EmailValidator.validate(email)
                                        ? 'Enter a valid email'
                                        : null,
                              ),
                            const SizedBox(height: 30),
                            
                            // Submit Button with Loading Animation
                            AnimatedContainer(
                              duration: AppTheme.quickDuration,
                              height: 50,
                              width: isLoading ? 50 : double.infinity,
                              child: isLoading
                                  ? const CircularProgressIndicator()
                                  : ElevatedButton.icon(
                                      style: AppTheme.elevatedButtonStyle,
                                      icon: const Icon(Icons.email_outlined),
                                      label: Text(
                                        emailSent ? 'Send Again' : 'Send Reset Link',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      onPressed: verifyEmail,
                                    ),
                            ),
                          ],
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
    );
  }

  Future<void> verifyEmail() async {
    if (!formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      setState(() {
        isLoading = false;
        emailSent = true;
      });

      // Show success animation
      _animationController.reset();
      _animationController.forward();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password Reset Email Sent'),
          backgroundColor: Colors.green,
        ),
      );

      // Auto navigate back after delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
