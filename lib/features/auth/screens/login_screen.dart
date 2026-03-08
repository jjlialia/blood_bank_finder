import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';
import 'signup_screen.dart';
import '../../user/screens/user_home_screen.dart';
import '../../super_admin/screens/super_admin_dashboard.dart';
import '../../hospital/screens/hospital_admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final error = await auth.login(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
        return;
      }

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

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
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
                Icon(
                  Icons.bloodtype,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: 16),
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
                CustomTextField(
                  label: 'Email',
                  prefixIcon: Icons.email_outlined,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v!.contains('@') ? null : 'Invalid email',
                ),
                CustomTextField(
                  label: 'Password',
                  prefixIcon: Icons.lock_outline,
                  controller: _passwordController,
                  obscureText: true,
                  validator: (v) =>
                      v!.length >= 6 ? null : 'Password too short',
                ),
                const SizedBox(height: 24),
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
                const SizedBox(height: 40),
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Demo Shortcuts:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () =>
                          _emailController.text = 'admin@blood.com',
                      child: const Text('Admin'),
                    ),
                    TextButton(
                      onPressed: () =>
                          _emailController.text = 'hospital@blood.com',
                      child: const Text('Hospital'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
