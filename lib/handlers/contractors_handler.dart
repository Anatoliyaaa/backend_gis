import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../database/database.dart';
import '../models/contractor.dart';

class ContractorsHandler {
  final Database db;

  ContractorsHandler(this.db);

  Future<Response> getAll(Request req) async {
    final connection = db.connection;

    final result = await connection.execute(
      'SELECT * FROM Contractors',
    );

    final contractors = result.map((row) {
      final map = {
        'id': row[0],
        'name': row[1],
        'contact_person': row[2],
        'phone': row[3],
        'email': row[4],
        'address': row[5],
        'created_at': row[6],
        'updated_at': row[7],
      };
      return Contractor.fromMap(map);
    }).toList();

    return Response.ok(
      jsonEncode(contractors.map((c) => c.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> getById(Request req, String id) async {
    final connection = db.connection;

    final result = await connection.execute(
      'SELECT * FROM Contractors WHERE id = @id',
      parameters: {'id': int.parse(id)},
    );

    if (result.isEmpty) {
      return Response.notFound('Contractor not found');
    }

    final row = result.first;
    final map = {
      'id': row[0],
      'name': row[1],
      'contact_person': row[2],
      'phone': row[3],
      'email': row[4],
      'address': row[5],
      'created_at': row[6],
      'updated_at': row[7],
    };

    final contractor = Contractor.fromMap(map);

    return Response.ok(
      jsonEncode(contractor.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
