import 'package:flutter/material.dart';
import 'login.dart';
import 'profile_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_data.dart';
import 'dart:async';
import 'emailjs.dart';

class HomePage extends StatefulWidget {
  final String name;
  final String email;
  final String? skill;
  final String? experience;
  final String? contact;
  final String? availability;
  final String? location;
  final bool isWorker;

  const HomePage({
    super.key,
    required this.name,
    required this.email,
    this.skill,
    this.experience,
    this.contact,
    this.availability,
    this.location,
    required this.isWorker,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allWorkers = [];
  List<Map<String, dynamic>> _filteredWorkers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (!widget.isWorker) {
      _loadWorkers();
    } else {
      setState(() => _loading = false);
    }
  }

  // -----------------------------------
  // ⭐ ADDED FUNCTION (only addition)
  // -----------------------------------
  Future<void> _setBookingStatus(
      Map<String, dynamic> booking, String status) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('bookings')
          .where('worker', isEqualTo: widget.name)
          .where('userEmail', isEqualTo: booking['userEmail'])
          .where('timestamp', isEqualTo: booking['timestamp'])
          .get();

      if (snap.docs.isEmpty) return;

      final docId = snap.docs.first.id;

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'status': status});

      await sendStatusEmail(
        customerEmail: booking['userEmail'],
        customerName: booking['userName'],
        workerName: widget.name,
        date: booking['date'],
        time: booking['time'],
        status: status,
      );

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated to $status")),
      );
    } catch (e) {
      print("Status update error: $e");
    }
  }

  // ---------------- Load all workers ----------------
  Future<void> _loadWorkers() async {
    setState(() => _loading = true);
    try {
      QuerySnapshot<Map<String, dynamic>> query;

      try {
        query = await FirebaseFirestore.instance
            .collection('profiles')
            .where('isWorker', isEqualTo: true)
            .get()
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        throw Exception('Server timeout. Please check your internet.');
      }

      List<Map<String, dynamic>> workers =
          query.docs.map((d) => d.data()).toList();

      if (workers.isEmpty) {
        final all =
            await FirebaseFirestore.instance.collection('profiles').get();
        workers = all.docs.map((d) => d.data()).toList();
      }

      setState(() {
        _allWorkers = workers;
        _filteredWorkers = List.from(_allWorkers);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load workers: $e')),
      );
    }
  }

  // ---------------- Search filter ----------------
  Future<void> _filterWorkers(String query) async {
    final q = query.trim().toLowerCase();

    final summarySnap =
        await FirebaseFirestore.instance.collection('summaries').get();
    final Map<String, double> ratings = {};
    for (var doc in summarySnap.docs) {
      final data = doc.data();
      final avg =
          double.tryParse(data['avgRating']?.toString() ?? '') ?? 0.0;
      ratings[doc.id.toLowerCase()] = avg;
    }

    List<Map<String, dynamic>> workers = _allWorkers.where((w) {
      final name = (w['name'] ?? '').toString().toLowerCase();
      final skill = (w['skill'] ?? '').toString().toLowerCase();
      final location = (w['location'] ?? '').toString().toLowerCase();
      return name.contains(q) || skill.contains(q) || location.contains(q);
    }).toList();

    workers.sort((a, b) {
      final ar = ratings[a['name']?.toString().toLowerCase()] ?? 0.0;
      final br = ratings[b['name']?.toString().toLowerCase()] ?? 0.0;
      return br.compareTo(ar);
    });

    setState(() => _filteredWorkers = workers);
  }

  // ---------------- Logout ----------------
  Future<void> _logout() async {
    try {
      await AppData.clearActiveSession();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
      }
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3FF),
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text(widget.isWorker ? 'Worker Dashboard' : 'User Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(
                    name: widget.name,
                    email: widget.email,
                    skill: widget.skill ?? '',
                    experience: widget.experience ?? '',
                    contact: widget.contact ?? '',
                    availability: widget.availability ?? '',
                    isWorker: widget.isWorker,
                    location: widget.location ?? '',
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple))
          : widget.isWorker
              ? _buildWorkerDashboard()
              : _buildUserDashboard(),
    );
  }

  // ---------------- Worker Dashboard ----------------
  Widget _buildWorkerDashboard() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AppData.loadBookings(widget.name),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple));
        }

        final bookings = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'Welcome, ${widget.name}!',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoRow("Email", widget.email),
                      _infoRow("Skill", widget.skill ?? ''),
                      _infoRow("Experience", widget.experience ?? ''),
                      _infoRow("Contact", widget.contact ?? ''),
                      _infoRow("Availability", widget.availability ?? ''),
                      _infoRow("Location", widget.location ?? ''),
                      const SizedBox(height: 10),
                      const Text(
                        'You are logged in as a worker.\nYour details are visible to users.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "📅 My Bookings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),

              // ----------------------------------------
              // ⭐ UPDATED BOOKING LIST (Only this)
              // ----------------------------------------
              bookings.isEmpty
                  ? const Text("No bookings yet.",
                      style: TextStyle(color: Colors.grey))
                  : ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: bookings.length,
  itemBuilder: (context, i) {
    final b = bookings[i];

    final userName = b['userName'] ?? 'Unknown';
    final userEmail = b['userEmail'] ?? '';
    final date = b['date'] ?? '';
    final time = b['time'] ?? '';
    final status = b['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 4),

            Text("📅 $date"),
            Text("⏰ $time"),
            Text("📧 $userEmail"),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: status == "accepted"
                    ? Colors.green.shade100
                    : status == "rejected"
                        ? Colors.red.shade100
                        : Colors.yellow.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Status: $status",
                style: TextStyle(
                  color: status == "accepted"
                      ? Colors.green
                      : status == "rejected"
                          ? Colors.red
                          : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (status == "pending")
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    onPressed: () => _setBookingStatus(b, "accepted"),
                    child: const Text("ACCEPT"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    onPressed: () => _setBookingStatus(b, "rejected"),
                    child: const Text("REJECT"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  },
)
,
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    if (value.trim().isEmpty) value = "Not provided";
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("$label: ",
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Flexible(child: Text(value)),
        ],
      ),
    );
  }

  // ---------------- User Dashboard ----------------
  Widget _buildUserDashboard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Welcome, ${widget.name}!',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 10),
          Text('Email: ${widget.email}',
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),

          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search workers by name, skill, or location',
              prefixIcon:
                  const Icon(Icons.search, color: Colors.deepPurple),
              filled: true,
              fillColor: Colors.white,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: _filterWorkers,
          ),
          const SizedBox(height: 12),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('summaries')
                  .snapshots(),
              builder: (context, snapshot) {
                final summaries = <String, dynamic>{};
                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    summaries[doc.id] = doc.data();
                  }
                }

                return ListView.builder(
                  itemCount: _filteredWorkers.length,
                  itemBuilder: (context, i) {
                    final w = _filteredWorkers[i];
                    final s = summaries[w['name']] ?? {};
                    final rating = s['avgRating'] ?? 'N/A';
                    final summary = (s['summary'] ?? '').toString();

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: CircleAvatar(
                        backgroundColor: Colors.deepPurple,
                        child:
                            const Icon(Icons.handyman, color: Colors.white),
                      ),
                      title: Text(
                        w['name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        '${w['skill'] ?? ''} • ${w['location'] ?? ''} • ${w['availability'] ?? ''}\n⭐ $rating  ${summary.isNotEmpty ? summary : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfilePage(
                              name: w['name'] ?? '',
                              email: w['email'] ?? '',
                              skill: w['skill'] ?? '',
                              experience: w['experience'] ?? '',
                              contact: w['contact'] ?? '',
                              availability: w['availability'] ?? '',
                              isWorker: true,
                              location: w['location'] ?? '',
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
