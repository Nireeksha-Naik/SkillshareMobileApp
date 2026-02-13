// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'login.dart';
import 'worker_form.dart';
import 'feedback.dart';
import 'booking_page.dart';
import 'homepage.dart';
import 'summaries.dart'; // ✅ Added for summaries page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint("🟣 STEP 1: Flutter initialized");

  // ✅ Initialize Firebase safely (avoid [core/duplicate-app])
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint("🟢 Firebase initialized");
    } else {
      debugPrint("⚠️ Firebase already initialized");
    }
  } catch (e, st) {
    debugPrint("❌ Firebase initialization failed: $e");
    debugPrint(st.toString());
  }

  debugPrint("🟣 STEP 2: Running app…");
  runApp(const SkillConnectApp());
}

class SkillConnectApp extends StatelessWidget {
  const SkillConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillConnect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFF7F3FF),
      ),
      home: const StartupPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/workerForm': (context) => const WorkerFormPage(),
        '/feedback': (context) => const FeedbackPage(),
        '/booking': (context) {
          final args =
              ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return BookingPage(
            workerName: args?['workerName'] ?? '',
            workerEmail: args?['workerEmail'] ?? '',
          );
        },
        '/summaries': (context) => const SummariesPage(), // ✅ NEW ROUTE
      },
    );
  }
}

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();
    _goLogin();
  }

  Future<void> _goLogin() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF7F3FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 20),
            Text(
              "Loading SkillConnect...",
              style: TextStyle(
                color: Colors.deepPurple,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
