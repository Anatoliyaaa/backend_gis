import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';

class DeliveriesHandler {
  final Database db;

  DeliveriesHandler(this.db);

  // Получить список доставок
  Future<Response> getAll(Request req) async {
    final result = await db.connection.execute('''
      SELECT d.id, d.delivery_date, d.status,
            u.id, u.username,
            v.id, v.model, v.license_plate,
            r.id, s.name, s.latitude, s.longitude,
            e.name, e.latitude, e.longitude,
            COALESCE(string_agg(c.type || ' (' || c.quantity || ' ' || c.unit || ')', ', '), '') AS cargo_summary
      FROM Deliveries d
      JOIN Users u ON d.driver_id = u.id
      JOIN Vehicles v ON d.vehicle_id = v.id
      JOIN Routes r ON d.route_id = r.id
      JOIN Locations s ON r.start_location_id = s.id
      JOIN Locations e ON r.end_location_id = e.id
      LEFT JOIN Cargo c ON d.id = c.delivery_id
      GROUP BY d.id, u.id, v.id, r.id, s.id, e.id
      ORDER BY d.delivery_date DESC
      ''');

    final deliveries = result
        .map((row) => {
              'id': row[0],
              'delivery_date': row[1].toString(),
              'status': row[2],
              'driver': {
                'id': row[3],
                'username': row[4],
              },
              'vehicle': {
                'id': row[5],
                'model': row[6],
                'license_plate': row[7],
              },
              'route': {
                'id': row[8],
                'start_location': {
                  'name': row[9],
                  'latitude': row[10],
                  'longitude': row[11],
                },
                'end_location': {
                  'name': row[12],
                  'latitude': row[13],
                  'longitude': row[14],
                },
              },
              'cargo': row[15] ?? '',
            })
        .toList();

    return Response.ok(
      jsonEncode(deliveries),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Создать доставку
  Future<Response> create(Request req) async {
    final data = jsonDecode(await req.readAsString());
    final driverId = data['driver_id'];
    final routeId = data['route_id'];
    final vehicleId = data['vehicle_id'];
    final date = data['delivery_date'];
    final status = data['status'];

    if (driverId == null ||
        routeId == null ||
        vehicleId == null ||
        date == null ||
        status == null) {
      return Response(400, body: 'Некорректные данные');
    }

    await db.connection.execute(
      Sql.named('''
        INSERT INTO Deliveries (driver_id, route_id, delivery_date, status, vehicle_id)
        VALUES (@driver, @route, @date, @status, @vehicle)
      '''),
      parameters: {
        'driver': driverId,
        'route': routeId,
        'date': DateTime.parse(date),
        'status': status,
        'vehicle': vehicleId,
      },
    );

    return Response.ok('Доставка создана');
  }

  // Обновить доставку
  Future<Response> update(Request req, String id) async {
    final data = jsonDecode(await req.readAsString());
    final driverId = data['driver_id'];
    final routeId = data['route_id'];
    final vehicleId = data['vehicle_id'];
    final date = data['delivery_date'];
    final status = data['status'];

    if (driverId == null ||
        routeId == null ||
        vehicleId == null ||
        date == null ||
        status == null) {
      return Response(400, body: 'Некорректные данные');
    }

    await db.connection.execute(
      Sql.named('''
        UPDATE Deliveries
        SET driver_id = @driver,
            route_id = @route,
            vehicle_id = @vehicle,
            delivery_date = @date,
            status = @status,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = @id
      '''),
      parameters: {
        'driver': driverId,
        'route': routeId,
        'vehicle': vehicleId,
        'date': DateTime.parse(date),
        'status': status,
        'id': int.parse(id),
      },
    );

    return Response.ok('Доставка обновлена');
  }

  // Удалить доставку
  Future<Response> delete(Request req, String id) async {
    await db.connection.execute(
      Sql.named('DELETE FROM Deliveries WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );

    return Response.ok('Доставка удалена');
  }

  Future<Response> getForDriver(Request req, String driverId) async {
    final result = await db.connection.execute(
      Sql.named('''
        SELECT d.id, d.delivery_date, d.status,
              u.id, u.username,
              v.id, v.model, v.license_plate,
              r.id, s.name, s.latitude, s.longitude,
              e.name, e.latitude, e.longitude,
              COALESCE(string_agg(c.type || ' (' || c.quantity || ' ' || c.unit || ')', ', '), '') AS cargo_summary
        FROM Deliveries d
        JOIN Users u ON d.driver_id = u.id
        JOIN Vehicles v ON d.vehicle_id = v.id
        JOIN Routes r ON d.route_id = r.id
        JOIN Locations s ON r.start_location_id = s.id
        JOIN Locations e ON r.end_location_id = e.id
        LEFT JOIN Cargo c ON d.id = c.delivery_id
        WHERE u.id = @driverId
        GROUP BY d.id, u.id, v.id, r.id, s.id, e.id
        ORDER BY d.delivery_date DESC
      '''),
      parameters: {'driverId': int.parse(driverId)},
    );

    final deliveries = result
        .map((row) => {
              'id': row[0],
              'delivery_date': row[1].toString(),
              'status': row[2],
              'driver': {
                'id': row[3],
                'username': row[4],
              },
              'vehicle': {
                'id': row[5],
                'model': row[6],
                'license_plate': row[7],
              },
              'route': {
                'id': row[8],
                'start_location': {
                  'name': row[9],
                  'latitude': row[10],
                  'longitude': row[11],
                },
                'end_location': {
                  'name': row[12],
                  'latitude': row[13],
                  'longitude': row[14],
                },
              },
              'cargo': row[15] ?? '',
            })
        .toList();

    return Response.ok(
      jsonEncode(deliveries),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
