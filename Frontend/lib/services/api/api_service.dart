import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'https://campusscore.onrender.com';

  Future<Map<String, dynamic>> calculateScore({
    required double amtIncomeTotal,
    required double daysEmployed,
    required double savingsCadence,
    required double trustCircleVouch,
    required double feePunctuality,
  }) async {
    final url = Uri.parse('$_baseUrl/simulate'); // Using /simulate instead of /score just in case
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'AMT_INCOME_TOTAL': amtIncomeTotal,
          'NAME_EDUCATION_TYPE': 'Secondary / secondary special',
          'AGE_YEARS': 20, // Default for simulator
          'fee_payment_punctuality': feePunctuality * 100, // Slider is 0-1, backend expects ~0-100
          'subscription_regularity': feePunctuality * 100, // Approximating using fee punctuality
          'savings_consistency': savingsCadence * 100, // Slider is 0-1, backend expects ~0-100
          'gig_income_stability': (daysEmployed / 1000) * 100, // Slider is 0-1000, map to 0-100
          'trust_circle_vouch_score': (trustCircleVouch / 3.0) * 100, // Slider is 0-3, map to 0-100
          'AMT_CREDIT': 0,
          'on_time_repayment_rate': 0,
          'is_returning_applicant': 0,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to calculate score: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error connecting to model API: $e');
    }
  }

  Future<Map<String, dynamic>> uploadStatement({
    required List<int> fileBytes,
    required String fileName,
    required double trustCircleVouch,
  }) async {
    final url = Uri.parse('$_baseUrl/upload_statement');
    try {
      var request = http.MultipartRequest('POST', url);

      // Add the file from bytes (works on Web and Mobile)
      request.files.add(
        http.MultipartFile.fromBytes('file', fileBytes, filename: fileName),
      );

      // Add the other form field
      request.fields['trust_circle_vouch'] = trustCircleVouch.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(
          'Failed to upload statement: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading statement: $e');
    }
  }
}
