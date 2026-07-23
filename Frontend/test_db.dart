import 'dart:io';
void main() async {
  var url1 = 'https://campusscore-7a0c0-default-rtdb.firebaseio.com/.json';
  var url2 = 'https://campusscore-7a0c0-default-rtdb.asia-southeast1.firebasedatabase.app/.json';
  
  try {
    var res = await HttpClient().getUrl(Uri.parse(url1));
    var req = await res.close();
    print('US Region: ${req.statusCode}');
  } catch (e) {
    print('US Region failed: $e');
  }
  
  try {
    var res2 = await HttpClient().getUrl(Uri.parse(url2));
    var req2 = await res2.close();
    print('Asia Region: ${req2.statusCode}');
  } catch (e) {
    print('Asia Region failed: $e');
  }
}
