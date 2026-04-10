import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/colors.dart';

class CenterSearchBar extends StatefulWidget {
  final Function(String) onChanged;

  const CenterSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  State<CenterSearchBar> createState() => _CenterSearchBarState();
}

class _CenterSearchBarState extends State<CenterSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool isFocused = false;

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onChanged(value.trim().toLowerCase());
    });

    if (mounted) {
      setState(() {});
    }
  }

  void _clear() {
    _controller.clear();
    widget.onChanged("");

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();

    _focusNode.addListener(() {
      if (mounted) {
        setState(() {
          isFocused = _focusNode.hasFocus;
        });
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isFocused ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFocused
              ? AppColors.gold.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.05),
        ),
        boxShadow: [
          if (isFocused)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 10,
            ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onChanged,
        style: const TextStyle(color: Colors.white),
        cursorColor: AppColors.gold,
        decoration: InputDecoration(
          hintText: "ابحث داخل لوحة التحكم...",
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: AppColors.gold),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: _clear,
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}