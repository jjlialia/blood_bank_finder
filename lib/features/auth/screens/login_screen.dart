library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'signup_screen.dart';
import 'landing_screen.dart';
import '../../user/screens/user_home_screen.dart';
import '../../super_admin/screens/super_admin_dashboard.dart';
import '../../hospital/screens/hospital_admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Hold typed credentials.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// validates, auth.login - fastapi-firebase auth, error message ,usermodel, decide where to go on role.
  void _login() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();

      //network request by AuthProvider.
      final error = await auth.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      //falure handling
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }

      // role to decide where to go
      Widget nextScreen;
      switch (auth.user?.role) {
        case 'superadmin':
          nextScreen = const SuperAdminDashboard();
          break;
        case 'admin':
          nextScreen = const HospitalAdminDashboard();
          break;
        case 'user':
        default:
          nextScreen = const UserHomeScreen();
          break;
      }

      // Navigate to LandingScreen as requested ("put a landing page after login")
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                const SizedBox(height: 60),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.displayLarge,
                ),
                Text(
                  'Blood Bank Finder',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 48),
                //Email
                CustomTextField(
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.contains('@') ? null : 'Invalid email',
                ),
                // Password
                CustomTextField(
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) =>
                      v!.length >= 6 ? null : 'Password too short',
                ),
                const SizedBox(height: 24),
                // action tiggerring _login data flow.
                Consumer<AuthProvider>(
                  builder: (context, auth, _) => CustomButton(
                    label: 'Login',
                    isLoading: auth.isLoading,
                    onPressed: _login,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SignupScreen(),
                      ),
                    );
                  },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
