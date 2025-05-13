import 'dart:convert';

import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';

class RoadRoutingHandler {
  final DotEnv env;

  RoadRoutingHandler(this.env);

  Future<Response> getRoute(Request req) async {
    try {
      final queryParams = req.url.queryParameters;
      final start = queryParams['start']; // format: lat,lng
      final end = queryParams['end']; // format: lat,lng

      if (start == null || end == null) {
        return Response(400, body: 'Параметры start и end обязательны');
      }

      final orsKey = env['ORS_API_KEY'];
      if (orsKey == null) {
        return Response(500, body: 'ORS ключ не найден в .env');
      }

      final url = Uri.parse(
          'https://api.openrouteservice.org/v2/directions/driving-car');
      final response = await http.post(
        url,
        headers: {
          'Authorization': orsKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'coordinates': [
            start.split(',').map(double.parse).toList().reversed.toList(),
            end.split(',').map(double.parse).toList().reversed.toList(),
          ]
        }),
      );

      final decoded = jsonDecode(response.body);

      if (decoded['routes'] == null || decoded['routes'].isEmpty) {
        return Response.internalServerError(
          body: 'ORS вернул пустой маршрут или ошибку: ${response.body}',
        );
      }

      final geometry = decoded['routes'][0]['geometry'];
      return Response.ok(
        jsonEncode({'type': 'polyline', 'geometry': geometry}),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Ошибка маршрутизации: $e');
    }
  }
}
