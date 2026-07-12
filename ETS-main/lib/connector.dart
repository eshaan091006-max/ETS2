import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:malhar_ets/app/admin/login/login_page.dart';
import 'package:malhar_ets/app/contingent/login/login_page.dart';
import 'package:malhar_ets/constants/app_bar.dart';
import 'package:malhar_ets/constants/app_colors.dart';
import 'package:malhar_ets/helpers/glass_container.dart';
import 'package:malhar_ets/utils/session_manager.dart';
import 'package:malhar_ets/app/admin/main.dart' as admin_main;
import 'package:malhar_ets/app/contingent/main.dart' as contingent_main;
import 'package:malhar_ets/helpers/page_transitions.dart';

class Connector extends StatefulWidget {
  const Connector({super.key});

  @override
  State<Connector> createState() => _ConnectorState();
}

class _ConnectorState extends State<Connector> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    final session = await SessionManager.getSession();
    final token = await SessionManager.getToken();
    if (session != null) {
      if (token != null && token.isNotEmpty) {
        try {
          await SessionManager.restoreCustomJWTSession(token);
          // Wait for the restored session to propagate to the Supabase client headers
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          debugPrint("Failed to restore Supabase session on startup: $e");
        }
      }
      if (mounted) {
        if (session['type'] == 'admin') {
          Navigator.of(context).pushReplacement(
            LiquidPageRoute(
              page: admin_main.Main(
                isVolunteer: session['is_volunteer'],
              ),
            ),
          );
        } else if (session['type'] == 'contingent') {
          Navigator.of(context).pushReplacement(
            LiquidPageRoute(
              page: contingent_main.Main(
                contingent: session['contingent'],
              ),
            ),
          );
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _checkingSession = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(80),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/logo/malhar26_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: AppColors.primary),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.secondary,
      extendBodyBehindAppBar: true,
      appBar: getAppBar(context, false),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Color(0xFF1E1400), // Very dark warm gold/amber sun-like glow in center
              AppColors.background, // Pure pitch black
            ],
            radius: 1.0,
            center: Alignment.center,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 800),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo container with subtle glowing effect
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(80),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                          BoxShadow(
                            color: AppColors.primary.withAlpha(50),
                            blurRadius: 50,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/logo/malhar26_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Title text
                    Text(
                      'Malhar 26',
                      style: GoogleFonts.montserrat(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            color: AppColors.accent,
                            offset: Offset(2, 2),
                            blurRadius: 4,
                          ),
                          const Shadow(
                            color: AppColors.primary,
                            offset: Offset(-2, -2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'EVENT TRACKING SYSTEM',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Portal Buttons
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 320),
                      child: Column(
                        children: [
                          LiquidGlassContainer(
                            onTap: () => Navigator.of(context).push(
                              LiquidPageRoute(page: const LoginPage()),
                            ),
                            glowColor: AppColors.accent,
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                'Contingent Portal',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          LiquidGlassContainer(
                            onTap: () => Navigator.of(context).push(
                              LiquidPageRoute(page: const LoginPageAdmin()),
                            ),
                            glowColor: AppColors.primary,
                            borderRadius: 14,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: Text(
                                'Admin Portal',
                                style: GoogleFonts.montserrat(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
}
