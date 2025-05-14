// lib/handlers/stats_handler.dart
import 'package:shelf/shelf.dart';

import '../database/database.dart';

class StatsHandler {
  final Database db;
  StatsHandler(this.db);

  Future<Response> getDeliveriesCount(Request req) async {
    final result =
        await db.connection.execute('SELECT COUNT(*) FROM deliveries');
    return Response.ok(result.first[0].toString());
  }

  Future<Response> getRoutesCount(Request req) async {
    final result = await db.connection.execute('SELECT COUNT(*) FROM routes');
    return Response.ok(result.first[0].toString());
  }

  Future<Response> getVehiclesInTransit(Request req) async {
    final result = await db.connection.execute('''
      SELECT COUNT(*) FROM vehicles WHERE status = 'в пути'
    ''');
    return Response.ok(result.first[0].toString());
  }
}
