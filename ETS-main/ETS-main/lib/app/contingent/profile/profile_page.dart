import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/shared/controllers/contingent_controller.dart';
import 'package:malhar_ets/shared/models/contingent.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/utils/hash_util.dart';
import 'package:malhar_ets/helpers/glass_container.dart';
import 'package:malhar_ets/utils/session_manager.dart';

class ProfilePage extends StatefulWidget {
  final Contingent contingent;
  const ProfilePage({super.key, required this.contingent});

  @override
  State<ProfilePage> createState() => _ContingentPageState();
}

class _ContingentPageState extends State<ProfilePage> {
  late String code;
  late String password;

  @override
  void initState() {
    super.initState();
    code = widget.contingent.contingentCode;
    password = widget.contingent.password;
  }

  void _showEditSheet() {
    final TextEditingController codeController = TextEditingController(
      text: code,
    );
    final TextEditingController passwordController = TextEditingController(
      text: '', // Start empty, do not show hashed password
    );

    bool obscurePassword = true;
    bool hasUpper = false;
    bool hasLower = false;
    bool hasDigit = false;
    bool hasSpecial = false;
    bool hasMinLength = false;
    bool isPasswordValid() {
      return hasUpper && hasLower && hasDigit && hasSpecial && hasMinLength;
    }

    void validatePassword(
      String value,
      void Function(void Function()) setModalState,
    ) {
      setModalState(() {
        hasUpper = RegExp(r'[A-Z]').hasMatch(value);
        hasLower = RegExp(r'[a-z]').hasMatch(value);
        hasDigit = RegExp(r'\d').hasMatch(value);
        hasSpecial = RegExp(r'[!@#\$&*~_]').hasMatch(value);
        hasMinLength = value.length >= 8;
      });
    }

    Widget buildRule(String text, bool isValid) {
      return Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isValid ? Colors.greenAccent : Colors.redAccent,
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isValid ? Colors.greenAccent.withAlpha(220) : Colors.redAccent.withAlpha(220),
              fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.secondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            validatePassword(passwordController.text, setModalState);
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header drag bar
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Change Password",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montserrat(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Remaining Resets: ${widget.contingent.resetCount}",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.contingent.resetCount <= 1 ? Colors.redAccent : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// Code (Disabled)
                      TextField(
                        enabled: false,
                        controller: codeController,
                        style: const TextStyle(color: Colors.white70),
                        decoration: InputDecoration(
                          labelText: "Contingent Code",
                          labelStyle: const TextStyle(color: AppColors.textSecondary),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primary.withAlpha(50)),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.fingerprint, color: AppColors.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      /// Password with toggle visibility
                      TextField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        style: const TextStyle(color: AppColors.textWhite),
                        onChanged: (value) => validatePassword(value, setModalState),
                        decoration: InputDecoration(
                          labelText: "New Password",
                          labelStyle: const TextStyle(color: AppColors.primary),
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.textSecondary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: AppColors.primary,
                            ),
                            onPressed: () {
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// Password rules
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(15)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Password Requirements",
                              style: GoogleFonts.montserrat(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            buildRule("Min 8 characters", hasMinLength),
                            const SizedBox(height: 8),
                            buildRule("At least 1 uppercase letter", hasUpper),
                            const SizedBox(height: 8),
                            buildRule("At least 1 lowercase letter", hasLower),
                            const SizedBox(height: 8),
                            buildRule("At least 1 number", hasDigit),
                            const SizedBox(height: 8),
                            buildRule("At least 1 special character (!@#\$&*~_)", hasSpecial),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// Save Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (widget.contingent.resetCount <= 0) {
                            AppFeedback.showError(
                              context,
                              "Password reset limit reached. Please contact Admin.",
                            );
                            return;
                          }
                          if (!isPasswordValid()) {
                            AppFeedback.showError(
                              context,
                              "Password Requirements not met.",
                            );
                            return;
                          }

                          AppFeedback.showLoading(context, message: "Saving password...");
                          final modalContext = context;
                          
                          Contingent c = widget.contingent;
                          c.contingentCode = code;
                          c.password = HashUtil.hashPassword(passwordController.text);
                          c.resetCount = c.resetCount - 1;
                          bool result = await ContingentController()
                              .updateContingent(modalContext, c);

                          if (modalContext.mounted) {
                            AppFeedback.hideLoading(modalContext);
                            if (result) {
                              await SessionManager.saveContingentSession(c);
                              if (modalContext.mounted) {
                                setState(() {
                                  code = codeController.text;
                                });
                                AppFeedback.showSuccess(
                                  modalContext,
                                  "Password Changed Successfully!",
                                );
                                Navigator.pop(modalContext);
                              }
                            } else {
                              c.resetCount = c.resetCount + 1; // Revert locally
                              AppFeedback.showError(
                                modalContext,
                                "Error in Changing Password.",
                              );
                            }
                          }
                        },
                        child: Text(
                          "Save Changes",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final initialLetter = code.isNotEmpty ? code[0].toUpperCase() : 'C';

    return Container(
      color: AppColors.secondary,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar circle with golden/primary gradient border
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.0),
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withAlpha(50),
                      AppColors.primary.withAlpha(15),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(40),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initialLetter,
                    style: GoogleFonts.cinzel(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Code title
              Text(
                code,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                "Contingent Account",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary.withAlpha(200),
                ),
              ),
              const SizedBox(height: 32),

              // Details card
              LiquidGlassContainer(
                glowColor: AppColors.accent,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Account Details",
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.divider, thickness: 0.8),
                    const SizedBox(height: 16),

                    // Row 1: Code
                    _buildDetailRow(
                      icon: Icons.fingerprint,
                      label: "Contingent Code",
                      value: code,
                    ),
                    const SizedBox(height: 20),

                    // Row 2: Password
                    _buildDetailRow(
                      icon: Icons.lock_outline,
                      label: "Security Password",
                      value: "••••••••",
                      trailing: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: AppColors.primary.withAlpha(80)),
                          ),
                        ),
                        onPressed: () {
                          if (widget.contingent.resetCount <= 0) {
                            AppFeedback.showError(
                              context,
                              "Password reset limit reached. Please contact Admin.",
                            );
                            return;
                          }
                          _showEditSheet();
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          "Change",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Row 3: Remaining Resets
                    _buildDetailRow(
                      icon: Icons.refresh_outlined,
                      label: "Remaining Resets",
                      value: "${widget.contingent.resetCount} left",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
