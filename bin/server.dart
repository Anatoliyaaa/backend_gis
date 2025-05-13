import 'dart:io';

import 'package:dotenv/dotenv.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/database/database.dart';
import '../lib/routes/api_routes.dart';
import '../lib/services/otp_scheduler.dart';

void main() async {
  final env = DotEnv()..load();
  final db = Database();
  await db.open();

  // ⏰ Запуск обновления OTP-кодов
  startOtpScheduler(db.connection);

  final router = Router()..mount('/api/', apiRoutes(db, env));

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await serve(handler, InternetAddress.anyIPv4, 8081);

  print('Server running at ${server.address.host}:${server.port}');
}
