/**
 * FILE: splash_screen.dart
 * 
 * DESCRIPTION:
 * The entry point of the application UI. It performs background 
 * authentication checks while displaying a branded animation to the user.
 * 
 * DATA FLOW OVERVIEW:
 * 1. RECEIVES DATA FROM: 
 *    - 'AuthProvider': Checks 'isAuthenticated' to see if a session exists.
 *    - 'UserModel': Retrieves the 'role' to decide where to send the user.
 * 2. PROCESSING:
 *    - Persistence Check: As soon as the app opens, it asks the AuthProvider 
 *      if a user was previously logged in.
 *    - Animation Lifecycle: Runs a 2-second fade-in visual.
 * 3. SENDS DATA TO:
 *    - Navigation: Switches the GUI to either 'LoginScreen' or a specific Dashboard.
 * 4. OUTPUTS/GUI:
 *    - Animated logo and "Blood Bank Finder" title.
 *    - "Proceed to Login" button for manual navigation.
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';
import 'login_screen.dart';
import '../../user/screens/user_home_screen.dart';
import '../../super_admin/screens/super_admin_dashboard.dart';
import '../../hospital/screens/hospital_admin_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    // STEP: Initialize the visual animation.
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    
    // STEP: Start the hidden data flow check.
    _checkAuthAndNavigate();
  }

  /**
   * CORE LOGIC: The Startup Data Flow.
   * 1. Waits for 3 seconds (to ensure the splash is seen).
   * 2. DATA CHECK: Asks 'AuthProvider' if someone is already logged in.
   * 3. DECISION:
   *    - If NO: Stays on this screen or goes to Login.
   *    - If YES: Evaluates the Role (SuperAdmin, Admin, User) and jumps to their dashboard.
   */
  void _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    
    // STEP: If we have an existing session, skip the login screen entirely.
    if (auth.isAuthenticated) {
      Widget nextScreen;
      final role = auth.user?.role;
      
      // ROLE GATE: Routing users based on their data profile.
      if (role == 'superadmin') {
        nextScreen = const SuperAdminDashboard();
      } else if (role == 'admin') {
        nextScreen = const HospitalAdminDashboard();
      } else {
        nextScreen = const UserHomeScreen();
      }

      // FINAL STEP: Enter the app.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // GUI: Background Image with Error Handling.
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // If the asset is missing, we use a fallback brand color.
                debugPrint('Asset Error: $error');
                return Container(color: Colors.red[900]);
              },
            ),
          ),
          // GUI: Readability overlay.
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // STEP: The fading brand logo.
                FadeTransition(
                  opacity: _animation,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.bloodtype,
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Blood Bank Finder',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton(
                    onPressed: _navigateToLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text('Proceed to Login'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
