import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../database/database.dart';

class LocationsHandler {
  final Database db;

  LocationsHandler(this.db);

  Future<Response> getAll(Request req) async {
    final result = await db.connection.execute(
      'SELECT id, name, latitude, longitude FROM Locations',
    );

    final locations = result
        .map((row) => {
              'id': row[0],
              'name': row[1],
              'latitude': row[2],
              'longitude': row[3],
            })
        .toList();

    return Response.ok(
      jsonEncode(locations),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
