import 'package:flutter/material.dart';
import 'app_data.dart'; // ✅ Firestore booking storage
import 'emailjs.dart'; // ✅ Your email system

class BookingPage extends StatefulWidget {
  final String workerName;
  final String workerEmail;

  const BookingPage({
    super.key,
    required this.workerName,
    required this.workerEmail,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  String? userName;
  String? userEmail;

  final List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // 🧠 Load logged-in user profile
  Future<void> _loadUserProfile() async {
    final activeProfile = await AppData.loadActiveProfile();
    setState(() {
      userName = activeProfile?['name'] ?? 'Unknown Customer'; // ✅ FIX
      userEmail = activeProfile?['email'] ?? 'unknown@example.com'; // ✅ FIX
    });
  }

  // 📅 Select Date
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  // ⏰ Select Time
  Future<void> _pickTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) setState(() => _selectedTime = pickedTime);
  }

  // ✅ Confirm Booking
  Future<void> _confirmBooking() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both date and time")),
      );
      return;
    }

    if (userName == null || userEmail == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ User info not loaded. Try again.")),
      );
      return;
    }

    final selectedDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    // 🕐 Restrict booking hours
    if (_selectedTime!.hour < 9 || _selectedTime!.hour >= 18) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("Bookings are allowed only between 9:00 AM and 6:00 PM."),
        ),
      );
      return;
    }

    // 🧠 Prevent overlapping bookings (within 1 hour)
    final conflict = _bookings.any((b) {
      final existing = b['datetime'] as DateTime;
      final diff = selectedDateTime.difference(existing).inMinutes.abs();
      return diff < 60;
    });

    if (conflict) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please choose a time at least 1 hour apart from other bookings."),
        ),
      );
      return;
    }

    final selectedDateTimeString = "${selectedDateTime.toLocal()}".split('.')[0];

    // 🗂 Booking Data
    final bookingData = {
      'workerName': widget.workerName,
      'workerEmail': widget.workerEmail,
      'userName': userName, // ✅ FIX — included properly
      'userEmail': userEmail, // ✅ FIX — included properly
      'date': "${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}",
      'time': "${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}",
      'timestamp': selectedDateTimeString,
    };

    try {
      // ✅ 1. Save to Firestore
      await AppData.addBooking(widget.workerName, bookingData);

      // ✅ 2. Send email notification
      try {
        await sendBookingEmail(
          workerEmail: widget.workerEmail,
          workerName: widget.workerName,
          userName: userName!,
          bookingDate: selectedDateTimeString,
          customerEmail: userEmail,
        );
      } catch (e) {
        print("⚠️ Email send failed (network issue maybe): $e");
      }

      // ✅ 3. Save locally
      setState(() {
        _bookings.add({
          'datetime': selectedDateTime,
          'formatted': selectedDateTimeString,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "✅ Booking confirmed for ${widget.workerName} on $selectedDateTimeString",
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Booking failed: $e")),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Worker"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Worker: ${widget.workerName}",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Your name: ${userName ?? 'Loading...'}",
              style: const TextStyle(color: Colors.deepPurple),
            ),
            Text(
              "Your email: ${userEmail ?? 'Loading...'}",
              style: const TextStyle(color: Colors.deepPurple),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickDate,
              child: const Text("Select Date"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickTime,
              child: const Text("Select Time"),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _confirmBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text("Confirm Booking"),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              "Previous Bookings:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _bookings.isEmpty
                  ? const Text("No previous bookings yet.")
                  : ListView.builder(
                      itemCount: _bookings.length,
                      itemBuilder: (context, i) {
                        final booking = _bookings[i];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.event, color: Colors.deepPurple),
                            title: Text(booking['formatted']),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
