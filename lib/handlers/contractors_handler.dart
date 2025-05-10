import 'dart:convert';

import 'package:postgres/postgres.dart';
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

  Future<Response> create(Request req) async {
    final payload = jsonDecode(await req.readAsString());

    await db.connection.execute(
      Sql.named('''
        INSERT INTO Contractors (name, contact_person, phone, email, address)
        VALUES (@name, @contact_person, @phone, @email, @address)
      '''),
      parameters: {
        'name': payload['name'],
        'contact_person': payload['contact_person'],
        'phone': payload['phone'],
        'email': payload['email'],
        'address': payload['address'],
      },
    );

    return Response.ok('Contractor created successfully');
  }

  Future<Response> update(Request req, String id) async {
    final payload = jsonDecode(await req.readAsString());

    await db.connection.execute(
      Sql.named('''
        UPDATE Contractors
        SET name = @name,
            contact_person = @contact_person,
            phone = @phone,
            email = @email,
            address = @address,
            updated_at = NOW()
        WHERE id = @id
      '''),
      parameters: {
        'id': int.parse(id),
        'name': payload['name'],
        'contact_person': payload['contact_person'],
        'phone': payload['phone'],
        'email': payload['email'],
        'address': payload['address'],
      },
    );

    return Response.ok('Contractor updated successfully');
  }

  Future<Response> delete(Request req, String id) async {
    await db.connection.execute(
      Sql.named('DELETE FROM Contractors WHERE id = @id'),
      parameters: {'id': int.parse(id)},
    );

    return Response.ok('Contractor deleted successfully');
  }
}
