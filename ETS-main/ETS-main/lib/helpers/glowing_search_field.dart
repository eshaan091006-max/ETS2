import 'package:flutter/material.dart';
import 'package:malhar_ets/constants/app_colors.dart';

class GlowingSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const GlowingSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
    super.key,
  });

  @override
  State<GlowingSearchField> createState() => _GlowingSearchFieldState();
}

class _GlowingSearchFieldState extends State<GlowingSearchField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _hasFocus = hasFocus;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: _hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 12,
                    spreadRadius: 1.5,
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          style: const TextStyle(color: AppColors.textWhite),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: AppColors.primary),
                    onPressed: () {
                      widget.onClear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.secondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}
