import 'dart:async';

import 'package:firebase_chat_app/view/screens/chats_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../constants.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({Key? key}) : super(key: key);

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> with SingleTickerProviderStateMixin {
  bool isEmailVerified = false;
  bool canResendEmail = false;
  Timer? timer;
  int timeLeft = 30; // Countdown timer for resend
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

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
    _animationController.forward();

    isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;

    if (!isEmailVerified) {
      sendVerificationEmail();
      
      // Check email verification status every 3 seconds
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => checkEmailVerified(),
      );

      // Countdown timer for resend button
      Timer.periodic(
        const Duration(seconds: 1),
        (Timer t) {
          if (mounted) {
            setState(() {
              if (timeLeft > 0) {
                timeLeft--;
              } else {
                canResendEmail = true;
                t.cancel();
              }
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkEmailVerified() async {
    try {
      // Reload user data
      await FirebaseAuth.instance.currentUser!.reload();

      setState(() {
        isEmailVerified = FirebaseAuth.instance.currentUser!.emailVerified;
      });

      if (isEmailVerified) {
        timer?.cancel();
        // Navigate to chat screen
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ChatsScreen()),
        );
      }
    } catch (e) {
      print('Error checking email verification: $e');
    }
  }

  Future<void> sendVerificationEmail() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();

      setState(() {
        canResendEmail = false;
        timeLeft = 30;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => isEmailVerified
      ? const ChatsScreen()
      : Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: AppTheme.gradientColors,
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: AppTheme.cardDecoration,
                        child: Column(
                          children: [
                            TweenAnimationBuilder<double>(
                              duration: AppTheme.slowDuration,
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.scale(
                                  scale: value,
                                  child: child,
                                );
                              },
                              child: const Icon(
                                Icons.mark_email_unread_outlined,
                                size: 80,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Verify your Email',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'We\'ve sent a verification email to\n${FirebaseAuth.instance.currentUser?.email}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 30),
                            AnimatedContainer(
                              duration: AppTheme.quickDuration,
                              transform: Matrix4.identity()
                                ..scale(canResendEmail ? 1.0 : 0.95),
                              child: ElevatedButton.icon(
                                style: AppTheme.elevatedButtonStyle,
                                icon: const Icon(Icons.email, size: 28),
                                label: Text(
                                  canResendEmail
                                      ? 'Resend Email'
                                      : 'Wait ${timeLeft}s',
                                  style: const TextStyle(fontSize: 20),
                                ),
                                onPressed: canResendEmail ? sendVerificationEmail : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text(
                          'Back to Sign In',
                          style: TextStyle(fontSize: 18),
                        ),
                        onPressed: () => FirebaseAuth.instance.signOut(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
}
