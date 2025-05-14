import 'dart:convert';

import 'package:http/http.dart' as http;

const driverId = 3;
const startLat = 45.034;
const startLng = 38.975;
const endLat = 45.055;
const endLng = 39.045;
const orsApiKey = '5b3ce3597851110001cf6248286500cbfa5b4a53ab10a1979be69848';
const updateUrl = 'http://localhost:8081/api/drivers/location';

Future<void> main() async {
  final routePoints = await _getRoutePoints();
  if (routePoints.isEmpty) {
    print('Маршрут не получен');
    return;
  }

  for (final point in routePoints) {
    await _updatePosition(point[0], point[1]);
    await Future.delayed(Duration(seconds: 10));
  }
}

Future<List<List<double>>> _getRoutePoints() async {
  final body = jsonEncode({
    'coordinates': [
      [startLng, startLat],
      [endLng, endLat],
    ]
  });

  final response = await http.post(
    Uri.parse('https://api.openrouteservice.org/v2/directions/driving-car'),
    headers: {
      'Authorization': orsApiKey,
      'Content-Type': 'application/json',
    },
    body: body,
  );

  if (response.statusCode != 200) {
    print('Ошибка ORS: ${response.body}');
    return [];
  }

  final data = jsonDecode(response.body);
  final polyline = data['routes'][0]['geometry'];
  return _decodePolyline(polyline);
}

Future<void> _updatePosition(double lat, double lon) async {
  final response = await http.post(
    Uri.parse(updateUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'driver_id': driverId,
      'latitude': lat,
      'longitude': lon,
    }),
  );
  print('Update sent: ($lat, $lon) — ${response.statusCode}');
}

List<List<double>> _decodePolyline(String encoded) {
  List<List<double>> polyline = [];
  int index = 0, len = encoded.length;
  int lat = 0, lng = 0;

  while (index < len) {
    int b, shift = 0, result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dlat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dlng;

    polyline.add([lat / 1E5, lng / 1E5]);
  }

  return polyline;
}
