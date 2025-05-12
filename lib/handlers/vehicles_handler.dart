import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';

class VehiclesHandler {
  final Database db;

  VehiclesHandler(this.db);

  // Получить все транспортные средства
  Future<Response> getAll(Request req) async {
    final result = await db.connection.execute(
        'SELECT id, license_plate, model, capacity, status FROM Vehicles');

    final vehicles = result
        .map((row) => {
              'id': row[0],
              'license_plate': row[1],
              'model': row[2],
              'capacity': row[3],
              'status': row[4],
            })
        .toList();

    return Response.ok(
      jsonEncode(vehicles),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Получить одно ТС с загрузкой
  Future<Response> getById(Request req, String id) async {
    final result = await db.connection.execute(
      Sql.named('SELECT * FROM Vehicles WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );

    if (result.isEmpty) {
      return Response.notFound('ТС не найдено');
    }

    final vehicle = result.first;

    final cargoResult = await db.connection.execute(
      Sql.named('''
        SELECT SUM(c.quantity) FROM Cargo c
        JOIN Deliveries d ON c.delivery_id = d.id
        WHERE d.vehicle_id = @id AND d.status != 'доставлено'
      '''),
      parameters: {'id': int.parse(id)},
    );

    final currentLoad = cargoResult.first[0] ?? 0;

    final data = {
      'id': vehicle[0],
      'license_plate': vehicle[1],
      'model': vehicle[2],
      'capacity': vehicle[3],
      'status': vehicle[4],
      'current_load': currentLoad
    };

    return Response.ok(
      jsonEncode(data),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
