/*profile.dart
import 'package:flutter/material.dart';
import 'login.dart';

class ProfilePage extends StatelessWidget {
  final String name;
  final String email;
  final String skill;
  final String experience;
  final String contact;
  final String availability;
  final bool isWorker;
  final String? location;

  const ProfilePage({
    super.key,
    required this.name,
    required this.email,
    required this.skill,
    required this.experience,
    required this.contact,
    required this.availability,
    required this.isWorker,
    this.location,
  });

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.deepPurple,
              child: Icon(isWorker ? Icons.handyman : Icons.person,
                  size: 40, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple)),
          ),
          Center(
            child: Text(isWorker ? 'Worker' : 'User',
                style: const TextStyle(fontSize: 15, color: Colors.grey)),
          ),
          const SizedBox(height: 20),

          _infoTile(Icons.email, 'Email', email),

          if (isWorker) ...[
            const SizedBox(height: 10),
            _infoTile(Icons.star, 'Skill', skill),
            _infoTile(Icons.work, 'Experience', experience),
            _infoTile(Icons.phone, 'Contact', contact),
            _infoTile(Icons.access_time, 'Availability', availability),
            _infoTile(Icons.location_on, 'Location',
                (location != null && location!.isNotEmpty)
                    ? location!
                    : 'Not provided'),
          ],

          const SizedBox(height: 30),
          Center(
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/