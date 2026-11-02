import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherMapPoint {
  const WeatherMapPoint({required this.latitude, required this.longitude, required this.windSpeed, required this.windDirection, required this.cloudCover, required this.airQualityIndex});
  final double latitude, longitude, windSpeed, windDirection;
  final int cloudCover, airQualityIndex;
}

class WeatherMapFrame {
  const WeatherMapFrame({required this.time, required this.points});
  final DateTime time;
  final List<WeatherMapPoint> points;
}

class WeatherMapTimeline {
  const WeatherMapTimeline({required this.frames});
  final List<WeatherMapFrame> frames;
}

class WeatherMapService {
  const WeatherMapService();

  Future<WeatherMapTimeline> loadArea({required double latitude, required double longitude}) async {
    // 25 punti per 24 ore: ogni livello è una sequenza animabile.
    const offsets = [-2.4, -1.2, 0.0, 1.2, 2.4];
    final coordinates = <(double, double)>[
      for (final latOffset in offsets)
        for (final lonOffset in offsets)
          ((latitude + latOffset).clamp(-85.0, 85.0), _wrapLongitude(longitude + lonOffset)),
    ];
    final latitudes = coordinates.map((point) => point.$1).join(',');
    final longitudes = coordinates.map((point) => point.$2).join(',');

    final weatherUri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitudes,
      'longitude': longitudes,
      'hourly': 'wind_speed_10m,wind_direction_10m,cloud_cover',
      'forecast_hours': '24',
      'timezone': 'UTC',
    });
    final airUri = Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      'latitude': latitudes,
      'longitude': longitudes,
      'hourly': 'european_aqi',
      'forecast_hours': '24',
      'timezone': 'UTC',
    });

    final responses = await Future.wait([http.get(weatherUri), http.get(airUri)]);
    if (responses.any((response) => response.statusCode != 200)) {
      throw Exception('Livelli meteo animati non disponibili.');
    }

    final weather = _asList(jsonDecode(responses[0].body));
    final air = _asList(jsonDecode(responses[1].body));
    final firstHourly = weather.first['hourly'] as Map<String, dynamic>;
    final times = firstHourly['time'] as List<dynamic>;
    final frameCount = times.length.clamp(0, 24);

    final frames = List.generate(frameCount, (frameIndex) {
      final points = List.generate(coordinates.length, (pointIndex) {
        final weatherHourly = weather[pointIndex]['hourly'] as Map<String, dynamic>;
        final airHourly = air[pointIndex]['hourly'] as Map<String, dynamic>;
        num value(Map<String, dynamic> source, String key) => (source[key] as List<dynamic>)[frameIndex] as num? ?? 0;
        return WeatherMapPoint(
          latitude: coordinates[pointIndex].$1,
          longitude: coordinates[pointIndex].$2,
          windSpeed: value(weatherHourly, 'wind_speed_10m').toDouble(),
          windDirection: value(weatherHourly, 'wind_direction_10m').toDouble(),
          cloudCover: value(weatherHourly, 'cloud_cover').round(),
          airQualityIndex: value(airHourly, 'european_aqi').round(),
        );
      }, growable: false);
      return WeatherMapFrame(time: DateTime.parse('${times[frameIndex]}Z').toLocal(), points: points);
    }, growable: false);

    if (frames.isEmpty) throw Exception('Nessun fotogramma meteo disponibile.');
    return WeatherMapTimeline(frames: frames);
  }

  List<Map<String, dynamic>> _asList(Object? value) {
    if (value is List<dynamic>) {
      return value.map((item) => Map<String, dynamic>.from(item as Map)).toList(growable: false);
    }
    return [Map<String, dynamic>.from(value as Map)];
  }

  double _wrapLongitude(double value) {
    if (value > 180) return value - 360;
    if (value < -180) return value + 360;
    return value;
  }
}
