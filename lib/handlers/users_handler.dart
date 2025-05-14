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
      'SELECT id, username, password, role, email, phone, otp_code, otp_created_at, created_at, updated_at FROM Users',
    );

    final users = result.map((row) {
      final map = {
        'id': row[0],
        'username': row[1],
        'password': row[2],
        'role': row[3],
        'email': row[4],
        'phone': row[5],
        'otp_code': row[6],
        'otp_created_at': row[7],
        'created_at': row[8],
        'updated_at': row[9],
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
      Sql.named('''
        SELECT id, username, password, role, email, phone, otp_code, otp_created_at, created_at, updated_at
        FROM Users WHERE id = @id
      '''),
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
      'email': row[4],
      'phone': row[5],
      'otp_code': row[6],
      'otp_created_at': row[7],
      'created_at': row[8],
      'updated_at': row[9],
    };

    final user = User.fromMap(map);

    return Response.ok(
      jsonEncode(user.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  // Создание нового пользователя
  Future<Response> createUser(Request req) async {
    final payload = jsonDecode(await req.readAsString());

    await db.connection.execute(
      Sql.named('''
        INSERT INTO Users (username, password, role, email, phone)
        VALUES (@username, @password, @role, @email, @phone)
      '''),
      parameters: {
        'username': payload['username'],
        'password': payload['password'],
        'role': payload['role'],
        'email': payload['email'],
        'phone': payload['phone'],
      },
    );

    return Response.ok('User created successfully');
  }

  // Логин
  Future<Response> login(Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final username = payload['username'];
    final password = payload['password'];

    final result = await db.connection.execute(
      Sql.named('''
      SELECT id, username, password, role, created_at, updated_at
      FROM Users WHERE username = @username
    '''),
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

  //отправка кода otp
  Future<Response> sendOtp(Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final username = payload['username'];

    final result = await db.connection.execute(
      Sql.named('''
      SELECT email, phone FROM Users WHERE username = @username
    '''),
      parameters: {'username': username},
    );

    if (result.isEmpty) {
      return Response.notFound('Пользователь не найден');
    }

    final row = result.first;
    final email = row[0] as String?;
    final phone = row[1] as String?;

    if (email == null || email.isEmpty) {
      return Response(400, body: 'Не указан email для пользователя');
    }
/*
    await sendOtpToEmail(
      connection: db.connection,
      username: username,
      email: email,
      phone: phone,
    );
    */

    return Response.ok('OTP отправлен');
  }

  // Проверка OTP
  Future<Response> verifyOtp(Request req) async {
    final payload = jsonDecode(await req.readAsString());
    final username = payload['username'];
    final otp = payload['otp'];

    final result = await db.connection.execute(
      Sql.named('''
        SELECT id, username, role, otp_code, otp_created_at
        FROM Users WHERE username = @username
      '''),
      parameters: {'username': username},
    );

    if (result.isEmpty) {
      return Response.forbidden('Пользователь не найден');
    }

    final row = result.first;
    final storedOtp = row[3] as String?;
    final otpCreatedAt = row[4] as DateTime?;

    if (storedOtp == null || otpCreatedAt == null) {
      return Response(401, body: 'OTP не найден. Запросите повторно.');
    }

    final now = DateTime.now().toUtc();
    final isExpired = now.difference(otpCreatedAt).inMinutes >= 5;

    if (isExpired) {
      return Response(401, body: 'OTP истёк. Запросите новый код.');
    }

    if (otp != storedOtp) {
      return Response(401, body: 'Неверный код OTP');
    }

    final user = {
      'id': row[0],
      'username': row[1],
      'role': row[2],
    };

    return Response.ok(
      jsonEncode(user),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
