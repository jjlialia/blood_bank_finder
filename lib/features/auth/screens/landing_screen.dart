import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'login_screen.dart';
import '../../user/screens/user_home_screen.dart';
import '../../super_admin/screens/super_admin_dashboard.dart';
import '../../hospital/screens/hospital_admin_dashboard.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _textFadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _textFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/landing_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.primaryColor,
                        const Color(0xFF8B0000),
                        Colors.black,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Hero(
                    tag: 'app_logo',
                    child: Icon(
                      Icons.bloodtype,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BLOOD BANK FINDER',
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const Spacer(),
                  FadeTransition(
                    opacity: _textFadeAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isAuthenticated
                              ? 'Welcome Back,\n${auth.user?.firstName}!'
                              : 'Saving Lives\nTogether',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          auth.isAuthenticated
                              ? 'Thank you for being part of our life-saving community. Your contributions make a real difference.'
                              : 'Connect with blood donors and hospitals near you. Every drop counts in an emergency.',
                          style: GoogleFonts.outfit(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.w300,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 48),
                        // Premium Primary Button
                        GestureDetector(
                          onTap: () {
                            if (auth.isAuthenticated) {
                              Widget nextScreen;
                              switch (auth.user?.role) {
                                case 'superadmin':
                                  nextScreen = const SuperAdminDashboard();
                                  break;
                                case 'admin':
                                  nextScreen = const HospitalAdminDashboard();
                                  break;
                                default:
                                  nextScreen = const UserHomeScreen();
                              }
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => nextScreen),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 64,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  Colors.white.withOpacity(0.9),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                auth.isAuthenticated ? 'Enter Dashboard' : 'Get Started',
                                style: GoogleFonts.outfit(
                                  color: theme.primaryColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (!auth.isAuthenticated)
                          Center(
                            child: TextButton(
                              onPressed: () {},
                              child: Text(
                                'Learn More About Our Mission',
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
