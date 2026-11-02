import 'weather_data.dart';

abstract final class ForecastConfidence {
  static int calculate(int dayIndex, List<HourlyWeather> hours) {
    if (hours.isEmpty) return (90 - dayIndex * 7).clamp(45, 96);
    final ambiguity = hours.map((item) => 1 - ((item.rainChance - 50).abs() / 50)).reduce((a, b) => a + b) / hours.length;
    var transitions = 0;
    for (var i = 1; i < hours.length; i++) {
      if (_family(hours[i - 1].code) != _family(hours[i].code)) transitions++;
    }
    return (97 - dayIndex * 7 - ambiguity * 8 - transitions.clamp(0, 8)).round().clamp(45, 98);
  }

  static String label(int score) => score >= 85 ? 'Alta' : score >= 70 ? 'Buona' : score >= 55 ? 'Media' : 'Bassa';
  static int _family(int code) => code <= 1 ? 0 : code <= 48 ? 1 : code <= 67 ? 2 : code <= 86 ? 3 : 4;
}
