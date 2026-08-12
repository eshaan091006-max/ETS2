import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/neon_container.dart';
import 'package:malhar_ets/shared/models/department.dart';

class DepartmentCard extends StatelessWidget {
  final Department d;
  final bool isFocused;
  const DepartmentCard({required this.d, this.isFocused = true, super.key});

  @override
  Widget build(BuildContext context) {
    if (!isFocused) {
      return NeonContainer(
        borderRadius: 16.0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Hero(
                  tag: 'dept-name-small-${d.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        d.name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
              ),
              const SizedBox(width: 8),
              Text(
                d.code,
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Full layout for focused state
    return LayoutBuilder(
      builder: (context, constraints) {
        double maxWidth = constraints.maxWidth;
        double maxHeight = constraints.maxHeight;
        double baseSize = maxWidth < maxHeight ? maxWidth : maxHeight;
        double titleFontSize = baseSize * 0.08;
        double codeFontSize = baseSize * 0.22;

        return NeonContainer(
          borderRadius: 35.0,
          padding: const EdgeInsets.all(20),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
            child: SizedBox(
              width: maxWidth - 40, // 20 padding on each side
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'dept-name-${d.id}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        d.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: titleFontSize.clamp(16.0, 32.0),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  d.code,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzel(
                    fontSize: codeFontSize.clamp(32.0, 96.0),
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                ],
              ),
            ),
          ),
          ),
        );
      },
    );
  }
}
