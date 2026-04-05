import 'package:flutter/material.dart';

class AppColors {

  // ================== 🎯 BASE ==================
  static const Color background = Color(0xFF0D0D0D);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  /// 🔥 NEW (light mode ready)
  static const Color backgroundLight = Color(0xFFF8F8F8);

  // ================== 👑 GOLD ==================
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color goldDark = Color(0xFFB8962E);

  // ================== 🌫 GREY ==================
  static const Color grey = Color(0xFF888888);
  static const Color lightGrey = Color(0xFFCCCCCC);
  static const Color darkGrey = Color(0xFF1A1A1A);

  /// 🔥 NEW
  static const Color border = Color(0x33FFFFFF);

  // ================== 🚦 STATUS COLORS ==================
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;

  /// 🔥 NEW
  static const Color info = Colors.blue;
  static const Color disabled = Colors.grey;

  // ================== 🎴 CARD ==================
  static const Color card = Color(0xFF1E1E1E);

  /// 🔥 NEW
  static const Color cardSoft = Color(0xFF2A2A2A);

  // ================== 🌈 GRADIENTS ==================
  static const LinearGradient goldGradient = LinearGradient(
    colors: [gold, goldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [
      Color(0xFF0D0D0D),
      Color(0xFF1A1A1A),
      Color(0xFF000000),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient cardGradient = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.06),
      Colors.white.withValues(alpha: 0.015),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ================== ✨ SHADOWS ==================
  static List<BoxShadow> goldShadow = [
    BoxShadow(
      color: gold.withValues(alpha: 0.25),
      blurRadius: 20,
      spreadRadius: 1,
    )
  ];

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.5),
      blurRadius: 15,
      offset: const Offset(0, 5),
    )
  ];

  /// 🔥 NEW
  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 8,
      offset: const Offset(0, 3),
    )
  ];

  // ================== 🧊 GLASS ==================
  static BoxDecoration glassDecoration = BoxDecoration(
    color: Colors.white.withValues(alpha: 0.05),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
  );

  // ================== 🎴 CARD STYLE ==================
  static BoxDecoration premiumCard = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
    gradient: cardGradient,
    border: Border.all(color: gold.withValues(alpha: 0.25)),
    boxShadow: goldShadow,
  );

  /// 🔥 NEW
  static BoxDecoration softCard = BoxDecoration(
    color: cardSoft,
    borderRadius: BorderRadius.circular(18),
    boxShadow: softShadow,
  );

  static BoxDecoration outlinedCard = BoxDecoration(
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: border),
  );

  // ================== ⚡ BUTTONS ==================
  static ButtonStyle goldButton = ElevatedButton.styleFrom(
    backgroundColor: gold,
    foregroundColor: Colors.black,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 5,
  );

  static ButtonStyle darkButton = ElevatedButton.styleFrom(
    backgroundColor: darkGrey,
    foregroundColor: white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );

  static ButtonStyle successButton = ElevatedButton.styleFrom(
    backgroundColor: success,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );

  /// 🔥 NEW
  static ButtonStyle outlineButton = OutlinedButton.styleFrom(
    foregroundColor: gold,
    side: const BorderSide(color: gold),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
  );

  // ================== 🔥 TEXT STYLES ==================
  static const TextStyle title = TextStyle(
    color: white,
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subtitle = TextStyle(
    color: grey,
    fontSize: 14,
  );

  static const TextStyle goldText = TextStyle(
    color: gold,
    fontWeight: FontWeight.bold,
  );

  /// 🔥 NEW
  static const TextStyle heading = TextStyle(
    color: white,
    fontSize: 22,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle body = TextStyle(
    color: white,
    fontSize: 15,
  );

  static const TextStyle small = TextStyle(
    color: grey,
    fontSize: 12,
  );

  // ================== 📦 INPUT ==================
  static InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: grey),
      filled: true,
      fillColor: black,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),

      /// 🔥 NEW
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: border),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: gold),
      ),
    );
  }

  // ================== 🎬 ANIMATION ==================
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 700);

  /// 🔥 NEW
  static const Duration ultraFast = Duration(milliseconds: 120);

  static const Color pending = Colors.orange;
  static const Color approved = Colors.green;
  static const Color rejected = Colors.red;
}