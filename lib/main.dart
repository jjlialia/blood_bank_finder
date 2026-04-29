import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/auth_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/blood_request/presentation/providers/blood_request_provider.dart';
import 'features/hospital/presentation/providers/hospital_provider.dart';
import 'features/super_admin/presentation/providers/super_admin_provider.dart';
import 'features/super_admin/infrastructure/repositories/firestore_super_admin_repository.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/chat/infrastructure/repositories/firestore_chat_repository.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BloodRequestProvider()),
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(
          create: (_) => SuperAdminProvider(FirestoreSuperAdminRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(FirestoreChatRepository()),
        ),
      ],
      child: const BloodBankApp(),
    ),
  );
}


class BloodBankApp extends StatelessWidget {
  const BloodBankApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Bank Finder',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
