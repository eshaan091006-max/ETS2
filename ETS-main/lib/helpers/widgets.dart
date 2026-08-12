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

/// Pill showing how many entries already exist for a contingent+event pair.
///
/// Selecting such a row in an add-sheet appends a further entry rather than
/// replacing anything, so the count tells the admin what they are adding to.
Widget buildEntryCountBadge(int count) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.accent.withAlpha(38),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.accent.withAlpha(128)),
    ),
    child: Text(
      count == 1 ? '1 entry' : '$count entries',
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
    ),
  );
}

/// Label telling a contingent's repeat entries in one event apart.
///
/// [entryNumber] of 0 means this is the only entry, which renders nothing.
Widget buildEntryChip(int entryNumber) {
  if (entryNumber == 0) return const SizedBox.shrink();
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.primary.withAlpha(38),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.primary.withAlpha(128)),
    ),
    child: Text(
      'Entry $entryNumber',
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    ),
  );
}
