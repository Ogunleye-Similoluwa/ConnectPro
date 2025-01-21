import 'package:flutter/material.dart';

// App Theme Colors
class AppTheme {
  // Branding
  static const String appName = 'ConnectPro';
  static const String appTagline = 'Connect. Collaborate. Communicate.';
  
  // Brand Colors (updating the existing colors for a more professional look)
  static const primaryColor = Color(0xFF0A2463);  // Deep Professional Blue
  static const accentColor = Color(0xFF3E92CC);   // Bright Blue
  static const highlightColor = Color(0xFF2196F3); // Interactive Blue
  
  // Updated Gradient Colors
  static final gradientColors = [
    const Color(0xFF0A2463),  // Deep Professional Blue
    const Color(0xFF1E4D8C),  // Medium Professional Blue
    const Color(0xFF3E92CC),  // Light Professional Blue
  ];

  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.95),
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        spreadRadius: 5,
        blurRadius: 15,
        offset: const Offset(0, 5),
      ),
    ],
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: primaryColor),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
    );
  }

  // Button Style
  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    minimumSize: const Size.fromHeight(50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 5,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  );

  // Animation Durations
  static const Duration quickDuration = Duration(milliseconds: 200);
  static const Duration normalDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);

  // Brand Typography
  static const TextStyle headingStyle = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 1.2,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    color: Colors.white70,
    letterSpacing: 0.5,
  );
}

const Color mainColor = Color(0xff703efe);

const String loginScreen = '/login';
const String registerScreen = '/register';
