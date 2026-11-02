import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/models/weather_data.dart';

void main() {
  test('mantiene tutte le ore giornaliere e separa le prossime ore', () {
    final start = DateTime(2026, 10, 22);
    final times = List.generate(
      48,
      (index) =>
          start.add(Duration(hours: index)).toIso8601String().substring(0, 16),
    );
    List<num> values(num value) => List<num>.filled(48, value);

    final weather = WeatherData.fromJson({
      'latitude': 41.9,
      'longitude': 12.5,
      'current': {
        'time': '2026-10-22T12:00',
        'temperature_2m': 20,
        'apparent_temperature': 20,
        'relative_humidity_2m': 55,
        'wind_speed_10m': 14,
        'wind_direction_10m': 225,
        'precipitation': 0,
        'weather_code': 1,
        'is_day': 1,
      },
      'hourly': {
        'time': times,
        'temperature_2m': values(20),
        'apparent_temperature': values(20),
        'weather_code': values(1),
        'precipitation_probability': values(10),
        'precipitation': values(0),
        'relative_humidity_2m': values(55),
        'wind_speed_10m': values(14),
        'wind_gusts_10m': values(22),
        'wind_direction_10m': values(225),
        'cloud_cover': values(20),
        'pressure_msl': values(1015),
        'is_day': List<num>.generate(
          48,
          (index) => index % 24 >= 7 && index % 24 < 19 ? 1 : 0,
        ),
      },
      'daily': {
        'time': ['2026-10-22', '2026-10-23'],
        'temperature_2m_max': [24, 25],
        'temperature_2m_min': [12, 13],
        'weather_code': [1, 2],
        'precipitation_probability_max': [10, 20],
        'precipitation_sum': [0, 1.2],
        'wind_speed_10m_max': [20, 28],
        'wind_gusts_10m_max': [35, 44],
        'wind_direction_10m_dominant': [180, 225],
      },
    });

    expect(weather.hoursFor(DateTime(2026, 10, 22)), hasLength(24));
    expect(weather.hoursFor(DateTime(2026, 10, 23)), hasLength(24));
    expect(weather.upcomingHours, hasLength(36));
    expect(weather.daily.last.windMax, 28);
    expect(weather.daily.last.gustMax, 44);
    expect(weather.daily.last.windDirection, 225);
    expect(weather.hourly.first.windDirection, 225);
    expect(weather.hourly.first.isDay, isFalse);
    expect(weather.hourly[12].isDay, isTrue);
    expect(weather.windDirection, 225);
    expect(weather.hasHourlyDetailsForAllDays, isTrue);
  });
}
