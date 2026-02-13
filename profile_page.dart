import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';
import 'booking_page.dart';
import 'feedback.dart';
import 'app_data.dart';
import 'worker_feedback_details.dart'; // ✅ new page

class ProfilePage extends StatefulWidget {
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

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isMyProfile = false;

  @override
  void initState() {
    super.initState();
    _checkIfOwnProfile();
  }

  Future<void> _checkIfOwnProfile() async {
    final activeProfile = await AppData.loadActiveProfile();
    final activeEmail = activeProfile?['email']?.toLowerCase() ?? '';
    setState(() {
      _isMyProfile = activeEmail == widget.email.toLowerCase();
    });
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout(context);
            },
            child: const Text("Yes, Logout"),
          ),
        ],
      ),
    );
  }

  Future<void> _bookWorker(BuildContext context) async {
    final activeProfile = await AppData.loadActiveProfile();
    final activeEmail = activeProfile?['email']?.toLowerCase() ?? '';

    if (activeEmail == widget.email.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ You cannot book yourself!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingPage(
          workerName: widget.name,
          workerEmail: widget.email,
        ),
      ),
    );
  }

  Future<void> _giveFeedback(BuildContext context) async {
    final activeProfile = await AppData.loadActiveProfile();
    final activeEmail = activeProfile?['email']?.toLowerCase() ?? '';

    if (activeEmail == widget.email.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ You cannot give feedback to yourself!"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedbackPage()),
    );
  }

  // ✅ Worker Bookings Section (for worker’s own profile)
  Widget _workerBookingsSection(String workerName) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppData.loadBookings(workerName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "⚠️ Failed to load bookings: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "No bookings yet.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "📅 My Bookings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            ...bookings.map((b) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.event, color: Colors.deepPurple),
                  title: Text(b['userName'] ?? 'Unknown Customer'),
                  subtitle: Text(
                    "📅 ${b['date']}  ⏰ ${b['time']}\n📧 ${b['userEmail'] ?? ''}",
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // 🧠 Clickable Worker Summary
  Widget _workerSummarySection(String workerName) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('summaries')
          .doc(workerName)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple));
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            "No feedback summary yet.",
            style: TextStyle(color: Colors.grey),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final rating = data['avgRating']?.toString() ?? 'N/A';
        final summary = data['summary']?.toString() ?? '';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    WorkerFeedbackDetailsPage(workerName: workerName),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text(
                      "AI Feedback Summary",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black87),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "Rating: $rating / 10",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (_isMyProfile)
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () => _confirmLogout(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.deepPurple,
              child: Icon(
                widget.isWorker ? Icons.handyman : Icons.person,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              widget.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _infoTile(Icons.email, 'Email', widget.email),
          if (widget.isWorker) ...[
            _infoTile(Icons.star, 'Skill', widget.skill),
            _infoTile(Icons.phone, 'Contact', widget.contact),
            _infoTile(Icons.access_time, 'Availability', widget.availability),
            _infoTile(Icons.location_on, 'Location',
                widget.location?.isNotEmpty == true ? widget.location! : 'N/A'),
            _workerSummarySection(widget.name),
          ],

          // ✅ Bookings for worker’s own profile
          if (_isMyProfile && widget.isWorker)
            _workerBookingsSection(widget.name),

          const SizedBox(height: 20),

          // ✅ Show Book / Feedback only when viewing worker (not own)
          if (widget.isWorker && !_isMyProfile) ...[
            ElevatedButton.icon(
              onPressed: () => _bookWorker(context),
              icon: const Icon(Icons.calendar_today),
              label: const Text("Book This Worker"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _giveFeedback(context),
              icon: const Icon(Icons.feedback),
              label: const Text("Give Feedback"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade100,
                foregroundColor: Colors.deepPurple,
              ),
            ),
          ],

          // ✅ Logout at bottom for self-profile
          if (_isMyProfile)
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
