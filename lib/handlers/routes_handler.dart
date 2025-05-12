import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';

class RoutesHandler {
  final Database db;

  RoutesHandler(this.db);

  // Создание маршрута
  Future<Response> create(Request req) async {
    final payload = jsonDecode(await req.readAsString());

    final startId = payload['start_location_id'];
    final endId = payload['end_location_id'];
    final distance = payload['distance'];
    final time = payload['estimated_time'];

    if (startId == null || endId == null || distance == null || time == null) {
      return Response(400, body: 'Некорректные данные');
    }

    await db.connection.execute(
      Sql.named('''
        INSERT INTO Routes (start_location_id, end_location_id, distance, estimated_time)
        VALUES (@start, @end, @distance, @time)
      '''),
      parameters: {
        'start': startId,
        'end': endId,
        'distance': distance,
        'time': time,
      },
    );

    return Response.ok('Маршрут создан');
  }

  // Получение всех маршрутов
  Future<Response> getAll(Request req) async {
    final result = await db.connection.execute('''
      SELECT r.id,
            r.start_location_id, s.name, s.latitude, s.longitude,
            r.end_location_id, e.name, e.latitude, e.longitude,
            r.distance, r.estimated_time
      FROM Routes r
      JOIN Locations s ON r.start_location_id = s.id
      JOIN Locations e ON r.end_location_id = e.id
      ORDER BY r.id DESC
      ''');

    final routes = result
        .map((row) => {
              'id': row[0],
              'start_location': {
                'id': row[1],
                'name': row[2],
                'latitude': row[3],
                'longitude': row[4],
              },
              'end_location': {
                'id': row[5],
                'name': row[6],
                'latitude': row[7],
                'longitude': row[8],
              },
              'distance': row[9],
              'estimated_time': row[10],
            })
        .toList();

    return Response.ok(
      jsonEncode(routes),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Обновление маршрута по ID
  Future<Response> update(Request req, String id) async {
    final payload = jsonDecode(await req.readAsString());
    final startId = payload['start_location_id'];
    final endId = payload['end_location_id'];
    final distance = payload['distance'];
    final time = payload['estimated_time'];

    if (startId == null || endId == null || distance == null || time == null) {
      return Response(400, body: 'Некорректные данные');
    }

    await db.connection.execute(
      Sql.named('''
        UPDATE Routes SET
          start_location_id = @start,
          end_location_id = @end,
          distance = @distance,
          estimated_time = @time,
          updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'start': startId,
        'end': endId,
        'distance': distance,
        'time': time,
        'id': int.parse(id),
      },
    );

    return Response.ok('Маршрут обновлён');
  }

  // Удаление маршрута по ID
  Future<Response> delete(Request req, String id) async {
    await db.connection.execute(
      Sql.named('DELETE FROM Routes WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );

    return Response.ok('Маршрут удалён');
  }
}
