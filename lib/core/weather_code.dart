import 'package:flutter/material.dart';
import 'app_constants.dart';

abstract final class WeatherCode {
  static String description(int code) => switch (code) {
    0 => 'Sereno',
    1 => 'Prevalentemente sereno',
    2 => 'Parzialmente nuvoloso',
    3 => 'Coperto',
    45 || 48 => 'Nebbia',
    51 || 53 || 55 || 56 || 57 => 'Pioviggine',
    61 || 63 || 65 || 66 || 67 => 'Pioggia',
    71 || 73 || 75 || 77 => 'Neve',
    80 || 81 || 82 => 'Rovesci',
    85 || 86 => 'Rovesci di neve',
    95 || 96 || 99 => 'Temporale',
    _ => 'Variabile',
  };

  static IconData icon(int code, {bool isDay = true}) {
    if (!isDay && code <= 2) return Icons.nightlight_round;
    if (code <= 1) return Icons.wb_sunny_rounded;
    if (code <= 3 || code == 45 || code == 48) return Icons.cloud_rounded;
    if (isSnow(code)) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.cloudy_snowing;
  }

  static bool isSnow(int code) =>
      code == 71 ||
      code == 73 ||
      code == 75 ||
      code == 77 ||
      code == 85 ||
      code == 86;

  static bool isRain(int code) =>
      (code >= 51 && code <= 67) || (code >= 80 && code <= 82) || code >= 95;

  static bool isLiquidRain(int code) =>
      (code >= 51 && code <= 67) || (code >= 80 && code <= 82);

  static int rainIntensity(int code, double rainMm, {bool dailyTotal = false}) {
    final byCode = switch (code) {
      55 || 57 || 65 || 67 || 82 => 3,
      53 || 63 || 66 || 81 => 2,
      _ => 1,
    };
    final byAmount = dailyTotal
        ? (rainMm >= 10 ? 3 : (rainMm >= 2 ? 2 : 1))
        : (rainMm >= 2.5 ? 3 : (rainMm >= .4 ? 2 : 1));
    return byCode > byAmount ? byCode : byAmount;
  }

  static Color iconColor(int code, {bool isDay = true}) {
    if (!isDay && code <= 2) return const Color(0xFFFFF3A6);
    if (code <= 1) return const Color(0xFFFFD54F);
    if (code <= 3) return const Color(0xFFE4EBF2);
    if (code == 45 || code == 48) return const Color(0xFFCFD8DC);
    if (isSnow(code)) return const Color(0xFFB3E5FC);
    if (code >= 95) return const Color(0xFFE1BEE7);
    return const Color(0xFF80D8FF);
  }

  static List<Color> gradient(int code, bool isDay, {DateTime? time}) {
    if (isRain(code)) return AppConstants.rainy;
    if (!isDay) return AppConstants.night;
    if (code <= 1)
      return time == null ? AppConstants.sunny : clearSkyGradient(time);
    if (isSnow(code)) return AppConstants.snowy;
    return AppConstants.cloudy;
  }

  static List<Color> clearSkyGradient(DateTime time) {
    const dawn = [Color(0xFF4869B1), Color(0xFFF08A91), Color(0xFFFFC36B)];
    const morning = [Color(0xFF168DE2), Color(0xFF61C6F2), Color(0xFFFFD98A)];
    const noon = [Color(0xFF087ED0), Color(0xFF39B7EE), Color(0xFF9ADCF4)];
    const afternoon = [Color(0xFF197FC9), Color(0xFF55BCE7), Color(0xFFFFC978)];
    const sunset = [Color(0xFF5363A7), Color(0xFFE87991), Color(0xFFFF9857)];
    final hour = time.hour + time.minute / 60;
    if (hour < 8) return _blend(dawn, morning, ((hour - 5) / 3).clamp(0, 1));
    if (hour < 12) return _blend(morning, noon, (hour - 8) / 4);
    if (hour < 16) return _blend(noon, afternoon, (hour - 12) / 4);
    return _blend(afternoon, sunset, ((hour - 16) / 4).clamp(0, 1));
  }

  static List<Color> _blend(List<Color> from, List<Color> to, num amount) =>
      List.generate(
        from.length,
        (i) => Color.lerp(from[i], to[i], amount.toDouble())!,
      );
}

/// Icona meteo composta: in caso di pioggia mostra una nuvola e da una a tre
/// gocce, così l'intensità è leggibile anche senza aprire i dettagli.
class WeatherIcon extends StatelessWidget {
  const WeatherIcon({
    super.key,
    required this.code,
    required this.rainMm,
    this.isDay = true,
    this.dailyTotal = false,
    this.size = 24,
  });

  final int code;
  final double rainMm;
  final bool isDay;
  final bool dailyTotal;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!WeatherCode.isLiquidRain(code)) {
      return Icon(
        WeatherCode.icon(code, isDay: isDay),
        color: WeatherCode.iconColor(code, isDay: isDay),
        size: size,
      );
    }

    final intensity = WeatherCode.rainIntensity(
      code,
      rainMm,
      dailyTotal: dailyTotal,
    );
    final dropColor = switch (intensity) {
      1 => const Color(0xFF8DDCFF),
      2 => const Color(0xFF42B5F5),
      _ => const Color(0xFF1687D4),
    };
    final dropSize = size * .28;
    final positions = switch (intensity) {
      1 => <double>[.50],
      2 => <double>[.35, .65],
      _ => <double>[.24, .50, .76],
    };

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Icon(
              Icons.cloud_rounded,
              color: const Color(0xFFE4EBF2),
              size: size * .78,
            ),
          ),
          for (final x in positions)
            Positioned(
              left: size * x - dropSize / 2,
              bottom: 0,
              child: Icon(
                Icons.water_drop_rounded,
                color: dropColor,
                size: dropSize,
              ),
            ),
        ],
      ),
    );
  }
}
