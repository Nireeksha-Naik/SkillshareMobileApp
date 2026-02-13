import 'package:flutter/material.dart';
import 'app_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = TextEditingController();
  final _workerController = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  bool _loading = true;
  double _rating = 5.0; // ⭐ default middle rating

  @override
  void initState() {
    super.initState();
    _loading = false;
  }

  Future<void> _loadFor(String name) async {
    setState(() => _loading = true);
    final items = await AppData.loadFeedbacks(name);
    setState(() {
      _list = items;
      _loading = false;
    });
  }

  // 🧠 AI summarization after submitting feedback
  Future<void> _summarizeWorkerFeedback(String workerName) async {
    try {
      final feedbackSnap = await FirebaseFirestore.instance
          .collection('feedbacks')
          .where('worker', isEqualTo: workerName)
          .get();

      if (feedbackSnap.docs.isEmpty) return;

      List<String> comments = [];
      double totalRating = 0;
      int count = 0;

      for (var doc in feedbackSnap.docs) {
        final data = doc.data();
        if (data['text'] != null && data['text'].toString().trim().isNotEmpty) {
          comments.add(data['text']);
        }
        if (data['rating'] != null) {
          totalRating += (data['rating'] as num).toDouble();
          count++;
        }
      }

      final avgRating =
          count > 0 ? (totalRating / count).toStringAsFixed(1) : "N/A";
      final combinedFeedback = comments.join(". ");

      if (combinedFeedback.isEmpty) return;

      // ✅ Directly use your OpenAI API key here
      const apiKey =
          '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';

      const endpoint = "https://api.openai.com/v1/chat/completions";

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
        },
        body: jsonEncode({
          "model": "gpt-4o-mini",
          "messages": [
            {
              "role": "system",
              "content":
                  "Summarize the following customer feedbacks about a worker in 1–2 sentences. Keep it brief, professional, and positive."
            },
            {"role": "user", "content": combinedFeedback}
          ],
          "max_tokens": 70,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['choices'][0]['message']['content'] ?? '';

        // 🔹 Save summary + avgRating to Firestore
        await FirebaseFirestore.instance
            .collection('summaries')
            .doc(workerName)
            .set({
          'worker': workerName,
          'avgRating': avgRating,
          'summary': summary,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print("✅ AI summary updated for $workerName: $summary");
      } else {
        print("❌ OpenAI API Error: ${response.body}");
      }
    } catch (e) {
      print("❌ Summarization failed: $e");
    }
  }

  Future<void> _submit(String name) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final entry = {
      'text': text,
      'rating': _rating, // ⭐ include rating
      'ts': DateTime.now().toIso8601String(),
      'worker': name,
      'worker_lower': name.toLowerCase(),
    };

    await AppData.addFeedback(name, entry);
    _controller.clear();
    await _loadFor(name);

    // 🧠 Generate AI summary
    await _summarizeWorkerFeedback(name);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Feedback saved successfully!')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _workerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: const Text('Feedback'), backgroundColor: Colors.deepPurple),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _workerController,
              decoration: const InputDecoration(
                labelText: 'Worker name (for feedback)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (_workerController.text.trim().isNotEmpty) {
                      _loadFor(_workerController.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Load'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _workerController.clear();
                    setState(() => _list = []);
                  },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Write feedback',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // ⭐ Rating slider
            Column(
              children: [
                Text('Rate this worker: ${_rating.toStringAsFixed(1)} / 10'),
                Slider(
                  value: _rating,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: Colors.deepPurple,
                  label: _rating.toStringAsFixed(1),
                  onChanged: (v) => setState(() => _rating = v),
                ),
              ],
            ),

            ElevatedButton(
              onPressed: () {
                final name = _workerController.text.trim();
                if (name.isNotEmpty) _submit(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _list.length,
                      itemBuilder: (context, i) {
                        final it = _list[i];
                        final dt =
                            DateTime.tryParse(it['ts'] ?? '')?.toLocal().toString() ?? '';
                        return Card(
                          child: ListTile(
                            title: Text(it['text'] ?? ''),
                            subtitle: Text('⭐ ${it['rating'] ?? '-'}  |  $dt'),
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
