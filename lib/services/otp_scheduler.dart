import 'dart:async';
import 'dart:math';

import 'package:postgres/postgres.dart';

Future<String> generateOtp() async {
  final rng = Random();
  return List.generate(6, (_) => rng.nextInt(10)).join();
}

Future<void> updateOtpForAllUsers(Connection connection) async {
  final result = await connection
      .execute('SELECT username FROM Users WHERE email IS NOT NULL');

  for (final row in result) {
    final username = row[0];
    final otp = await generateOtp();
    final now = DateTime.now().toUtc();

    await connection.execute(
      '''UPDATE Users
          SET otp_code = @otp, otp_created_at = @now
          WHERE username = @username''',
      parameters: {
        'otp': otp,
        'now': now,
        'username': username,
      },
    );

    print('OTP обновлён для $username: $otp');
    // опционально — отправка по email/sms
  }
}

void startOtpScheduler(Connection connection) {
  Timer.periodic(const Duration(minutes: 5), (_) async {
    print('Обновление OTP для всех пользователей...');
    await updateOtpForAllUsers(connection);
  });
}
