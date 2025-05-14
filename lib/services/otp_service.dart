import 'dart:math';

import 'package:dotenv/dotenv.dart' show DotEnv;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:postgres/postgres.dart';

import 'send_otp_sms.dart';

final env = DotEnv()..load(['.env']); // Загружаем .env глобально один раз

Future<String> generateOtp() async {
  final rng = Random();
  return List.generate(6, (_) => rng.nextInt(10)).join();
}

Future<void> sendOtpToEmail({
  required Connection connection,
  required String username,
  required String email,
  required String? phone,
}) async {
  final otp = await generateOtp();
  final now = DateTime.now();

  await connection.execute(
    Sql.named('''
      UPDATE Users
      SET otp_code = @otp, otp_created_at = @created_at
      WHERE username = @username
    '''),
    parameters: {
      'otp': otp,
      'created_at': now.toUtc(),
      'username': username,
    },
  );
  //print('Содержимое .env: ${env.map}');
  //final env2 = DotEnv()..load();
  //print('Содержимое .env: ${env2.map}');
  // EMAIL
  final smtpServer = SmtpServer(
    env['SMTP_HOST'] ?? 'smtp.yandex.ru',
    port: int.tryParse(env['SMTP_PORT'] ?? '') ?? 587,
    ssl: (env['SMTP_SSL'] ?? 'false') == 'true',
    ignoreBadCertificate: true,
    username: env['SMTP_USER'] ?? '',
    password: env['SMTP_PASS'] ?? '',
  );

  final message = Message()
    ..from = Address(env['SMTP_USER']!, 'OTP Service')
    ..recipients.add(email)
    ..subject = 'Ваш код OTP'
    ..text = 'Ваш код подтверждения: $otp (действителен 1 минуту).';

  try {
    final sendReport = await send(message, smtpServer);
    print('Email отправлен: $sendReport');
  } catch (e) {
    //print('Ошибка отправки Email: $e');
  }

  // SMS
  if (phone != null && phone.isNotEmpty) {
    final smsApiKey = env['SMS_API_KEY'];
    if (smsApiKey != null && smsApiKey.isNotEmpty) {
      await sendOtpSms(phone, otp, smsApiKey);
    } else {
      print('SMS API ключ не найден. SMS не отправлено.');
    }
  }
}
