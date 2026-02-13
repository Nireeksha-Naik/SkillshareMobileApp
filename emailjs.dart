import 'dart:convert';
import 'package:http/http.dart' as http;

// 🔐 EmailJS credentials (YOUR ACTUAL IDs)
const String serviceId = 'service_jzl9c7g';
const String publicKey = 'D6Ia66wBvJ4HsKKkg';

// SINGLE TEMPLATE used for ALL EMAILS
const String templateId = 'template_5s5zx7o';

/// ----------------------------------------------------------------------
/// 1️⃣ Send Booking Email → to Worker
/// ----------------------------------------------------------------------
Future<void> sendBookingEmail({
  required String workerEmail,
  required String workerName,
  required String userName,
  required String bookingDate,
  String? customerEmail,
}) async {
  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        // 🔥 Required by your new template
        'email_title': "📢 New Booking Received!",
        'email_message': "You have received a booking from $userName.",
        'title_color': "#000000",

        // 🔥 Booking details
        'customer_name': userName,
        'worker_name': workerName,
        'customer_email': customerEmail ?? "",
        'booking_time': bookingDate,

        // 🔥 Worker MUST receive email → THIS IS IMPORTANT!
        'to_email': workerEmail,

        // 🔥 Template requires these (even if blank)
        'date': "",
        'time': "",
      },
    }),
  );

  print("EMAILJS RESPONSE: ${response.body}");

  if (response.statusCode == 200) {
    print('📧 Booking email sent to worker');
  } else {
    print('❌ Booking email failed: ${response.body}');
  }
}


/// ----------------------------------------------------------------------
/// 2️⃣ Send Password Recovery Email (Separate Template)
/// ----------------------------------------------------------------------
Future<void> sendPasswordRecoveryEmail({
  required String toEmail,
  required String userName,
  required String password,
}) async {
  const passwordTemplateId = 'template_v13j5ew';

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'service_id': serviceId,
      'template_id': passwordTemplateId,
      'user_id': publicKey,
      'template_params': {
        'to_email': toEmail,
        'to_name': userName,
        'user_password': password,
      },
    }),
  );

  if (response.statusCode == 200) {
    print('📧 Password email sent');
  } else {
    print('❌ Password email failed: ${response.body}');
  }
}

/// ----------------------------------------------------------------------
/// 3️⃣ Send Booking Status Email → to User (Accepted / Rejected)
/// ----------------------------------------------------------------------
Future<void> sendStatusEmail({
  required String customerEmail,
  required String customerName,
  required String workerName,
  required String date,
  required String time,
  required String status, // accepted / rejected
}) async {
  String title = "";
  String message = "";
  String color = "";

  if (status == "accepted") {
    title = "✔ Booking Accepted";
    message = "Your booking has been accepted by $workerName.";
    color = "green";
  } else if (status == "rejected") {
    title = "✖ Booking Rejected";
    message = "Your booking request was declined by $workerName.";
    color = "red";
  }

  final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

  final response = await http.post(
    url,
    headers: {
      'origin': 'http://localhost',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'service_id': serviceId,
      'template_id': templateId,
      'user_id': publicKey,
      'template_params': {
        'email_title': title,
        'email_message': message,
        'title_color': color,

        'customer_name': customerName,
        'worker_name': workerName,
        'customer_email': customerEmail,
        'booking_time': "",
        'date': date,
        'time': time,

        // 🔥 IMPORTANT! REQUIRED FOR EMAIL TO SEND
        'to_email': customerEmail,
      },
    }),
  );

  print("EMAILJS RESPONSE: ${response.body}");

  if (response.statusCode == 200) {
    print('📧 Status email sent ($status)');
  } else {
    print('❌ Status email failed: ${response.body}');
  }
}

