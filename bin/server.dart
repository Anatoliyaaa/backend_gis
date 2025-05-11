import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

import '../lib/database/database.dart';
import '../lib/routes/api_routes.dart';

void main() async {
  final db = Database();
  await db.open(); // <-- теперь await здесь корректен и обязателен

  final router = Router()..mount('/api/', apiRoutes(db));

  final handler = Pipeline().addMiddleware(logRequests()).addHandler(router);

  final server = await serve(handler, InternetAddress.anyIPv4, 8081);

  print('Server running at ${server.address.host}:${server.port}');
}
