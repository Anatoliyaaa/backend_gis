import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:postgres/postgres.dart';
import '../database/database.dart';

class ExchangeHandler {
  final Database db;

  ExchangeHandler(this.db);

  /// Экспорт всех доставок в JSON
  Future<Response> exportDeliveries(Request req) async {
    final result = await db.connection.execute('''
      SELECT d.id, d.delivery_date, d.status,
            u.username AS driver,
            v.model, v.license_plate,
            s.name AS start_location, s.latitude, s.longitude,
            e.name AS end_location, e.latitude, e.longitude,
            COALESCE(string_agg(c.type || ' (' || c.quantity || ' ' || c.unit || ')', ', '), '') AS cargo_summary
      FROM Deliveries d
      JOIN Users u ON d.driver_id = u.id
      JOIN Vehicles v ON d.vehicle_id = v.id
      JOIN Routes r ON d.route_id = r.id
      JOIN Locations s ON r.start_location_id = s.id
      JOIN Locations e ON r.end_location_id = e.id
      LEFT JOIN Cargo c ON d.id = c.delivery_id
      GROUP BY d.id, u.username, v.model, v.license_plate, s.name, s.latitude, s.longitude, e.name, e.latitude, e.longitude
      ORDER BY d.delivery_date DESC
    ''');

    final deliveries = result
        .map((row) => {
              'id': row[0],
              'delivery_date': row[1].toString(),
              'status': row[2],
              'driver': row[3],
              'vehicle': {'model': row[4], 'license_plate': row[5]},
              'start_location': {
                'name': row[6],
                'latitude': row[7],
                'longitude': row[8],
              },
              'end_location': {
                'name': row[9],
                'latitude': row[10],
                'longitude': row[11],
              },
              'cargo': row[12] ?? '',
            })
        .toList();

    return Response.ok(
      jsonEncode(deliveries),
      headers: {'Content-Type': 'application/json'},
    );
  }

  /// Импорт новых доставок (JSON)
  Future<Response> importDeliveries(Request req) async {
    final body = await req.readAsString();
    final List<dynamic> deliveries = jsonDecode(body);

    for (final delivery in deliveries) {
      try {
        await db.connection.execute(
          Sql.named('''
            INSERT INTO Deliveries (driver_id, route_id, delivery_date, status, vehicle_id)
            VALUES ((SELECT id FROM Users WHERE username = @driver),
                    @route_id,
                    @date,
                    @status,
                    (SELECT id FROM Vehicles WHERE license_plate = @license))
          '''),
          parameters: {
            'driver': delivery['driver'],
            'route_id': delivery['route_id'],
            'date': DateTime.parse(delivery['delivery_date']),
            'status': delivery['status'],
            'license': delivery['vehicle']['license_plate'],
          },
        );
      } catch (e) {
        return Response.internalServerError(body: 'Ошибка импорта: $e');
      }
    }

    return Response.ok('Импорт завершён успешно');
  }

  /// Проверка доступности обмена
  Future<Response> ping(Request req) async {
    return Response.ok('ERP API доступен');
  }
}
