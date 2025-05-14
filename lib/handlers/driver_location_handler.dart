import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';

class DriverLocationHandler {
  final Database db;

  DriverLocationHandler(this.db);

  Future<Response> updateLocation(Request req) async {
    final body = jsonDecode(await req.readAsString());
    final driverId = body['driver_id'];
    final lat = body['latitude'];
    final lon = body['longitude'];

    if (driverId == null || lat == null || lon == null) {
      return Response(400, body: 'Недостаточно данных');
    }

    await db.connection.execute(
      Sql.named('''
        INSERT INTO DriverPositions (driver_id, latitude, longitude, updated_at)
        VALUES (@driver_id, @lat, @lon, CURRENT_TIMESTAMP)
        ON CONFLICT (driver_id) DO UPDATE
        SET latitude = @lat, longitude = @lon, updated_at = CURRENT_TIMESTAMP
      '''),
      parameters: {
        'driver_id': driverId,
        'lat': lat,
        'lon': lon,
      },
    );

    return Response.ok('Координаты обновлены');
  }

  Future<Response> getAllDriverPositions(Request req) async {
    final result = await db.connection.execute('''
      SELECT d.driver_id, u.username, d.latitude, d.longitude, d.updated_at
      FROM DriverPositions d
      JOIN Users u ON u.id = d.driver_id
    ''');

    final drivers = result
        .map((row) => {
              'driver_id': row[0],
              'username': row[1],
              'latitude': row[2],
              'longitude': row[3],
              'updated_at': row[4].toString(),
            })
        .toList();

    return Response.ok(
      jsonEncode(drivers),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
