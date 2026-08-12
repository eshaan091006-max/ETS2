import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:malhar_ets/app/admin/auth/admin_controller.dart';
import 'package:malhar_ets/app/admin/main.dart';
import 'package:malhar_ets/constants/app_bar.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/page_transitions.dart';
import 'package:malhar_ets/utils/app_feedback.dart';
import 'package:malhar_ets/utils/session_manager.dart';
import 'package:malhar_ets/helpers/glass_container.dart';
import 'package:malhar_ets/helpers/ambient_glow_background.dart';

class LoginPageAdmin extends StatefulWidget {
  const LoginPageAdmin({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPageAdmin> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: getAppBar(context, false),
      body: AmbientGlowBackground(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
          child: SingleChildScrollView(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1.0 - value)),
                    child: child,
                  ),
                );
              },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: isKeyboardOpen ? 15.0 : (MediaQuery.of(context).padding.top + kToolbarHeight + 10)),
                Text(
                  "Admin Login",
                  style: GoogleFonts.montserrat(
                    fontSize: isKeyboardOpen ? 20 : 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: isKeyboardOpen ? 15.0 : 40.0),
                LiquidGlassContainer(
                  glowColor: AppColors.primary,
                  padding: EdgeInsets.all(isKeyboardOpen ? 16.0 : 24.0),
                  child: Form(
                    key: _formKey,
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _usernameController,
                            label: "Username",
                            hint: "Enter your username",
                            focusNode: _usernameFocus,
                            autofillHint: AutofillHints.username,
                          ),
                          SizedBox(height: isKeyboardOpen ? 12.0 : 20.0),
                          _buildTextField(
                            controller: _passwordController,
                            label: "Password",
                            hint: "Enter your password",
                            obscureText: true,
                            focusNode: _passwordFocus,
                            autofillHint: AutofillHints.password,
                          ),
                          SizedBox(height: isKeyboardOpen ? 16.0 : 30.0),
                          _buildGradientButton(
                            text: "Login",
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) return;

                              AppFeedback.showLoading(
                                context,
                                message: 'Authenticating...',
                              );

                              try {
                                final result = await AdminController.loginAsAdmin(
                                  _usernameController.text,
                                  _passwordController.text,
                                );
                                if (!context.mounted) return;

                                AppFeedback.hideLoading(context);

                                if (result['success']) {
                                  TextInput.finishAutofillContext(); // ✅ End autofill
                                  final navigator = Navigator.of(context);
                                  await SessionManager.saveAdminSession(
                                    _usernameController.text,
                                    result['is_volunteer'] ?? false,
                                    result['token'] ?? '',
                                  );
                                  if (context.mounted) {
                                    AppFeedback.showSuccess(
                                      context,
                                      result['message'],
                                    );
                                    navigator.pushReplacement(
                                      LiquidPageRoute(
                                        page: Main(
                                          isVolunteer: result['is_volunteer'],
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  AppFeedback.showError(
                                    context,
                                    result['message'],
                                  );
                                }
                              } catch (e) {
                                if (!context.mounted) return;
                                AppFeedback.hideLoading(context);
                                AppFeedback.showError(
                                  context,
                                  'An error occurred: $e',
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                  SizedBox(height: isKeyboardOpen ? 10.0 : 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: GoogleFonts.montserrat(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                           final Uri emailLaunchUri;
                           if (kIsWeb) {
                             emailLaunchUri = Uri(
                               scheme: 'https',
                               host: 'mail.google.com',
                               path: '/mail/',
                               queryParameters: {
                                 'view': 'cm',
                                 'fs': '1',
                                 'to': 'malhar.admin@xaviers.edu.in',
                                 'su': 'Admin Registration Query',
                                 'body': 'Hey, I am having trouble registering an Admin account.',
                               },
                             );
                           } else {
                             emailLaunchUri = Uri(
                               scheme: 'mailto',
                               path: 'malhar.admin@xaviers.edu.in',
                               queryParameters: {
                                 'subject': 'Admin Registration Query',
                                 'body': 'Hey, I am having trouble registering an Admin account.',
                               },
                             );
                           }

                          try {
                            final bool launched = await launchUrl(
                              emailLaunchUri,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!launched) {
                              throw Exception("Failed to launch email client");
                            }
                          } catch (e) {
                            // Fallback: If mailto failed, try launching Gmail in the browser
                            if (emailLaunchUri.scheme == 'mailto') {
                              final Uri gmailUri = Uri(
                                scheme: 'https',
                                host: 'mail.google.com',
                                path: '/mail/',
                                queryParameters: {
                                  'view': 'cm',
                                  'fs': '1',
                                  'to': 'malhar.admin@xaviers.edu.in',
                                  'su': 'Admin Registration Query',
                                  'body': 'Hey, I am having trouble registering an Admin account.',
                                },
                              );
                              try {
                                final bool webLaunched = await launchUrl(
                                  gmailUri,
                                  mode: LaunchMode.externalApplication,
                                );
                                if (webLaunched) return; // Fallback succeeded
                              } catch (_) {
                                // If even Gmail Web fails, fall through to the dialog
                              }
                            }

                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: AppColors.secondary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: const BorderSide(color: AppColors.border, width: 1.5),
                                ),
                                title: Text(
                                  "Contact Support",
                                  style: GoogleFonts.montserrat(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "No default email client could be launched. You can reach the admin directly at:",
                                      style: GoogleFonts.poppins(color: AppColors.textWhite),
                                    ),
                                    const SizedBox(height: 16),
                                    SelectableText(
                                      "malhar.admin@xaviers.edu.in",
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text(
                                      "Close",
                                      style: GoogleFonts.poppins(
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final Uri gmailUri = Uri(
                                        scheme: 'https',
                                        host: 'mail.google.com',
                                        path: '/mail/',
                                        queryParameters: {
                                          'view': 'cm',
                                          'fs': '1',
                                          'to': 'malhar.admin@xaviers.edu.in',
                                          'su': 'Admin Registration Query',
                                          'body': 'Hey, I am having trouble registering an Admin account.',
                                        },
                                      );
                                      Navigator.pop(context);
                                      try {
                                        await launchUrl(
                                          gmailUri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                      } catch (_) {
                                        // Ignore failure to open web page
                                      }
                                    },
                                    child: Text(
                                      "Open Gmail",
                                      style: GoogleFonts.poppins(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () {
                                      Clipboard.setData(
                                        const ClipboardData(
                                          text: "malhar.admin@xaviers.edu.in",
                                        ),
                                      );
                                      Navigator.pop(context);
                                      AppFeedback.showSuccess(
                                        context,
                                        "Email address copied to clipboard!",
                                      );
                                    },
                                    child: Text(
                                      "Copy",
                                      style: GoogleFonts.poppins(
                                        color: AppColors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        child: Text(
                          "Contact Admin",
                          style: GoogleFonts.montserrat(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

    Widget _buildTextField({
      required TextEditingController controller,
      required String label,
      required String hint,
      required FocusNode focusNode,
      bool obscureText = false,
      String? autofillHint,
    }) {
      return TextFormField(
        controller: controller,
        focusNode: focusNode,
        style: const TextStyle(color: AppColors.textWhite),
        obscureText: (obscureText) ? _obscurePassword : false,
        autofillHints: autofillHint != null ? [autofillHint] : null,
        onTap: () {
          if (!focusNode.hasFocus) {
            focusNode.requestFocus();
          } else {
            if (!kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
              focusNode.unfocus();
              Future.delayed(const Duration(milliseconds: 50), () {
                focusNode.requestFocus();
              });
            }
          }
        },
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColors.textSecondary, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          suffixIconColor: AppColors.textWhite,
          suffixIcon:
              (!obscureText)
                  ? const Icon(Icons.person)
                  : IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.primary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                      Future.delayed(const Duration(milliseconds: 50), () {
                        focusNode.requestFocus();
                      });
                    },
                  ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      );
    }

    Widget _buildGradientButton({
      required VoidCallback onPressed,
      required String text,
    }) {
      return Container(
        decoration: BoxDecoration(
          gradient: AppColors.sunburstGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 60,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
      );
    }
}
