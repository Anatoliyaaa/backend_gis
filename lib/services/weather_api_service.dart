import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherApiService {
  static const String baseUrl = 'http://10.0.2.2:8081/api';

  static Future<String?> fetchWeatherCondition(int startId, int endId) async {
    final routeRes = await http.get(Uri.parse('$baseUrl/routes'));
    if (routeRes.statusCode != 200) return null;

    final List<dynamic> routes = jsonDecode(routeRes.body);
    final match = routes.firstWhere(
      (r) =>
          r['start_location']['id'] == startId &&
          r['end_location']['id'] == endId,
      orElse: () => null,
    );

    if (match == null) return null;

    final routeId = match['id'];
    final weatherRes = await http.get(Uri.parse('$baseUrl/weather/$routeId'));
    if (weatherRes.statusCode != 200) return null;

    final json = jsonDecode(weatherRes.body);
    final temp = json['temperature'];
    final cond = json['condition'];
    return '$cond, ${temp.toStringAsFixed(1)}°C';
  }

  static Future<String?> fetchLiveWeather(
      double lat, double lon, String apiKey) async {
    final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ru');

    final response = await http.get(uri);
    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body);
    final description = data['weather'][0]['description'];
    final temp = data['main']['temp'];
    return '$description, ${temp.toStringAsFixed(1)}°C';
  }
}
