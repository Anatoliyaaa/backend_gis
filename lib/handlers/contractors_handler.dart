import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../database/database.dart';
import '../models/contractor.dart';

class ContractorsHandler {
  final Database db;

  ContractorsHandler(this.db);

  Future<Response> getAll(Request req) async {
    final result = await db.connection.query('SELECT * FROM Contractors');
    final contractors =
        result.map((row) => Contractor.fromMap(row.toColumnMap())).toList();

    return Response.ok(
      jsonEncode(contractors.map((c) => c.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> getById(Request req, String id) async {
    final result = await db.connection.query(
      'SELECT * FROM Contractors WHERE id=@id',
      substitutionValues: {'id': int.parse(id)},
    );

    if (result.isEmpty) {
      return Response.notFound('Contractor not found');
    }

    final contractor = Contractor.fromMap(result.first.toColumnMap());

    return Response.ok(
      jsonEncode(contractor.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
