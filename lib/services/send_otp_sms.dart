import 'dart:convert';

import 'package:http/http.dart' as http;

Future<void> sendOtpSms(String phone, String otp, String apiKey) async {
  final url = Uri.parse(
      'https://sms.ru/sms/send?api_id=$apiKey&to=$phone&msg=Ваш+код:+$otp&json=1');

  try {
    final response = await http.get(url);
    final result = jsonDecode(response.body);
    if (result['status'] == 'OK') {
      print('SMS отправлено на $phone');
    } else {
      print('Ошибка SMS: ${result['status_text']}');
    }
  } catch (e) {
    print('Ошибка отправки SMS: $e');
  }
}
