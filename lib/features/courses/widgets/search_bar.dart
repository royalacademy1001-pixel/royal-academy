import 'dart:async';
import 'package:flutter/material.dart';
import 'package:royal_academy/core/colors.dart';

class SearchBarWidget extends StatefulWidget {
  final Function(String) onChanged;

  const SearchBarWidget({super.key, required this.onChanged});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  Timer? _debounce;
  bool isFocused = false;

  void _onChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () {
      widget.onChanged(value);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isFocused ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isFocused
                ? AppColors.gold.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.05),
            width: isFocused ? 1.2 : 1,
          ),
          boxShadow: [
            if (isFocused)
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.25),
                blurRadius: 18,
                spreadRadius: 1,
              )
          ],
        ),
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          style: const TextStyle(color: Colors.white),
          cursorColor: AppColors.gold,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: "ابحث عن كورس...",
            hintStyle: TextStyle(
              color: isFocused
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.grey,
            ),
            border: InputBorder.none,
            prefixIcon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.search,
                color: isFocused
                    ? AppColors.gold
                    : Colors.grey,
              ),
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _controller.text.isEmpty ? 0 : 1,
                    child: IconButton(
                      onPressed: _clear,
                      icon: const Icon(Icons.close, color: Colors.grey),
                    ),
                  ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}