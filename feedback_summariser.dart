// lib/feedback_summariser.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SummaryResult {
  final String summary;
  final double score;
  const SummaryResult({required this.summary, required this.score});
}

class FeedbackSummariser {
  final String apiKey; // ⚠️ Keep your API key secure

  FeedbackSummariser({required this.apiKey});

  Future<SummaryResult> summarise({
    required String workerName,
    required List<String> comments,
  }) async {
    if (comments.isEmpty) {
      return const SummaryResult(summary: '', score: 0.0);
    }

    final prompt = '''
You are given customer feedback comments for a worker named "$workerName".

Feedbacks:
${comments.map((c) => "- $c").join("\n")}

Task:
1) Write a 2-3 sentence summary highlighting professionalism, punctuality, and reliability.
2) Give an overall rating (0.0 to 10.0).

Return STRICT JSON only:
{"summary": "...", "score": 8.9}
''';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    if (response.statusCode != 200) {
      print("❌ Gemini API Error: ${response.body}");
      return const SummaryResult(summary: '', score: 0.0);
    }

    final data = jsonDecode(response.body);

    String textOutput = '';
    try {
      final candidates = data['candidates'] as List?;
      if (candidates != null && candidates.isNotEmpty) {
        final content = candidates.first['content'];
        final parts = content['parts'] as List?;
        if (parts != null && parts.isNotEmpty) {
          textOutput = parts.first['text']?.toString() ?? '';
        }
      }
    } catch (_) {}

    final jsonText = _extractJson(textOutput);
    if (jsonText.isEmpty) return const SummaryResult(summary: '', score: 0.0);

    try {
      final parsed = jsonDecode(jsonText);
      final summary = (parsed['summary'] ?? '').toString();
      final score = double.tryParse(parsed['score']?.toString() ?? '') ?? 0.0;
      return SummaryResult(summary: summary, score: score);
    } catch (e) {
      print("⚠️ JSON parsing error: $e");
      return const SummaryResult(summary: '', score: 0.0);
    }
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) {
      return text.substring(start, end + 1);
    }
    return '';
  }
}
