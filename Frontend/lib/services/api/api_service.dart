import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  //cd Documents/CampusScore/CsScore-backend
  //python3 -m uvicorn main:app --reload --host 127.0.0.1 --port 8000

  //python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000

  // TODO(Deployment): Uncomment and update this URL once backend is on Render!
  // static const String _baseUrl = 'https://your-backend.onrender.com';

  static const String _baseUrl = 'http://192.168.31.176:8000';
  //static const String _baseUrl = 'http://10.0.2.2:8000';

  Future<Map<String, dynamic>> calculateScore({
    required double amtIncomeTotal,
    required double daysEmployed,
    required double savingsCadence,
    required double trustCircleVouch,
    required double feePunctuality,
  }) async {
    final url = Uri.parse('$_baseUrl/score');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'AMT_INCOME_TOTAL': amtIncomeTotal,
          'DAYS_EMPLOYED': daysEmployed,
          'savings_cadence': savingsCadence,
          'trust_circle_vouch': trustCircleVouch,
          'fee_punctuality': feePunctuality,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to calculate score: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error connecting to model API: $e');
    }
  }

  Future<Map<String, dynamic>> uploadStatement({
    required String filePath,
    required double trustCircleVouch,
  }) async {
    final url = Uri.parse('$_baseUrl/upload_statement');
    try {
      var request = http.MultipartRequest('POST', url);

      // Add the file
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

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
