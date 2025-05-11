import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';
import '../models/user.dart';

class UsersHandler {
  final Database db;

  UsersHandler(this.db);

  // Получение всех пользователей
  Future<Response> getAll(Request req) async {
    final result = await db.connection.execute(
      'SELECT id, username, password, role, created_at, updated_at FROM Users',
    );

    final users = result.map((row) {
      final map = {
        'id': row[0],
        'username': row[1],
        'password': row[2],
        'role': row[3],
        'created_at': row[4],
        'updated_at': row[5],
      };
      return User.fromMap(map);
    }).toList();

    return Response.ok(
      jsonEncode(users.map((u) => u.toJson()).toList()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Получение пользователя по ID
  Future<Response> getById(Request req, String id) async {
    final result = await db.connection.execute(
      'SELECT id, username, password, role, created_at, updated_at FROM Users WHERE id = @id',
      parameters: {'id': int.parse(id)},
    );

    if (result.isEmpty) {
      return Response.notFound('User not found');
    }

    final row = result.first;
    final map = {
      'id': row[0],
      'username': row[1],
      'password': row[2],
      'role': row[3],
      'created_at': row[4],
      'updated_at': row[5],
    };

    final user = User.fromMap(map);

    return Response.ok(
      jsonEncode(user.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> createUser(Request req) async {
    final payload = jsonDecode(await req.readAsString());

    await db.connection.execute(
      Sql.named(
        'INSERT INTO Users (username, password, role) '
        'VALUES (@username, @password, @role)',
      ),
      parameters: {
        'username': payload['username'],
        'password': payload['password'],
        'role': payload['role'],
      },
    );

    return Response.ok('User created successfully');
  }

  Future<Response> login(Request req) async {
    final payload = jsonDecode(await req.readAsString());

    final username = payload['username'];
    final password = payload['password'];

    final result = await db.connection.execute(
      Sql.named('SELECT id, username, password, role, created_at, updated_at '
          'FROM Users WHERE username = @username'),
      parameters: {'username': username},
    );

    if (result.isEmpty) {
      return Response(401, body: 'Invalid credentials');
    }

    final row = result.first;
    final storedPassword = row[2];

    if (storedPassword != password) {
      return Response(401, body: 'Invalid credentials');
    }

    final user = {
      'id': row[0],
      'username': row[1],
      'role': row[3],
      'created_at': row[4].toString(),
      'updated_at': row[5].toString(),
    };

    return Response.ok(
      jsonEncode(user),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
