import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';

class TrafficHandler {
  final Database db;

  TrafficHandler(this.db);

  // Получить все условия
  Future<Response> getAll(Request req) async {
    final result = await db.connection.execute('''
      SELECT t.id, t.route_id, t.condition, t.created_at,
            s.name, e.name
      FROM TrafficConditions t
      JOIN Routes r ON t.route_id = r.id
      JOIN Locations s ON r.start_location_id = s.id
      JOIN Locations e ON r.end_location_id = e.id
      ORDER BY t.created_at DESC
    ''');

    final traffic = result
        .map((row) => {
              'id': row[0],
              'route_id': row[1],
              'condition': row[2],
              'created_at': row[3].toString(),
              'route': {
                'start': row[4],
                'end': row[5],
              },
            })
        .toList();

    return Response.ok(jsonEncode(traffic),
        headers: {'Content-Type': 'application/json'});
  }

  // Получить условие по маршруту
  Future<Response> getByRoute(Request req, String routeId) async {
    final result = await db.connection.execute(
      Sql.named('''
        SELECT id, route_id, condition, created_at
        FROM TrafficConditions
        WHERE route_id = @route
        ORDER BY created_at DESC
        LIMIT 1
      '''),
      parameters: {'route': int.parse(routeId)},
    );

    if (result.isEmpty) {
      return Response.notFound('Нет данных по маршруту');
    }

    final row = result.first;
    final data = {
      'id': row[0],
      'route_id': row[1],
      'condition': row[2],
      'created_at': row[3].toString(),
    };

    return Response.ok(jsonEncode(data),
        headers: {'Content-Type': 'application/json'});
  }

  // Добавить новое состояние
  Future<Response> create(Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final routeId = payload['route_id'];
    final condition = payload['condition'];

    if (routeId == null || condition == null) {
      return Response(400, body: 'Нужно указать route_id и condition');
    }

    await db.connection.execute(
      Sql.named('''
        INSERT INTO TrafficConditions (route_id, condition)
        VALUES (@route, @condition)
      '''),
      parameters: {
        'route': routeId,
        'condition': condition,
      },
    );

    return Response.ok('Добавлено новое состояние дороги');
  }
}
