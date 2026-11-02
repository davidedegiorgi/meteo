import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_constants.dart';
import '../models/city.dart';
import '../models/weather_data.dart';
import 'local_database_service.dart';

class WeatherResult {
  const WeatherResult(this.data, this.fromCache);
  final WeatherData data;
  final bool fromCache;
}

class CityWeatherSnapshot {
  const CityWeatherSnapshot({
    required this.weatherCode,
    required this.isDay,
    required this.precipitation,
  });

  final int weatherCode;
  final bool isDay;
  final double precipitation;
}

class WeatherService {
  WeatherService(this.database, [http.Client? client])
    : client = client ?? http.Client();
  final LocalDatabaseService database;
  final http.Client client;
  Future<WeatherResult> getWeather(double lat, double lon, String name) async {
    try {
      const currentVariables =
          'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_gusts_10m,wind_direction_10m';
      final uri = Uri.parse(AppConstants.weatherUrl).replace(
        queryParameters: {
          'latitude': '$lat',
          'longitude': '$lon',
          'timezone': 'auto',
          'forecast_days': '7',
          'models': 'italia_meteo_arpae_icon_2i,ecmwf_ifs025',
          'current': currentVariables,
          'hourly':
              'temperature_2m,apparent_temperature,precipitation_probability,precipitation,weather_code,relative_humidity_2m,wind_speed_10m,wind_gusts_10m,wind_direction_10m,cloud_cover,pressure_msl,uv_index,freezing_level_height,is_day',
          'daily':
              'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum,wind_speed_10m_max,wind_gusts_10m_max,wind_direction_10m_dominant,sunrise,sunset',
        },
      );
      final currentUri = Uri.parse(AppConstants.weatherUrl).replace(
        queryParameters: {
          'latitude': '$lat',
          'longitude': '$lon',
          'timezone': 'auto',
          'models': 'icon_eu',
          'current': currentVariables,
        },
      );
      final atmosphericDetailsUri = Uri.parse(AppConstants.weatherUrl).replace(
        queryParameters: {
          'latitude': '$lat',
          'longitude': '$lon',
          'timezone': 'auto',
          'forecast_days': '7',
          'hourly': 'uv_index,freezing_level_height',
        },
      );
      final liveCurrentFuture = client
          .get(currentUri)
          .timeout(AppConstants.timeout)
          .then<http.Response?>((response) => response, onError: (_) => null);
      final atmosphericDetailsFuture = client
          .get(atmosphericDetailsUri)
          .timeout(AppConstants.timeout)
          .then<http.Response?>((response) => response, onError: (_) => null);
      final response = await client.get(uri).timeout(AppConstants.timeout);
      if (response.statusCode != 200)
        throw Exception('Open-Meteo: errore ${response.statusCode}');
      final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      final liveCurrent = await liveCurrentFuture;
      if (liveCurrent?.statusCode == 200) {
        final liveJson = Map<String, dynamic>.from(
          jsonDecode(liveCurrent!.body) as Map,
        );
        if (liveJson['current'] is Map) json['current'] = liveJson['current'];
      }
      final atmosphericDetails = await atmosphericDetailsFuture;
      if (atmosphericDetails?.statusCode == 200) {
        final detailsJson = Map<String, dynamic>.from(
          jsonDecode(atmosphericDetails!.body) as Map,
        );
        final primaryHourly = Map<String, dynamic>.from(
          json['hourly'] as Map? ?? const {},
        );
        final detailsHourly = Map<String, dynamic>.from(
          detailsJson['hourly'] as Map? ?? const {},
        );
        final primaryTimes = primaryHourly['time'] as List? ?? const [];
        final detailTimes = detailsHourly['time'] as List? ?? const [];
        for (final variable in ['uv_index', 'freezing_level_height']) {
          final detailValues = detailsHourly[variable] as List? ?? const [];
          final byTime = <String, dynamic>{};
          for (
            var index = 0;
            index < detailTimes.length && index < detailValues.length;
            index++
          ) {
            byTime[detailTimes[index] as String] = detailValues[index];
          }
          primaryHourly[variable] = primaryTimes
              .map((time) => byTime[time as String])
              .toList(growable: false);
        }
        json['hourly'] = primaryHourly;
      }
      final data = WeatherData.fromJson(json, locationName: name);
      await database.cacheWeather(data);
      return WeatherResult(data, false);
    } catch (_) {
      final cached = database.getCachedWeather(lat, lon);
      if (cached != null) return WeatherResult(cached, true);
      throw Exception('Meteo non disponibile e nessun dato offline trovato.');
    }
  }

  Future<List<City>> searchCities(String query) async {
    if (query.trim().length < 2) return [];
    final uri = Uri.parse(AppConstants.geocodingUrl).replace(
      queryParameters: {
        'name': query.trim(),
        'count': '8',
        'language': 'it',
        'format': 'json',
      },
    );
    final response = await client.get(uri).timeout(AppConstants.timeout);
    if (response.statusCode != 200)
      throw Exception('Ricerca città non disponibile.');
    final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    return (json['results'] as List? ?? [])
        .map((x) => City.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList();
  }

  Future<CityWeatherSnapshot> getCurrentConditions(City city) async {
    final uri = Uri.parse(AppConstants.weatherUrl).replace(
      queryParameters: {
        'latitude': '${city.latitude}',
        'longitude': '${city.longitude}',
        'timezone': 'auto',
        'current': 'weather_code,is_day,precipitation',
      },
    );
    final response = await client.get(uri).timeout(AppConstants.timeout);
    if (response.statusCode != 200) {
      throw Exception('Condizioni attuali non disponibili.');
    }
    final json = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
    final current = Map<String, dynamic>.from(json['current'] as Map);
    return CityWeatherSnapshot(
      weatherCode: (current['weather_code'] as num).round(),
      isDay: (current['is_day'] as num).round() == 1,
      precipitation: (current['precipitation'] as num?)?.toDouble() ?? 0,
    );
  }

  void dispose() => client.close();
}
