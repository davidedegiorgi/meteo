import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/wind_direction.dart';
import '../models/weather_data.dart';
import '../providers/weather_provider.dart';

class MarineWeatherSection extends StatelessWidget {
  const MarineWeatherSection({
    required this.provider,
    required this.weather,
    super.key,
  });

  final WeatherProvider provider;
  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final marine = provider.marine;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Previsioni marine',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (provider.marineLoading)
          const _MarineCard(
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Caricamento condizioni del mare…',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          )
        else if (marine == null)
          _MarineCard(
            child: Row(
              children: [
                const Icon(Icons.waves_rounded, color: Colors.white, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    provider.marineMessage ??
                        'Dati del mare non disponibili per questa posizione.',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        else
          _MarineCard(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 680
                    ? (constraints.maxWidth - 36) / 4
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 18,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _MarineValue(
                        icon: Icons.air_rounded,
                        value: '${weather.windSpeed.round()} km/h',
                        label: 'Vento mare',
                        direction: weather.windDirection,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _MarineValue(
                        icon: Icons.waves_rounded,
                        value: '${(marine.waveHeight * 100).round()} cm',
                        label: 'Altezza onda',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _MarineValue(
                        icon: Icons.timer_outlined,
                        value: '${marine.wavePeriod.toStringAsFixed(1)} s',
                        label: 'Periodo onda',
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _MarineValue(
                        icon: Icons.navigation_rounded,
                        value:
                            '${WindDirection.label(marine.waveDirection)} · ${marine.waveDirection.round()}°',
                        label: 'Direzione onda',
                        direction: marine.waveDirection,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class _MarineCard extends StatelessWidget {
  const _MarineCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0277BD), Color(0xFF01579B)],
      ),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: Colors.white.withValues(alpha: .18)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x26000000),
          blurRadius: 12,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

class _MarineValue extends StatelessWidget {
  const _MarineValue({
    required this.icon,
    required this.value,
    required this.label,
    this.direction,
  });

  final IconData icon;
  final String value;
  final String label;
  final double? direction;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (direction == null)
        Icon(icon, color: Colors.white, size: 24)
      else
        Transform.rotate(
          angle: (direction! + 180) * math.pi / 180,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      const SizedBox(height: 7),
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          value,
          maxLines: 1,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ],
  );
}
