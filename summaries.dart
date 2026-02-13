import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'feedback_summariser.dart';

class SummariesPage extends StatefulWidget {
  const SummariesPage({super.key});

  @override
  State<SummariesPage> createState() => _SummariesPageState();
}

class _SummariesPageState extends State<SummariesPage> {
  final _workerController = TextEditingController();
  String? _summary;
  double? _rating;
  bool _loading = false;
  List<String> _feedbacks = [];

  final _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _workerController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbacks(String worker) async {
    setState(() => _loading = true);
    try {
      // 🔹 Use lowercase field for consistency
      final snap = await _db
          .collection('feedbacks')
          .where('worker_lower', isEqualTo: worker.toLowerCase())
          .get();

      _feedbacks = snap.docs.map((d) => d['text'].toString()).toList();

      final summaryDoc = await _db.collection('summaries').doc(worker).get();

      setState(() {
        _summary = summaryDoc.data()?['summary'];
        // 🔹 Match field name to 'avgRating' instead of 'score'
        _rating = double.tryParse(summaryDoc.data()?['avgRating']?.toString() ?? '');
      });
    } catch (e) {
      print("⚠️ Error loading feedbacks: $e");
    }
    setState(() => _loading = false);
  }

  Future<void> _generateSummary(String worker) async {
    if (_feedbacks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No feedbacks found for this worker')),
      );
      return;
    }

    setState(() => _loading = true);

    const apiKey =
        "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";

    final summariser = FeedbackSummariser(apiKey: apiKey);

    final result =
        await summariser.summarise(workerName: worker, comments: _feedbacks);

    await _db.collection('summaries').doc(worker).set({
      'worker': worker,
      'avgRating': result.score, // 🔹 match field name
      'summary': result.summary,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _summary = result.summary;
      _rating = result.score;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Worker Summaries'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _workerController,
              decoration: const InputDecoration(
                labelText: 'Enter worker name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    final worker = _workerController.text.trim();
                    if (worker.isNotEmpty) _loadFeedbacks(worker);
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
                    final worker = _workerController.text.trim();
                    if (worker.isNotEmpty) _generateSummary(worker);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Summarize'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_loading)
              const CircularProgressIndicator()
            else if (_summary != null)
              Card(
                color: Colors.deepPurple.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🧠 Summary",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(_summary ?? ''),
                      if (_rating != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "⭐ Rating: ${_rating!.toStringAsFixed(1)}/10",
                            style: const TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
