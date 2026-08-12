import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';

Widget buildDropdown({
  required String label,
  required String value,
  required List<String> options,
  required void Function(String?) onChanged,
  bool expanded = true,
}) {
  final dropdownWidget = Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.secondary,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        dropdownColor: AppColors.tertiary,
        borderRadius: BorderRadius.circular(12),
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.accent),
        isExpanded: true,
        style: const TextStyle(color: AppColors.textWhite),
        onChanged: onChanged,
        items:
            options.map((option) {
              return DropdownMenuItem(
                value: option,
                child: Text(
                  option == 'All' ? '$label: All' : option,
                  style: GoogleFonts.poppins(color: AppColors.textWhite),
                ),
              );
            }).toList(),
      ),
    ),
  );

  return expanded ? Expanded(child: dropdownWidget) : dropdownWidget;
}
