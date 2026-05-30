import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var res = await http.post(
    Uri.parse('http://localhost:5000/api/auth/phone-login-request'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'phone': '0540584453'})
  );
  print('Status: ${res.statusCode}');
  print('Body: ${res.body}');
  try {
    var decoded = jsonDecode(res.body);
    print('Decoded message: ${decoded['message']}');
  } catch (e) {
    print('Error decoding: $e');
  }
}
