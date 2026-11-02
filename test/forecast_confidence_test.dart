import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/models/forecast_confidence.dart';
import 'package:meteo/models/weather_data.dart';

HourlyWeather hour(int code, int rainChance) => HourlyWeather(
  time: DateTime(2026, 10, 22, 12),
  temperature: 20,
  apparentTemperature: 20,
  code: code,
  rainChance: rainChance,
  rainMm: 0,
  humidity: 50,
  windSpeed: 8,
  windGust: 12,
  windDirection: 180,
  cloudCover: 20,
  pressure: 1015,
  uvIndex: 4,
  freezingLevel: 3000,
  isDay: true,
);

void main() {
  test('l’attendibilità diminuisce con l’orizzonte temporale', () {
    final hours = [hour(0, 5), hour(0, 5), hour(1, 10)];
    expect(
      ForecastConfidence.calculate(0, hours),
      greaterThan(ForecastConfidence.calculate(5, hours)),
    );
  });

  test('l’incertezza e i cambi meteo riducono l’indice', () {
    final stable = [hour(0, 0), hour(0, 0), hour(0, 0)];
    final variable = [hour(0, 50), hour(63, 50), hour(95, 50)];
    expect(
      ForecastConfidence.calculate(0, stable),
      greaterThan(ForecastConfidence.calculate(0, variable)),
    );
  });
}
