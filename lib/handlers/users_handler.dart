import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../database/database.dart';
import '../models/user.dart';

class UsersHandler {
  final Database db;

  UsersHandler(this.db);

  // Получение всех пользователей
  Future<Response> getAll(Request req) async {
    final result = await db.connection.query(
      'SELECT id, username, role, created_at, updated_at FROM Users',
    );

    final users = result.map((row) => User.fromMap(row.toColumnMap())).toList();

    return Response.ok(
      jsonEncode(users.map((u) => u.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Получение пользователя по ID
  Future<Response> getById(Request req, String id) async {
    final result = await db.connection.query(
      'SELECT id, username, role, created_at, updated_at FROM Users WHERE id=@id',
      substitutionValues: {'id': int.parse(id)},
    );

    if (result.isEmpty) {
      return Response.notFound('User not found');
    }

    final user = User.fromMap(result.first.toColumnMap());

    return Response.ok(
      jsonEncode(user.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Создание нового пользователя
  Future<Response> createUser(Request req) async {
    final payload = jsonDecode(await req.readAsString());

    await db.connection.query(
      '''
      INSERT INTO Users (username, password, role) 
      VALUES (@username, @password, @role)
      ''',
      substitutionValues: {
        'username': payload['username'],
        'password': payload['password'],
        'role': payload['role'],
      },
    );

    return Response.ok('User created successfully');
  }
}
