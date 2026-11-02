import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/city.dart';
import '../models/environmental_data.dart';
import '../models/laundry_index.dart';
import '../models/marine_data.dart';
import '../models/user_preferences.dart';
import '../models/weather_data.dart';
import '../services/local_database_service.dart';
import '../services/environmental_service.dart';
import '../services/location_service.dart';
import '../services/marine_service.dart';
import '../services/weather_service.dart';

enum WeatherViewState { loading, ready, offline, failure }

class WeatherProvider extends ChangeNotifier {
  WeatherProvider(
    this.weatherService,
    this.marineService,
    this.environmentalService,
    this.database,
    this.locationService,
  );
  final WeatherService weatherService;
  final MarineService marineService;
  final EnvironmentalService environmentalService;
  final LocalDatabaseService database;
  final LocationService locationService;
  WeatherViewState state = WeatherViewState.loading;
  WeatherData? weather;
  MarineData? marine;
  EnvironmentalData? environmental;
  List<City> favorites = [];
  Map<String, CityWeatherSnapshot> favoriteConditions = {};
  City? selectedCity;
  TemperatureUnit unit = TemperatureUnit.celsius;
  bool refreshing = false;
  bool marineLoading = false;
  bool environmentalLoading = false;
  String? message;
  String? marineMessage;
  String? environmentalMessage;
  double vesselHeading = 180;
  double vesselSpeed = 6;
  bool get offline => state == WeatherViewState.offline;
  bool get favorite =>
      selectedCity != null && favorites.any((x) => x.id == selectedCity!.id);
  LaundryIndex? get laundry => weather == null
      ? null
      : LaundryIndexCalculator.calculate(
          temperature: weather!.temperature,
          humidity: weather!.humidity,
          windSpeed: weather!.windSpeed,
          weatherCode: weather!.weatherCode,
          precipitation: weather!.precipitation,
        );
  String temp(double value) => '${unit.convert(value).round()}${unit.symbol}';

  Future<void> initialize() async {
    favorites = database.getFavoriteCities();
    unawaited(_loadFavoriteConditions());
    unit = database.getTemperatureUnit();
    weather = database.getLastWeather();
    marine = weather == null
        ? null
        : database.getCachedMarine(weather!.latitude, weather!.longitude);
    environmental = weather == null
        ? null
        : database.getCachedEnvironmental(
            weather!.latitude,
            weather!.longitude,
          );
    vesselHeading = database.getVesselHeading();
    vesselSpeed = database.getVesselSpeed();
    if (weather != null) {
      state = WeatherViewState.offline;
      message = 'Dati salvati: aggiornamento in corso…';
    }
    notifyListeners();
    if (weather == null && favorites.isNotEmpty) {
      await selectCity(favorites.first);
    } else {
      await useCurrentLocation();
    }
  }

  void _begin() {
    refreshing = weather != null;
    marine = null;
    marineMessage = null;
    environmentalMessage = null;
    marineLoading = weather != null;
    environmentalLoading = weather != null;
    if (weather == null) state = WeatherViewState.loading;
    message = null;
    notifyListeners();
  }

  void _fail(Object e) {
    refreshing = false;
    marineLoading = false;
    environmentalLoading = false;
    state = weather == null
        ? WeatherViewState.failure
        : WeatherViewState.offline;
    message = e.toString().replaceFirst('Exception: ', '');
    notifyListeners();
  }

  Future<void> useCurrentLocation() async {
    selectedCity = null;
    final cachedLocation = weather;
    _begin();
    if (cachedLocation != null) {
      unawaited(_loadMarine(cachedLocation.latitude, cachedLocation.longitude));
      unawaited(
        _loadEnvironmental(cachedLocation.latitude, cachedLocation.longitude),
      );
    }
    try {
      final p = await locationService.getCurrentPosition();
      await _load(p.latitude, p.longitude, 'Posizione attuale');
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> selectCity(City city) async {
    selectedCity = city;
    _begin();
    await _load(city.latitude, city.longitude, city.displayName);
  }

  Future<void> _load(double lat, double lon, String name) async {
    try {
      // La sezione marina aggiorna il proprio stato senza aspettare i modelli
      // terrestri, che possono impiegare più tempo quando c'è già una cache.
      unawaited(_loadMarine(lat, lon));
      unawaited(_loadEnvironmental(lat, lon));
      final result = await weatherService.getWeather(lat, lon, name);
      weather = result.data;
      state = result.fromCache
          ? WeatherViewState.offline
          : WeatherViewState.ready;
      message = result.fromCache
          ? 'Offline: mostro l’ultimo aggiornamento.'
          : null;
      refreshing = false;
      notifyListeners();
    } catch (e) {
      _fail(e);
    }
  }

  Future<void> _loadMarine(double lat, double lon) async {
    marineLoading = true;
    marineMessage = null;
    notifyListeners();
    try {
      final result = await marineService.getMarine(lat, lon);
      marine = result.data;
      marineMessage = result.fromCache
          ? 'Dati marini offline: ultimo aggiornamento disponibile.'
          : null;
    } catch (error) {
      marine = null;
      marineMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      marineLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadEnvironmental(double lat, double lon) async {
    environmentalLoading = true;
    environmentalMessage = null;
    notifyListeners();
    try {
      final result = await environmentalService.getData(lat, lon);
      environmental = result.data;
      environmentalMessage = result.fromCache
          ? 'Altri dati offline: ultimo aggiornamento disponibile.'
          : null;
    } catch (error) {
      environmentalMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      environmentalLoading = false;
      notifyListeners();
    }
  }

  Future<void> setVesselHeading(double value) async {
    vesselHeading = value;
    notifyListeners();
    await database.saveVesselHeading(value);
  }

  Future<void> setVesselSpeed(double value) async {
    vesselSpeed = value;
    notifyListeners();
    await database.saveVesselSpeed(value);
  }

  Future<void> refresh() =>
      selectedCity == null ? useCurrentLocation() : selectCity(selectedCity!);
  Future<List<City>> search(String q) => weatherService.searchCities(q);
  Future<CityWeatherSnapshot> currentConditions(City city) =>
      weatherService.getCurrentConditions(city);

  Future<void> _loadFavoriteConditions() async {
    final cities = List<City>.from(favorites);
    final entries = await Future.wait(
      cities.map((city) async {
        try {
          final snapshot = await currentConditions(city);
          return MapEntry(city.id, snapshot);
        } catch (_) {
          return null;
        }
      }),
    );
    favoriteConditions = {
      for (final entry in entries)
        if (entry != null) entry.key: entry.value,
    };
    notifyListeners();
  }

  Future<void> toggleFavorite() async {
    final c = selectedCity;
    if (c == null) return;
    favorites = favorite
        ? favorites.where((x) => x.id != c.id).toList()
        : [...favorites, c];
    notifyListeners();
    unawaited(_loadFavoriteConditions());
    await database.saveFavoriteCities(favorites);
  }

  Future<void> remove(City c) async {
    favorites = favorites.where((x) => x.id != c.id).toList();
    notifyListeners();
    unawaited(_loadFavoriteConditions());
    await database.saveFavoriteCities(favorites);
  }

  Future<void> toggleUnit() async {
    unit = unit == TemperatureUnit.celsius
        ? TemperatureUnit.fahrenheit
        : TemperatureUnit.celsius;
    notifyListeners();
    await database.saveTemperatureUnit(unit);
  }

  @override
  void dispose() {
    weatherService.dispose();
    marineService.dispose();
    environmentalService.dispose();
    super.dispose();
  }
}
