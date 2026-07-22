import 'package:campusscore/views/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campusscore/services/auth/auth_service.dart';
import 'package:campusscore/views/Register_Login_View.dart';
// Make sure to import your verify email and home views
// import 'package:campusscore/views/verify_email_view.dart';
// import 'package:campusscore/views/home_view.dart';
import 'firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:campusscore/services/db/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DatabaseProvider()),
      ],
      child: MaterialApp(
        title: 'CampusScore',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B00)),
        ),
        home: const AuthGate(),
      ),
    ),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B00)),
            ),
          );
        }

        final user = snapshot.data;

        // 2. Not Logged In -> Show Login/Register View
        // (Your Google Sign-In button inside this view will trigger state changes)
        if (user == null) {
          return const Register_Login_View();
        }

        // 3. Logged In but Email Not Verified
        // Note: Google Sign-In accounts are usually auto-verified by Firebase.
        final isVerified =
            AuthService.firebase().currentUser?.isEmailVeified ?? false;

        if (!isVerified) {
          return const VerifyEmailView();
        }

        // 4. Logged In & Verified -> Main App Content
        return const MainLayout();
      },
    );
  }
}
