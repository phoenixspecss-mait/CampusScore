import 'dart:convert';
import 'dart:io';

void main() async {
  final url = Uri.parse('https://campusscore.onrender.com/simulate');
  final request = await HttpClient().postUrl(url);
  request.headers.set('Content-Type', 'application/json');
  
  final body = jsonEncode({
    'AMT_INCOME_TOTAL': 45000.0,
    'NAME_EDUCATION_TYPE': 'Secondary / secondary special',
    'AGE_YEARS': 20,
    'fee_payment_punctuality': 0.8 * 100,
    'subscription_regularity': 0.8 * 100,
    'savings_consistency': 0.5 * 100,
    'gig_income_stability': (300.0 / 1000) * 100,
    'trust_circle_vouch_score': (1.0 / 3.0) * 100,
    'AMT_CREDIT': 0,
    'on_time_repayment_rate': 0,
    'is_returning_applicant': 0,
  });
  
  request.write(body);
  final response = await request.close();
  final responseBody = await response.transform(utf8.decoder).join();
  print('Status: ${response.statusCode}');
  print('Body: $responseBody');
}
