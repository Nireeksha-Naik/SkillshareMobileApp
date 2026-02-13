import 'package:flutter/material.dart';
import 'homepage.dart';
import 'app_data.dart';
import 'signup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'emailjs.dart'; // ✅ Added for sending recovery email

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  bool isWorker = false;
  bool _loading = false;
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;

  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // ----------------------- Validators -----------------------
  String? emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter email';
    final email = v.trim();
    if (!RegExp(r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$").hasMatch(email)) {
      return 'Enter valid email';
    }
    return null;
  }

  String? passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Enter password';
    if (v.length < 6) return 'Password must be at least 6 chars';
    return null;
  }

  // ----------------------- Submit -----------------------
  Future<void> _onSubmit() async {
    setState(() => _autoValidate = AutovalidateMode.always);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    final email = _email.text.trim();
    final isWorkerRole = isWorker;

    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found. Please Sign up first.')),
        );
        setState(() => _loading = false);
        return;
      }

      final data = snap.docs.first.data();

      // 🔐 Password check
      if (data['password'] != _password.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect password')),
        );
        setState(() => _loading = false);
        return;
      }

      // 🔄 Role mismatch check
      final isWorkerInDb = data['isWorker'] == true;
      if (isWorkerInDb != isWorkerRole) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWorkerInDb
                ? 'This is a worker account. Switch to Worker login.'
                : 'This is a user account. Switch to User login.'),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      // ✅ Clean Firestore data before saving locally
      final cleanProfile = <String, dynamic>{};
      data.forEach((key, value) {
        if (value is! FieldValue && value is! Timestamp && value is! DocumentReference) {
          cleanProfile[key] = value;
        }
      });

      // ✅ Save profile locally
      await AppData.saveActiveProfile(
        role: isWorker ? 'worker' : 'user',
        profile: cleanProfile,
      );

      // ✅ Navigate to HomePage
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(
            name: cleanProfile['name'] ?? '',
            email: cleanProfile['email'] ?? '',
            skill: isWorker ? cleanProfile['skill'] : null,
            experience: isWorker ? cleanProfile['experience'] : null,
            contact: isWorker ? cleanProfile['contact'] : null,
            availability: isWorker ? cleanProfile['availability'] : null,
            isWorker: isWorker,
            location: isWorker ? cleanProfile['location'] : null,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: $e')),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  // ----------------------- Forgot Password -----------------------
  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email to recover password')),
      );
      return;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('profiles')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No account found with this email')),
        );
        return;
      }

      final data = snap.docs.first.data();
      final password = data['password'] ?? 'Not found';
      final name = data['name'] ?? 'User';

      // ✅ Send recovery email using EmailJS
      try {
        await sendPasswordRecoveryEmail(
          toEmail: email,
          userName: name,
          password: password.toString(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Password has been sent to your email.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ Failed to send email: $e')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // ----------------------- Build UI -----------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        title: const Text('SkillConnect Login'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Form(
                key: _formKey,
                autovalidateMode: _autoValidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: ToggleButtons(
                        isSelected: [!isWorker, isWorker],
                        onPressed: (i) => setState(() => isWorker = (i == 1)),
                        borderRadius: BorderRadius.circular(10),
                        selectedColor: Colors.white,
                        fillColor: Colors.deepPurple,
                        color: Colors.deepPurple,
                        children: const [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text('User'),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: Text('Worker'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildField(_email, Icons.email, 'Email', validator: emailValidator),
                    _buildField(_password, Icons.lock, 'Password',
                        obscure: true, validator: passwordValidator),

                    // 🔹 Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text(
                          "Forgot Password?",
                          style: TextStyle(color: Colors.deepPurple),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                          : Text(
                        isWorker ? 'Login as Worker' : 'Login as User',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account? "),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupPage()),
                            );
                          },
                          child: const Text(
                            "Sign up",
                            style: TextStyle(
                              color: Colors.deepPurple,
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

  Widget _buildField(TextEditingController c, IconData icon, String label,
      {bool obscure = false, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: c,
        obscureText: obscure,
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.deepPurple),
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
          ),
        ),
      ),
    );
  }
}
