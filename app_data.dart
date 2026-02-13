import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class AppData {
  static final _db = FirebaseFirestore.instance;

  static const _profileKey = 'profile';
  static const _profilesKey = 'profiles';
  static String _bookingsKey(String name) => 'bookings_$name';
  static String _feedbacksKey(String name) => 'feedbacks_$name';

  /// ---------------- PROFILE ----------------
  static Future<void> saveProfile(Map<String, dynamic> profile) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // 🧹 Clean Firestore objects (can't be JSON encoded)
      final cleanProfile = <String, dynamic>{};
      profile.forEach((key, value) {
        if (value is! FieldValue &&
            value is! Timestamp &&
            value is! DocumentReference) {
          cleanProfile[key] = value;
        }
      });

      // ✅ Save locally
      await prefs.setString(_profileKey, jsonEncode(cleanProfile));

      // ✅ Update local list of profiles
      final existing = prefs.getString(_profilesKey);
      List<Map<String, dynamic>> profiles = [];
      if (existing != null) {
        final list = jsonDecode(existing);
        if (list is List) {
          profiles = list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }

      final id = cleanProfile['email'] ?? cleanProfile['name'];
      final index = profiles.indexWhere((p) => (p['email'] ?? p['name']) == id);
      if (index >= 0) {
        profiles[index] = cleanProfile;
      } else {
        profiles.add(cleanProfile);
      }
      await prefs.setString(_profilesKey, jsonEncode(profiles));

      // ✅ Save to Firestore
      if (id != null && id.toString().isNotEmpty) {
        final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
        await _db.collection('profiles').doc(safeId).set(
          {
            ...cleanProfile,
            'createdAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
        print("✅ Profile saved to Firestore: $safeId");
      }
    } catch (e, st) {
      print("❌ saveProfile failed: $e\n$st");
    }
  }

  /// ---------------- LOAD PROFILE ----------------
  static Future<Map<String, dynamic>?> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_profileKey);
    if (data != null) return jsonDecode(data) as Map<String, dynamic>;

    final snapshot = await _db.collection('profiles').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> loadAllProfiles() async {
    try {
      final snap = await _db.collection('profiles').get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('⚠️ Firestore loadAllProfiles failed: $e');
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_profilesKey);
      if (data == null) return [];
      final list = jsonDecode(data);
      if (list is List) {
        return list.map((e) => Map<String, dynamic>.from(e)).toList();
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAllWorkers() async {
    try {
      final snap = await _db
          .collection('profiles')
          .where('isWorker', isEqualTo: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('⚠️ Firestore getAllWorkers failed: $e');
      final all = await loadAllProfiles();
      return all.where((p) => p['isWorker'] == true).toList();
    }
  }

  /// ---------------- BOOKINGS ----------------
  static Future<void> addBooking(
      String workerName, Map<String, dynamic> booking) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _bookingsKey(workerName);

    try {
      // 🧹 Clean invalid Firestore-only objects
      final cleanBooking = <String, dynamic>{};
      booking.forEach((k, v) {
        if (v != null &&
            v is! FieldValue &&
            v is! Timestamp &&
            v is! DocumentReference) {
          cleanBooking[k] = v;
        }
      });

      // ✅ Save locally
      List<String> bookings = prefs.getStringList(key) ?? [];
      bookings.add(jsonEncode(cleanBooking));
      await prefs.setStringList(key, bookings);

      // ✅ Save to Firestore with timestamp
      await _db.collection('bookings').add({
        'worker': workerName,
        ...cleanBooking,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Booking added successfully for $workerName");
    } catch (e, st) {
      print("❌ Firestore addBooking failed: $e\n$st");
    }
  }

  static Future<List<Map<String, dynamic>>> loadBookings(
      String workerName) async {
    try {
      final snap = await _db
          .collection('bookings')
          .where('worker', isEqualTo: workerName)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('⚠️ Firestore loadBookings failed: $e');
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookingsKey(workerName)) ?? [];
      return list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    }
  }

  /// ---------------- FEEDBACK ----------------
  static Future<void> addFeedback(
      String workerName, Map<String, dynamic> feedback) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _feedbacksKey(workerName);

    try {
      // 🧹 Clean data before saving
      final cleanFeedback = <String, dynamic>{};
      feedback.forEach((k, v) {
        if (v != null &&
            v is! FieldValue &&
            v is! Timestamp &&
            v is! DocumentReference) {
          cleanFeedback[k] = v;
        }
      });

      // ✅ Save locally
      List<String> feedbacks = prefs.getStringList(key) ?? [];
      feedbacks.add(jsonEncode(cleanFeedback));
      await prefs.setStringList(key, feedbacks);

      // ✅ Save to Firestore
      await _db.collection('feedbacks').add({
        'worker': workerName,
        ...cleanFeedback,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("✅ Feedback added for $workerName");
    } catch (e, st) {
      print("❌ Firestore addFeedback failed: $e\n$st");
    }
  }

  static Future<List<Map<String, dynamic>>> loadFeedbacks(
      String workerName) async {
    try {
      final snap = await _db
          .collection('feedbacks')
          .where('worker', isEqualTo: workerName)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    } catch (e) {
      print('⚠️ Firestore loadFeedbacks failed: $e');
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_feedbacksKey(workerName)) ?? [];
      return list.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();
    }
  }

  /// ---------------- CLEAR ALL ----------------
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🧹 Cleared all local data");
  }

  /// ---------------- EMAIL SIMULATION ----------------
  static Future<void> sendMailToWorker(
      String workerName, Map<String, dynamic> booking) async {
    final date = booking['date'] ?? '';
    final time = booking['time'] ?? '';
    print('📧 Email sent to $workerName: New booking on $date at $time');
  }

  // ------------------------------------------------------------------
  // ✅ HELPERS FOR LOGIN/SIGNUP WITHOUT AUTH
  // ------------------------------------------------------------------
  static Future<void> saveActiveProfile({
    required String role, // 'user' or 'worker'
    required Map<String, dynamic> profile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_role', role);
    await prefs.setString('active_profile', jsonEncode(profile));
  }

  static Future<Map<String, dynamic>?> loadActiveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('active_profile');
    if (data == null) return null;
    return Map<String, dynamic>.from(jsonDecode(data));
  }

  static Future<String?> getActiveRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('active_role');
  }

  static Future<void> clearActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_role');
    await prefs.remove('active_profile');
  }
}
