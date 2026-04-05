// 🔥 FINAL PRO CUSTOM TEXTFIELD (ULTIMATE SAFE + BACKWARD COMPATIBLE)

import 'package:flutter/material.dart';
import '../core/colors.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;

  final Function(String)? onChanged;
  final String? Function(String?)? validator;

  /// 🔥 UI
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;

  /// 🔥 UX
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final Iterable<String>? autofillHints;

  /// 🔥 BACKWARD SUPPORT (مهم)
  final VoidCallback? onSubmitted;

  /// 🔥 NEW PRO
  final bool readOnly;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;

  const CustomTextField({
    super.key,
    required this.hint,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,

    /// UX
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,

    /// 🔥 BACKWARD
    this.onSubmitted,

    /// NEW
    this.readOnly = false,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.05),
            blurRadius: 12,
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        enabled: enabled,
        readOnly: readOnly,
        onTap: onTap,

        /// 🔥 FIX
        maxLines: isPassword ? 1 : maxLines,

        focusNode: focusNode,
        textInputAction: textInputAction,

        /// 🔥 الحل النهائي هنا
        onFieldSubmitted: (value) {
          if (onFieldSubmitted != null) {
            onFieldSubmitted!(value);
          }
          if (onSubmitted != null) {
            onSubmitted!();
          }

          /// 🔥 Auto next focus
          if (textInputAction == TextInputAction.next) {
            FocusScope.of(context).nextFocus();
          } else {
            FocusScope.of(context).unfocus();
          }
        },

        autofillHints: autofillHints,
        textCapitalization: textCapitalization,

        style: const TextStyle(color: Colors.white),
        cursorColor: AppColors.gold,
        cursorHeight: 20,

        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),

          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,

          filled: true,
          fillColor: AppColors.black,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 16,
          ),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
            ),
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColors.gold,
              width: 1.5,
            ),
          ),

          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red),
          ),

          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }
}