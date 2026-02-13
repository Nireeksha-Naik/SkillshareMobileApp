import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ added this
import 'firebase_options.dart'; //

class WorkerFormPage extends StatefulWidget {
  const WorkerFormPage({super.key});

  @override
  State<WorkerFormPage> createState() => _WorkerFormPageState();
}

class _WorkerFormPageState extends State<WorkerFormPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final skillController = TextEditingController();
  final experienceController = TextEditingController();
  final locationController = TextEditingController();
  final availabilityController = TextEditingController();
  final contactController = TextEditingController();

  bool isLoading = false;

  Future<void> addWorkerData() async {
    // ✅ ensure Firebase is initialized before Firestore
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase initialized inside form ✅");
    }

    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        skillController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      print("📤 Uploading worker data...");

      final docRef = await FirebaseFirestore.instance.collection('workers').add({
        'name': nameController.text.trim(),
        'email': emailController.text.trim(),
        'password': passwordController.text.trim(),
        'skill': skillController.text.trim(),
        'experience': int.tryParse(experienceController.text.trim()) ?? 0,
        'location': locationController.text.trim(),
        'availability': int.tryParse(availabilityController.text.trim()) ?? 0,
        'contact_number': contactController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Upload success! Document ID: ${docRef.id}");

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Worker info added successfully!")),
      );

      nameController.clear();
      emailController.clear();
      passwordController.clear();
      skillController.clear();
      experienceController.clear();
      locationController.clear();
      availabilityController.clear();
      contactController.clear();
    } catch (e) {
      print("❌ Error adding worker: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Worker Info")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            TextField(controller: skillController, decoration: const InputDecoration(labelText: "Skill")),
            TextField(
              controller: experienceController,
              decoration: const InputDecoration(labelText: "Experience (in years)"),
              keyboardType: TextInputType.number,
            ),
            TextField(controller: locationController, decoration: const InputDecoration(labelText: "Location")),
            TextField(
              controller: availabilityController,
              decoration: const InputDecoration(labelText: "Availability (in days)"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: contactController,
              decoration: const InputDecoration(labelText: "Contact Number"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: isLoading ? null : addWorkerData,
              icon: isLoading
                  ? const SizedBox(
                width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(isLoading ? "Saving..." : "Save Worker Info"),
            ),
          ],
        ),
      ),
    );
  }
}
