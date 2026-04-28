library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'signup_screen.dart';
import 'landing_screen.dart';
import 'otp_screen.dart';

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

  /// validates, triggers OTP, then completes login.
  void _login() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // 1. Admin bypass check (skip OTP for superadmin)
      if (email == 'admin@gmail.com' && password == '1234') {
        final error = await auth.login(email, password);
        if (!mounted) return;
        if (error == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LandingScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
        return;
      }

      // 2. Trigger OTP first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sending verification code...')),
      );

      final otpError = await auth.sendOtp(email);
      if (!mounted) return;

      if (otpError != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(otpError), backgroundColor: Colors.red),
        );
        return;
      }

      // 3. Navigate to OTP Screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            email: email,
            onVerified: () => _completeLogin(email, password),
          ),
        ),
      );
    }
  }

  void _completeLogin(String email, String password) async {
    final auth = context.read<AuthProvider>();
    final error = await auth.login(email, password);

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }

    // Success
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LandingScreen()),
    );
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
