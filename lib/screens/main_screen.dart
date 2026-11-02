import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../core/app_constants.dart';
import '../core/astronomy.dart';
import '../core/weather_code.dart';
import '../core/wind_direction.dart';
import '../models/city.dart';
import '../models/forecast_confidence.dart';
import '../models/weather_data.dart';
import '../providers/weather_provider.dart';
import '../services/rainviewer_service.dart';
import '../services/weather_ai_service.dart';
import '../services/weather_map_service.dart';
import '../services/weather_service.dart';
import '../widgets/global_weather_map.dart';
import '../widgets/marine_weather_section.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});
  @override
  Widget build(BuildContext context) => Consumer<WeatherProvider>(
    builder: (context, p, _) {
      final w = p.weather;
      final colors = w == null
          ? AppConstants.cloudy
          : WeatherCode.gradient(w.weatherCode, w.isDay, time: w.currentTime);
      return AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Scaffold(
          floatingActionButton: w == null
              ? null
              : FloatingActionButton.extended(
                  tooltip: 'Apri Meteo AI',
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    backgroundColor: Colors.transparent,
                    barrierColor: const Color(0x5200162A),
                    builder: (_) => _WeatherAiSheet(p),
                  ),
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text(
                    'Meteo AI',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(p),
                Expanded(child: w == null ? _Empty(p) : _Content(p, w)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar(this.p);
  final WeatherProvider p;

  @override
  Widget build(BuildContext context) {
    void openSearch() => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x5200162A),
      builder: (_) => _SearchSheet(p),
    );
    void openFavorites() => showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Chiudi preferiti',
      barrierColor: const Color(0x5200162A),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, _, _) => _FavoritesMenu(p),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: .96, end: 1.0).animate(animation),
          alignment: Alignment.topRight,
          child: child,
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 2, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Usa la posizione attuale',
                onPressed: p.useCurrentLocation,
                color: Colors.white,
                icon: const Icon(Icons.my_location_rounded),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Preferiti',
                onPressed: openFavorites,
                color: Colors.white,
                icon: Icon(
                  p.favorites.isEmpty
                      ? Icons.star_border_rounded
                      : Icons.star_rounded,
                ),
              ),
              TextButton(
                onPressed: p.toggleUnit,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: Text(
                  p.unit.symbol,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SearchBar(
                onTap: openSearch,
                hintText: 'Inserisci la tua città',
                leading: const Icon(Icons.search_rounded),
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  Colors.white.withValues(alpha: .94),
                ),
                hintStyle: const WidgetStatePropertyAll(
                  TextStyle(color: Color(0xFF455A64)),
                ),
                textStyle: const WidgetStatePropertyAll(
                  TextStyle(color: Color(0xFF263238)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoritesMenu extends StatelessWidget {
  const _FavoritesMenu(this.p);

  final WeatherProvider p;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: SafeArea(
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 48, right: 8, left: 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0B5C86).withValues(alpha: .76),
                          const Color(0xFF123A57).withValues(alpha: .64),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .32),
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: AnimatedBuilder(
                      animation: p,
                      builder: (context, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 5, 16, 8),
                            child: Text(
                              'Città preferite',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (p.favorites.isEmpty)
                            const Padding(
                              padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
                              child: Text(
                                'Nessuna città salvata',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          else
                            for (final city in p.favorites)
                              _FavoriteCityRow(p: p, city: city),
                          if (p.selectedCity != null) ...[
                            Divider(
                              color: Colors.white.withValues(alpha: .25),
                              height: 10,
                            ),
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                p.toggleFavorite();
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 11,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      p.favorite
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      color: const Color(0xFFFFD54F),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        p.favorite
                                            ? 'Rimuovi città corrente'
                                            : 'Aggiungi città corrente',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _FavoriteCityRow extends StatelessWidget {
  const _FavoriteCityRow({required this.p, required this.city});

  final WeatherProvider p;
  final City city;

  @override
  Widget build(BuildContext context) {
    final conditions = p.favoriteConditions[city.id];
    final selected = p.selectedCity?.id == city.id;
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        p.selectCity(city);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 26,
              child: conditions == null
                  ? const Padding(
                      padding: EdgeInsets.all(6),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : WeatherIcon(
                      code: conditions.weatherCode,
                      rainMm: conditions.precipitation,
                      isDay: conditions.isDay,
                      size: 25,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                city.displayName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.p);
  final WeatherProvider p;
  @override
  Widget build(BuildContext context) {
    if (p.state == WeatherViewState.loading)
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, color: Colors.white, size: 64),
            const SizedBox(height: 14),
            const Text(
              'Meteo non disponibile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              p.message ?? 'Controlla posizione e connessione.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: p.useCurrentLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Riprova'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content(this.p, this.w);
  final WeatherProvider p;
  final WeatherData w;
  @override
  Widget build(BuildContext context) {
    final laundry = p.laundry!;
    return RefreshIndicator(
      onRefresh: p.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          if (p.message != null) ...[const SizedBox(height: 12), _Banner(p)],
          const SizedBox(height: 12),
          _Hero(p, w),
          const SizedBox(height: 16),
          _Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.dry_cleaning, color: Colors.white),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Indice Stendi il Bucato',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Text(
                      '${laundry.score}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: laundry.progress,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(99),
                  color: laundry.score >= 70
                      ? Colors.lightGreenAccent
                      : Colors.amberAccent,
                  backgroundColor: Colors.white24,
                ),
                const SizedBox(height: 10),
                Text(
                  laundry.verdict,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _Title('Prossime ore'),
          const SizedBox(height: 10),
          _Hourly(p, w.upcomingHours),
          const SizedBox(height: 26),
          _Title('Tutti i giorni'),
          const SizedBox(height: 10),
          _Daily(p, w),
          const SizedBox(height: 26),
          _OtherData(p, w),
          const SizedBox(height: 26),
          MarineWeatherSection(provider: p, weather: w),
          const SizedBox(height: 26),
          GlobalWeatherMap(weather: w),
          const SizedBox(height: 26),
          _SunMoon(w),
        ],
      ),
    );
  }
}

class _SunMoon extends StatelessWidget {
  const _SunMoon(this.weather);
  final WeatherData weather;

  String _time(DateTime? value) {
    if (value == null) return '—';
    return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }

  String _duration(Duration? value) {
    if (value == null) return '—';
    final hours = value.inHours;
    final minutes = value.inMinutes.remainder(60);
    return '$hours h ${minutes.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    if (weather.daily.isEmpty) return const SizedBox.shrink();
    final today = weather.daily.first;
    final calculatedSun = SunInfo.calculate(
      today.date.copyWith(hour: 12),
      weather.latitude,
      weather.longitude,
    );
    final sunrise = today.sunrise ?? calculatedSun.rise;
    final sunset = today.sunset ?? calculatedSun.set;
    final moon = MoonInfo.calculate(
      today.date.copyWith(hour: 12),
      weather.latitude,
      weather.longitude,
    );
    Duration? daylight;
    if (sunrise != null && sunset != null) {
      daylight = sunset.difference(sunrise);
      if (daylight.isNegative) daylight += const Duration(days: 1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('Sole e Luna'),
        const SizedBox(height: 10),
        _Glass(
          child: Column(
            children: [
              _AstronomyRow(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.wb_sunny_rounded,
                    color: Colors.white,
                    size: 29,
                  ),
                ),
                title: 'SOLE',
                primary:
                    'Sorge: ${_time(sunrise)}   Tramonta: ${_time(sunset)}',
                secondary: 'Durata della luce: ${_duration(daylight)}',
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(color: Colors.white24, height: 1),
              ),
              _AstronomyRow(
                leading: Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF536DFE), Color(0xFF1A237E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Text(moon.emoji, style: const TextStyle(fontSize: 28)),
                ),
                title: 'LUNA',
                primary: 'Leva: ${_time(moon.rise)}   Cala: ${_time(moon.set)}',
                secondary:
                    '${moon.label} · Illuminata ${(moon.illumination * 100).round()}%',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AstronomyRow extends StatelessWidget {
  const _AstronomyRow({
    required this.leading,
    required this.title,
    required this.primary,
    required this.secondary,
  });

  final Widget leading;
  final String title;
  final String primary;
  final String secondary;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      leading,
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              primary,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              secondary,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    ],
  );
}

class _OtherData extends StatelessWidget {
  const _OtherData(this.provider, this.weather);

  final WeatherProvider provider;
  final WeatherData weather;

  @override
  Widget build(BuildContext context) {
    final data = provider.environmental;
    final parasite = _parasiteRisk(weather);
    final mushrooms = _mushroomForecast(weather);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('Altri dati'),
        const SizedBox(height: 10),
        if (provider.environmentalLoading && data == null)
          const _Glass(
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
                  'Caricamento qualità dell’aria e pollini…',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          )
        else
          _Glass(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _OtherDataTile(
                      width: width,
                      icon: Icons.air_rounded,
                      label: 'Qualità dell’aria',
                      value: data?.airQuality ?? 'Non disponibile',
                      detail: data == null
                          ? 'PM10'
                          : '${data.pm10.toStringAsFixed(1)} µg/m³ PM10',
                      color: const Color(0xFF69F0AE),
                    ),
                    _OtherDataTile(
                      width: width,
                      icon: Icons.grass_rounded,
                      label: 'Pollini',
                      value: data?.pollenLevel ?? 'Non disponibile',
                      detail: data == null
                          ? 'Indice composito'
                          : '${data.pollenComposite.toStringAsFixed(1)} grani/m³',
                      color: const Color(0xFFFFD54F),
                    ),
                    _OtherDataTile(
                      width: width,
                      icon: Icons.pets_rounded,
                      label: 'Parassiti animali',
                      value: parasite,
                      detail: 'Dirofilaria',
                      color: const Color(0xFFFF8A65),
                    ),
                    _OtherDataTile(
                      width: width,
                      icon: Icons.eco_rounded,
                      label: 'Crescita funghi',
                      value: mushrooms,
                      detail: 'Condizioni locali',
                      color: const Color(0xFFA5D6A7),
                    ),
                  ],
                );
              },
            ),
          ),
        if (data == null && provider.environmentalMessage != null) ...[
          const SizedBox(height: 7),
          Text(
            provider.environmentalMessage!,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ],
    );
  }

  static String _parasiteRisk(WeatherData weather) {
    if (weather.temperature >= 20 && weather.humidity >= 65) return 'Alto';
    if (weather.temperature >= 14 && weather.humidity >= 55) return 'Medio';
    return 'Basso';
  }

  static String _mushroomForecast(WeatherData weather) {
    final mild = weather.temperature >= 8 && weather.temperature <= 24;
    if (mild && weather.humidity >= 75 && weather.precipitation >= .5) {
      return 'Favoriti';
    }
    if (mild && weather.humidity >= 65) return 'Possibili';
    return 'Non previsti';
  }
}

class _OtherDataTile extends StatelessWidget {
  const _OtherDataTile({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 132),
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: Colors.white.withValues(alpha: .2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 25),
        const SizedBox(height: 9),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(detail, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    ),
  );
}

class _Hero extends StatefulWidget {
  const _Hero(this.p, this.w);
  final WeatherProvider p;
  final WeatherData w;

  @override
  State<_Hero> createState() => _HeroState();
}

class _HeroState extends State<_Hero> {
  final _heroKey = GlobalKey();
  Offset _gaze = Offset.zero;

  void _followPointer(PointerHoverEvent event) {
    final box = _heroKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final position = box.globalToLocal(event.position);
    final center = box.size.center(Offset.zero);
    final dx = ((position.dx - center.dx) / center.dx).clamp(-1.0, 1.0);
    final dy = ((position.dy - center.dy) / center.dy).clamp(-1.0, 1.0);
    final next = Offset(dx, dy);
    if ((next - _gaze).distance > .025) setState(() => _gaze = next);
  }

  @override
  Widget build(BuildContext context) {
    final confidence = ForecastConfidence.calculate(
      0,
      widget.w.daily.isEmpty
          ? widget.w.hourly
          : widget.w.hoursFor(widget.w.daily.first.date),
    );
    return MouseRegion(
      onHover: _followPointer,
      onExit: (_) => setState(() => _gaze = Offset.zero),
      child: KeyedSubtree(
        key: _heroKey,
        child: _Glass(
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      widget.w.locationName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.p.temp(widget.w.temperature),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          WeatherCode.description(widget.w.weatherCode),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Percepiti ${widget.p.temp(widget.w.apparentTemperature)}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      Icons.water_drop_outlined,
                      '${widget.w.humidity}%',
                      'Umidità',
                    ),
                  ),
                  Expanded(
                    child: _WindMetric(
                      speed: widget.w.windSpeed,
                      direction: widget.w.windDirection,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      Icons.umbrella_outlined,
                      '${widget.w.precipitation.toStringAsFixed(1)} mm',
                      'Pioggia',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _ConfidenceGauge(confidence),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.value, this.label);
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: Colors.white),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}

class _WindDirectionIcon extends StatelessWidget {
  const _WindDirectionIcon(this.direction, {this.size = 18});
  final double direction;
  final double size;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    // L’API indica la provenienza; la freccia mostra dove si dirige il flusso.
    angle: (direction + 180) * math.pi / 180,
    child: Icon(Icons.navigation_rounded, color: Colors.white, size: size),
  );
}

class _ConfidenceGauge extends StatelessWidget {
  const _ConfidenceGauge(this.value);
  final int value;

  Color get color {
    final normalized = value.clamp(0, 100);
    if (normalized <= 50) {
      return Color.lerp(
        const Color(0xFFE53935),
        const Color(0xFFFFC107),
        normalized / 50,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFFC107),
      const Color(0xFF43A047),
      (normalized - 50) / 50,
    )!;
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_outlined, color: Colors.white, size: 18),
        const SizedBox(width: 7),
        Text(
          'Attendibilità ${ForecastConfidence.label(value)}',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 9),
        SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value.clamp(0, 100) / 100,
                  strokeWidth: 5,
                  strokeCap: StrokeCap.round,
                  color: color,
                  backgroundColor: const Color(0x55E53935),
                ),
              ),
              Text(
                '$value%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ConfidenceRing extends StatelessWidget {
  const _ConfidenceRing(this.value, {this.size = 34});
  final int value;
  final double size;

  Color get color {
    final normalized = value.clamp(0, 100);
    if (normalized <= 50) {
      return Color.lerp(
        const Color(0xFFE53935),
        const Color(0xFFFFC107),
        normalized / 50,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFFC107),
      const Color(0xFF43A047),
      (normalized - 50) / 50,
    )!;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox.expand(
          child: CircularProgressIndicator(
            value: value.clamp(0, 100) / 100,
            strokeWidth: size <= 30 ? 3 : 4,
            strokeCap: StrokeCap.round,
            color: color,
            backgroundColor: const Color(0x55E53935),
          ),
        ),
        Text(
          '$value%',
          style: TextStyle(
            color: Colors.white,
            fontSize: size <= 30 ? 8 : 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _WindMetric extends StatelessWidget {
  const _WindMetric({required this.speed, required this.direction});
  final double speed, direction;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.air, color: Colors.white, size: 21),
          const SizedBox(width: 4),
          _WindDirectionIcon(direction, size: 17),
        ],
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${speed.round()} km/h ${WindDirection.label(direction)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      const Text('Vento', style: TextStyle(color: Colors.white, fontSize: 12)),
    ],
  );
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontSize: 22,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white.withValues(alpha: .14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
      side: BorderSide(color: Colors.white.withValues(alpha: .15)),
    ),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class _Hourly extends StatelessWidget {
  const _Hourly(this.p, this.items);
  final WeatherProvider p;
  final List<HourlyWeather> items;
  @override
  Widget build(BuildContext context) => _ExpandableHours(
    provider: p,
    items: items,
    maxItems: 12,
    showNow: true,
    compact: false,
  );
}

class _ExpandableHours extends StatefulWidget {
  const _ExpandableHours({
    required this.provider,
    required this.items,
    required this.compact,
    this.maxItems,
    this.showNow = false,
  });

  final WeatherProvider provider;
  final List<HourlyWeather> items;
  final bool compact;
  final int? maxItems;
  final bool showNow;

  @override
  State<_ExpandableHours> createState() => _ExpandableHoursState();
}

class _ExpandableHoursState extends State<_ExpandableHours> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final count = widget.maxItems == null
        ? widget.items.length
        : math.min(widget.maxItems!, widget.items.length);
    final selected = selectedIndex != null && selectedIndex! < count
        ? widget.items[selectedIndex!]
        : null;
    return Column(
      children: [
        SizedBox(
          height: widget.compact ? 202 : 216,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: count,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final hour = widget.items[i];
              return _HourTile(
                provider: widget.provider,
                hour: hour,
                compact: widget.compact,
                label: widget.showNow && i == 0
                    ? 'Ora'
                    : '${hour.time.hour.toString().padLeft(2, '0')}:00',
                expanded: selectedIndex == i,
                onToggle: () => setState(
                  () => selectedIndex = selectedIndex == i ? null : i,
                ),
              );
            },
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: selected == null
              ? const SizedBox.shrink()
              : Padding(
                  key: ValueKey(selected.time),
                  padding: const EdgeInsets.only(top: 10),
                  child: _HourDetails(widget.provider, selected),
                ),
        ),
      ],
    );
  }
}

class _HourTile extends StatelessWidget {
  const _HourTile({
    required this.provider,
    required this.hour,
    required this.compact,
    required this.label,
    required this.expanded,
    required this.onToggle,
  });

  final WeatherProvider provider;
  final HourlyWeather hour;
  final bool compact;
  final String label;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) => Container(
    width: compact ? 96 : 108,
    padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: WeatherCode.gradient(hour.code, hour.isDay, time: hour.time),
      ),
      borderRadius: BorderRadius.circular(compact ? 16 : 20),
      border: Border.all(
        color: expanded ? Colors.white : Colors.white.withValues(alpha: .22),
        width: expanded ? 2 : 1,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        WeatherIcon(code: hour.code, rainMm: hour.rainMm, isDay: hour.isDay),
        Text(
          provider.temp(hour.temperature),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${hour.rainChance}% · ${hour.rainMm.toStringAsFixed(1)} mm',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              _WindDirectionIcon(hour.windDirection, size: 13),
              const SizedBox(width: 3),
              Text(
                '${WindDirection.label(hour.windDirection)} · ${hour.windSpeed.round()} km/h',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 28,
          width: 28,
          child: IconButton(
            tooltip: expanded ? 'Chiudi dettagli' : 'Apri dettagli',
            onPressed: onToggle,
            padding: EdgeInsets.zero,
            iconSize: 21,
            color: Colors.white,
            icon: Icon(expanded ? Icons.remove_circle : Icons.add_circle),
          ),
        ),
      ],
    ),
  );
}

class _HourDetails extends StatelessWidget {
  const _HourDetails(this.provider, this.hour);

  final WeatherProvider provider;
  final HourlyWeather hour;

  @override
  Widget build(BuildContext context) {
    final showSnowLine = hour.rainMm > 0 || hour.rainChance >= 30;
    final snowLine = math.max(0, hour.freezingLevel - 300).round();
    final environmental = provider.environmental;
    final air = environmental?.forHour(hour.time);
    final airQuality = air?.quality ?? environmental?.airQuality;
    final airAqi = air?.europeanAqi ?? environmental?.europeanAqi;
    final airPm10 = air?.pm10 ?? environmental?.pm10;
    final cachedAirSuffix = air == null && environmental != null
        ? ' · ultimo dato'
        : '';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              WeatherIcon(
                code: hour.code,
                rainMm: hour.rainMm,
                isDay: hour.isDay,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  WeatherCode.description(hour.code),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HourMetric('Prob. prec.', '${hour.rainChance}%'),
              _HourMetric('Percepita', provider.temp(hour.apparentTemperature)),
              _HourMetric('Raffica', '${hour.windGust.round()} km/h'),
              _HourMetric('Umidità', '${hour.humidity}%'),
              _HourMetric(
                'Pressione',
                hour.pressure > 0 ? '${hour.pressure.round()} mb' : '–',
              ),
              _HourMetric(
                'Indice UV',
                '${hour.uvIndex.toStringAsFixed(1)} su 11',
              ),
              _AirQualityMetric(
                quality: airQuality,
                aqi: airAqi,
                suffix: cachedAirSuffix,
              ),
              _HourMetric(
                'PM10',
                airPm10 == null
                    ? 'Non disponibile'
                    : '${airPm10.toStringAsFixed(1)} µg/m³$cachedAirSuffix',
              ),
              _HourMetric('Quota neve', showSnowLine ? '$snowLine m' : '–'),
              _HourMetric(
                '0 termico',
                hour.freezingLevel > 0
                    ? '${hour.freezingLevel.round()} m'
                    : '–',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HourMetric extends StatelessWidget {
  const _HourMetric(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 128,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: const TextStyle(color: Colors.white)),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AirQualityMetric extends StatelessWidget {
  const _AirQualityMetric({
    required this.quality,
    required this.aqi,
    required this.suffix,
  });

  final String? quality;
  final double? aqi;
  final String suffix;

  int get score => (10 - (aqi ?? 100) / 10).round().clamp(0, 10);

  Color get color {
    final normalized = score.clamp(0, 10);
    if (normalized <= 5) {
      return Color.lerp(
        const Color(0xFFE53935),
        const Color(0xFFFFC107),
        normalized / 5,
      )!;
    }
    return Color.lerp(
      const Color(0xFFFFC107),
      const Color(0xFF43A047),
      (normalized - 5) / 5,
    )!;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 266,
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Qualità aria', style: TextStyle(color: Colors.white)),
              Text(
                quality == null || aqi == null
                    ? 'Non disponibile'
                    : '$quality · AQI ${aqi!.round()}$suffix',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        if (quality != null && aqi != null) ...[
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: score / 10,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _Daily extends StatelessWidget {
  const _Daily(this.p, this.weather);
  final WeatherProvider p;
  final WeatherData weather;
  static const days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white.withValues(alpha: .14),
    clipBehavior: Clip.antiAlias,
    child: ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: math.max(0, weather.daily.length - 1),
      separatorBuilder: (_, _) =>
          const Divider(color: Colors.white24, height: 1),
      itemBuilder: (_, i) {
        final dayIndex = i + 1;
        final day = weather.daily[dayIndex];
        final hours = weather.hoursFor(day.date);
        final confidence = ForecastConfidence.calculate(dayIndex, hours);
        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: WeatherIcon(
              code: day.code,
              rainMm: day.rainMm,
              dailyTotal: true,
            ),
            iconColor: Colors.white,
            collapsedIconColor: Colors.white,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${days[day.date.weekday - 1]} · ${day.date.day.toString().padLeft(2, '0')}/${day.date.month.toString().padLeft(2, '0')}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${p.temp(day.min)}  ${p.temp(day.max)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${WeatherCode.description(day.code)} · ${day.rainChance}% pioggia · ${day.rainMm.toStringAsFixed(1)} mm',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _WindDirectionIcon(day.windDirection, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Vento ${day.windMax.round()} km/h ${WindDirection.label(day.windDirection)} · Raffiche ${day.gustMax.round()} km/h',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Attendibilità',
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    const SizedBox(width: 3),
                    _ConfidenceRing(confidence, size: 28),
                  ],
                ),
              ],
            ),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            children: [
              if (hours.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Dettaglio orario non disponibile.',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              else
                _DayHours(p, hours),
            ],
          ),
        );
      },
    ),
  );
}

class _DayHours extends StatelessWidget {
  const _DayHours(this.p, this.items);
  final WeatherProvider p;
  final List<HourlyWeather> items;
  @override
  Widget build(BuildContext context) =>
      _ExpandableHours(provider: p, items: items, compact: true);
}

class _WeatherRadarMap extends StatefulWidget {
  const _WeatherRadarMap(this.weather);

  final WeatherData weather;

  @override
  State<_WeatherRadarMap> createState() => _WeatherRadarMapState();
}

class _WeatherRadarMapState extends State<_WeatherRadarMap> {
  final _radarService = const RainViewerService();
  final _mapService = const WeatherMapService();
  late Future<RadarTimeline> _timeline;
  late Future<WeatherMapTimeline> _mapTimeline;
  int _frameIndex = 0;
  int _overlayFrameIndex = 0;
  bool _showSnow = true;
  bool _isPlaying = false;
  Timer? _animationTimer;
  _WeatherLayer _selectedLayer = _WeatherLayer.radar;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _timeline = _radarService.loadTimeline();
    _mapTimeline = _mapService.loadArea(
      latitude: widget.weather.latitude,
      longitude: widget.weather.longitude,
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _isPlaying = false;
  }

  void _toggleAnimation({required int frameCount, required bool radar}) {
    if (_isPlaying) {
      setState(_stopAnimation);
      return;
    }
    setState(() => _isPlaying = true);
    _animationTimer = Timer.periodic(const Duration(milliseconds: 850), (_) {
      if (!mounted) return;
      setState(() {
        if (radar) {
          _frameIndex = (_frameIndex + 1) % frameCount;
        } else {
          _overlayFrameIndex = (_overlayFrameIndex + 1) % frameCount;
        }
      });
    });
  }

  String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.weather.latitude, widget.weather.longitude);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Title('Radar meteo'),
        const SizedBox(height: 5),
        const Text(
          'Pioggia, vento, nuvole e qualità dell’aria sulla stessa mappa',
          style: TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 430,
            child: FutureBuilder<RadarTimeline>(
              future: _timeline,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const ColoredBox(
                    color: Color(0x22000000),
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return ColoredBox(
                    color: const Color(0x22000000),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.radar,
                              color: Colors.white,
                              size: 40,
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Radar non disponibile',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => setState(_reload),
                              child: const Text('Riprova'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final timeline = snapshot.requireData;
                return FutureBuilder<WeatherMapTimeline>(
                  future: _mapTimeline,
                  builder: (context, mapSnapshot) {
                    if (mapSnapshot.hasError &&
                        _selectedLayer != _WeatherLayer.radar) {
                      return ColoredBox(
                        color: const Color(0x22000000),
                        child: Center(
                          child: FilledButton.icon(
                            onPressed: () => setState(_reload),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Ricarica livelli animati'),
                          ),
                        ),
                      );
                    }
                    if (!mapSnapshot.hasData &&
                        _selectedLayer != _WeatherLayer.radar) {
                      return const ColoredBox(
                        color: Color(0x22000000),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      );
                    }
                    return _buildMap(center, timeline, mapSnapshot.data);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap(
    LatLng center,
    RadarTimeline timeline,
    WeatherMapTimeline? mapTimeline,
  ) {
    final safeIndex = _frameIndex.clamp(0, timeline.frames.length - 1);
    final frame = timeline.frames[safeIndex];
    final overlayIndex = mapTimeline == null
        ? 0
        : _overlayFrameIndex.clamp(0, mapTimeline.frames.length - 1);
    final overlayFrame = mapTimeline?.frames[overlayIndex];
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 6.5),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'it.meteo.app',
              maxNativeZoom: 19,
            ),
            if (_selectedLayer == _WeatherLayer.radar)
              TileLayer(
                key: ValueKey('${frame.path}-$_showSnow'),
                urlTemplate: timeline.tileUrl(safeIndex, showSnow: _showSnow),
                userAgentPackageName: 'it.meteo.app',
                maxNativeZoom: 7,
              ),
            if (_selectedLayer != _WeatherLayer.radar)
              MarkerLayer(
                markers: (overlayFrame?.points ?? const [])
                    .map(_weatherMarker)
                    .toList(),
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_pin,
                    color: Color(0xFFE53935),
                    size: 42,
                  ),
                ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap'),
                TextSourceAttribution('RainViewer / Open-Meteo'),
              ],
            ),
          ],
        ),
        Positioned(
          left: 10,
          right: 10,
          top: 10,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _WeatherLayer.values.map((layer) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    avatar: Icon(_layerIcon(layer), size: 17),
                    label: Text(_layerName(layer)),
                    selected: _selectedLayer == layer,
                    onSelected: (_) => setState(() {
                      _stopAnimation();
                      _selectedLayer = layer;
                    }),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 12,
          child: _selectedLayer == _WeatherLayer.radar
              ? _radarControls(timeline, safeIndex, frame)
              : _overlayControls(mapTimeline!, overlayIndex, overlayFrame!),
        ),
      ],
    );
  }

  Marker _weatherMarker(WeatherMapPoint point) {
    final position = LatLng(point.latitude, point.longitude);
    return switch (_selectedLayer) {
      _WeatherLayer.wind => Marker(
        point: position,
        width: 54,
        height: 54,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xDD00695C),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: point.windDirection * math.pi / 180,
                child: const Icon(
                  Icons.navigation,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              Text(
                '${point.windSpeed.round()}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      _WeatherLayer.clouds => Marker(
        point: position,
        width: 120,
        height: 120,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                Colors.blueGrey.withValues(alpha: .18 + point.cloudCover / 125),
                Colors.blueGrey.withValues(alpha: 0),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${point.cloudCover}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 3, color: Colors.black)],
            ),
          ),
        ),
      ),
      _WeatherLayer.airQuality => Marker(
        point: position,
        width: 90,
        height: 90,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _aqiColor(point.airQualityIndex).withValues(alpha: .9),
                _aqiColor(point.airQualityIndex).withValues(alpha: 0),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '${point.airQualityIndex}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
      _WeatherLayer.radar => throw StateError('Marker non richiesto'),
    };
  }

  Widget _radarControls(
    RadarTimeline timeline,
    int safeIndex,
    RadarFrame frame,
  ) => Material(
    color: Colors.black.withValues(alpha: .72),
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.radar, color: Colors.white, size: 18),
              const SizedBox(width: 7),
              Text(
                'Pioggia alle ${_time(frame.time)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: _isPlaying ? 'Pausa' : 'Anima radar',
                onPressed: () => _toggleAnimation(
                  frameCount: timeline.frames.length,
                  radar: true,
                ),
                color: Colors.white,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
              ),
              FilterChip(
                label: const Text('Neve'),
                selected: _showSnow,
                onSelected: (value) => setState(() => _showSnow = value),
              ),
            ],
          ),
          Slider(
            value: safeIndex.toDouble(),
            min: 0,
            max: (timeline.frames.length - 1).toDouble(),
            divisions: timeline.frames.length - 1,
            label: _time(frame.time),
            onChanged: (value) => setState(() {
              _stopAnimation();
              _frameIndex = value.round();
            }),
          ),
        ],
      ),
    ),
  );

  Widget _overlayControls(
    WeatherMapTimeline timeline,
    int frameIndex,
    WeatherMapFrame frame,
  ) {
    final text = switch (_selectedLayer) {
      _WeatherLayer.wind => 'Frecce: direzione · Numero: km/h',
      _WeatherLayer.clouds => 'Copertura nuvolosa in percentuale',
      _WeatherLayer.airQuality => 'AQI UE: verde buono · rosso scarso',
      _WeatherLayer.radar => '',
    };
    return Material(
      color: Colors.black.withValues(alpha: .72),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(_layerIcon(_selectedLayer), color: Colors.white, size: 18),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    '${_layerName(_selectedLayer)} · ${_time(frame.time)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _isPlaying ? 'Pausa' : 'Avvia animazione',
                  onPressed: () => _toggleAnimation(
                    frameCount: timeline.frames.length,
                    radar: false,
                  ),
                  color: Colors.white,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                ),
              ],
            ),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
            Slider(
              value: frameIndex.toDouble(),
              min: 0,
              max: (timeline.frames.length - 1).toDouble(),
              divisions: timeline.frames.length - 1,
              label: _time(frame.time),
              onChanged: (value) => setState(() {
                _stopAnimation();
                _overlayFrameIndex = value.round();
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _layerName(_WeatherLayer layer) => switch (layer) {
    _WeatherLayer.radar => 'Pioggia',
    _WeatherLayer.wind => 'Vento',
    _WeatherLayer.clouds => 'Nuvole',
    _WeatherLayer.airQuality => 'Qualità aria',
  };

  IconData _layerIcon(_WeatherLayer layer) => switch (layer) {
    _WeatherLayer.radar => Icons.water_drop_outlined,
    _WeatherLayer.wind => Icons.air,
    _WeatherLayer.clouds => Icons.cloud_outlined,
    _WeatherLayer.airQuality => Icons.eco_outlined,
  };

  Color _aqiColor(int value) {
    if (value <= 20) return const Color(0xFF2E7D32);
    if (value <= 40) return const Color(0xFF8BC34A);
    if (value <= 60) return const Color(0xFFF9A825);
    if (value <= 80) return const Color(0xFFEF6C00);
    if (value <= 100) return const Color(0xFFC62828);
    return const Color(0xFF6A1B9A);
  }
}

enum _WeatherLayer { radar, wind, clouds, airQuality }

class _Banner extends StatelessWidget {
  const _Banner(this.p);
  final WeatherProvider p;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(
          p.offline ? Icons.cloud_off : Icons.info_outline,
          color: Colors.white,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(p.message!, style: const TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

class _AiMessage {
  const _AiMessage(this.text, {required this.user});
  final String text;
  final bool user;
}

class _WeatherAiSheet extends StatefulWidget {
  const _WeatherAiSheet(this.provider);
  final WeatherProvider provider;

  @override
  State<_WeatherAiSheet> createState() => _WeatherAiSheetState();
}

class _WeatherAiSheetState extends State<_WeatherAiSheet> {
  static const ai = WeatherAiService();
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final messages = <_AiMessage>[
    const _AiMessage(
      'Ciao! Chiedimi liberamente qualsiasi cosa sulla tua giornata: come vestirti, quando uscire, attività, viaggi, pioggia, vento, mare, sole, aria o salute. Userò tutti i dati meteo della località selezionata per darti una risposta mirata.',
      user: false,
    ),
  ];
  bool thinking = false;

  static const suggestions = [
    'Come mi vesto?',
    'Quando conviene uscire oggi?',
    'Posso organizzare una cena fuori?',
    'Come sarà la giornata domani?',
    'Mi serve l’ombrello stasera?',
    'È una buona giornata per andare in bici?',
  ];

  Future<void> send([String? suggested]) async {
    final question = (suggested ?? controller.text).trim();
    final weather = widget.provider.weather;
    if (question.isEmpty || weather == null || thinking) return;
    String? previousQuestion;
    for (final message in messages.reversed) {
      if (message.user) {
        previousQuestion = message.text;
        break;
      }
    }
    controller.clear();
    setState(() {
      messages.add(_AiMessage(question, user: true));
      thinking = true;
    });
    _scrollToBottom();
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    final response = ai.answer(
      question: question,
      weather: weather,
      temperature: widget.provider.temp,
      previousQuestion: previousQuestion,
      marine: widget.provider.marine,
      environmental: widget.provider.environmental,
      laundry: widget.provider.laundry,
    );
    setState(() {
      messages.add(_AiMessage(response, user: false));
      thinking = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B5C86).withValues(alpha: .72),
              const Color(0xFF123A57).withValues(alpha: .58),
            ],
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: .32)),
          ),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              onSurface: Colors.white,
              surfaceContainerLow: Colors.white.withValues(alpha: .14),
              surfaceContainerHighest: Colors.white.withValues(alpha: .16),
            ),
            dividerColor: Colors.white.withValues(alpha: .22),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white.withValues(alpha: .92),
              hintStyle: const TextStyle(color: Color(0xFF546E7A)),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .86,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C63FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Meteo AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Chiudi',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      scrollDirection: Axis.horizontal,
                      itemCount: suggestions.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (_, index) => ActionChip(
                        avatar: const Icon(
                          Icons.bolt_rounded,
                          size: 17,
                          color: Color(0xFF5148D8),
                        ),
                        label: Text(
                          suggestions[index],
                          style: const TextStyle(
                            color: Color(0xFF263238),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: .92),
                        disabledColor: Colors.white.withValues(alpha: .55),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: .45),
                        ),
                        onPressed: thinking
                            ? null
                            : () => send(suggestions[index]),
                      ),
                    ),
                  ),
                  const Divider(height: 18),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
                      itemCount: messages.length + (thinking ? 1 : 0),
                      itemBuilder: (_, index) {
                        if (thinking && index == messages.length) {
                          return const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }
                        final message = messages[index];
                        return Align(
                          alignment: message.user
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width * .8,
                            ),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color: message.user
                                  ? const Color(0xFF6C63FF)
                                  : Colors.white.withValues(alpha: .16),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Text(
                              message.text,
                              style: TextStyle(
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: controller,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => send(),
                            style: const TextStyle(color: Color(0xFF263238)),
                            decoration: InputDecoration(
                              hintText: 'Chiedi qualcosa sul meteo…',
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          tooltip: 'Invia domanda',
                          onPressed: thinking ? null : () => send(),
                          icon: const Icon(Icons.arrow_upward_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _SearchSheet extends StatefulWidget {
  const _SearchSheet(this.p);
  final WeatherProvider p;
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final controller = TextEditingController();
  List<City> results = [];
  Map<String, CityWeatherSnapshot> currentConditions = {};
  bool loading = false;
  String? error;
  Timer? debounce;
  int requestVersion = 0;

  void onQueryChanged(String value) {
    debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      requestVersion++;
      setState(() {
        results = [];
        currentConditions = {};
        loading = false;
        error = null;
      });
      return;
    }
    debounce = Timer(const Duration(milliseconds: 300), () => search(query));
  }

  Future<void> search([String? submittedQuery]) async {
    final query = (submittedQuery ?? controller.text).trim();
    if (query.length < 2) return;
    final version = ++requestVersion;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final found = await widget.p.search(query);
      if (!mounted || version != requestVersion) return;
      setState(() {
        results = found;
        currentConditions = {};
        loading = false;
      });
      unawaited(loadCurrentConditions(found, version));
    } catch (e) {
      if (!mounted || version != requestVersion) return;
      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
        loading = false;
      });
    }
  }

  Future<void> loadCurrentConditions(List<City> cities, int version) async {
    final entries = await Future.wait(
      cities.map((city) async {
        try {
          final snapshot = await widget.p.currentConditions(city);
          return MapEntry(city.id, snapshot);
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted || version != requestVersion) return;
    setState(() {
      currentConditions = {
        for (final entry in entries)
          if (entry != null) entry.key: entry.value,
      };
    });
  }

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0B5C86).withValues(alpha: .62),
              const Color(0xFF123A57).withValues(alpha: .48),
            ],
          ),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: .32)),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.viewInsetsOf(context).bottom + 20,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cerca una città',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SearchBar(
                    controller: controller,
                    autoFocus: true,
                    hintText: 'Roma, Milano, Torino…',
                    leading: const Icon(Icons.search),
                    backgroundColor: WidgetStatePropertyAll(
                      Colors.white.withValues(alpha: .9),
                    ),
                    elevation: const WidgetStatePropertyAll(0),
                    trailing: [
                      IconButton(
                        onPressed: () {
                          debounce?.cancel();
                          search();
                        },
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                    onChanged: onQueryChanged,
                    onSubmitted: (value) {
                      debounce?.cancel();
                      search(value);
                    },
                  ),
                  if (loading)
                    const LinearProgressIndicator(color: Colors.white),
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Color(0xFFFFCDD2)),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (_, i) {
                        final c = results[i];
                        final conditions = currentConditions[c.id];
                        return ListTile(
                          leading: SizedBox.square(
                            dimension: 30,
                            child: conditions == null
                                ? const Padding(
                                    padding: EdgeInsets.all(7),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : WeatherIcon(
                                    code: conditions.weatherCode,
                                    rainMm: conditions.precipitation,
                                    isDay: conditions.isDay,
                                    size: 28,
                                  ),
                          ),
                          title: Text(
                            c.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            c.country ?? '',
                            style: const TextStyle(color: Colors.white),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.p.selectCity(c);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
