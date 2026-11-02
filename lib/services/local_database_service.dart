import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/city.dart';
import '../models/environmental_data.dart';
import '../models/marine_data.dart';
import '../models/user_preferences.dart';
import '../models/weather_data.dart';

class LocalDatabaseService {
  LocalDatabaseService(this.prefs);
  final SharedPreferences prefs;
  static const _favorites = 'favorite_cities_v1',
      _unit = 'temperature_unit_v1',
      _last = 'last_weather_v3',
      _cache = 'weather_cache_v3_',
      _marineLast = 'last_marine_v1',
      _marineCache = 'marine_cache_v1_',
      _environmentalCache = 'environmental_cache_v1_',
      _vesselHeading = 'vessel_heading_v1',
      _vesselSpeed = 'vessel_speed_v1';
  List<City> getFavoriteCities() {
    try {
      return (jsonDecode(prefs.getString(_favorites) ?? '[]') as List)
          .map((x) => City.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveFavoriteCities(List<City> value) => prefs.setString(
    _favorites,
    jsonEncode(value.map((x) => x.toJson()).toList()),
  );
  TemperatureUnit getTemperatureUnit() =>
      TemperatureUnit.parse(prefs.getString(_unit));
  Future<void> saveTemperatureUnit(TemperatureUnit value) =>
      prefs.setString(_unit, value.name);
  String key(double lat, double lon) =>
      '$_cache${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}';
  WeatherData? _decode(String? raw) {
    try {
      if (raw == null) return null;
      final decoded = Map<String, dynamic>.from(jsonDecode(raw) as Map);
      final daily = decoded['daily'] as List<dynamic>? ?? const [];
      final hourly = decoded['hourly'] as List<dynamic>? ?? const [];
      final usesCompleteSchema =
          decoded.containsKey('currentTime') &&
          decoded.containsKey('windDirection') &&
          hourly.isNotEmpty &&
          hourly.every(
            (item) =>
                (item as Map).containsKey('apparentTemperature') &&
                item.containsKey('windGust') &&
                item.containsKey('pressure') &&
                item.containsKey('uvIndex') &&
                item.containsKey('freezingLevel'),
          ) &&
          daily.every((item) => (item as Map).containsKey('windDirection'));
      if (!usesCompleteSchema) return null;
      final weather = WeatherData.fromJson(decoded);
      return weather.hasHourlyDetailsForAllDays ? weather : null;
    } catch (_) {
      return null;
    }
  }

  WeatherData? getLastWeather() => _decode(prefs.getString(_last));
  WeatherData? getCachedWeather(double lat, double lon) =>
      _decode(prefs.getString(key(lat, lon)));
  Future<void> cacheWeather(WeatherData data) async {
    final value = jsonEncode(data.toJson());
    await prefs.setString(_last, value);
    await prefs.setString(key(data.latitude, data.longitude), value);
  }

  String marineKey(double lat, double lon) =>
      '$_marineCache${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}';

  MarineData? _decodeMarine(String? raw) {
    try {
      if (raw == null) return null;
      return MarineData.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  MarineData? getLastMarine() => _decodeMarine(prefs.getString(_marineLast));

  MarineData? getCachedMarine(double lat, double lon) =>
      _decodeMarine(prefs.getString(marineKey(lat, lon)));

  Future<void> cacheMarine(double lat, double lon, MarineData data) async {
    final value = jsonEncode(data.toJson());
    await prefs.setString(_marineLast, value);
    await prefs.setString(marineKey(lat, lon), value);
  }

  String environmentalKey(double lat, double lon) =>
      '$_environmentalCache${lat.toStringAsFixed(3)}_${lon.toStringAsFixed(3)}';

  EnvironmentalData? getCachedEnvironmental(double lat, double lon) {
    try {
      final raw = prefs.getString(environmentalKey(lat, lon));
      if (raw == null) return null;
      return EnvironmentalData.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheEnvironmental(
    double lat,
    double lon,
    EnvironmentalData data,
  ) => prefs.setString(environmentalKey(lat, lon), jsonEncode(data.toJson()));

  double getVesselHeading() => prefs.getDouble(_vesselHeading) ?? 180;

  Future<void> saveVesselHeading(double value) =>
      prefs.setDouble(_vesselHeading, value);

  double getVesselSpeed() => prefs.getDouble(_vesselSpeed) ?? 6;

  Future<void> saveVesselSpeed(double value) =>
      prefs.setDouble(_vesselSpeed, value);
}
