import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_constants.dart';
import '../models/environmental_data.dart';
import 'environmental_transport.dart';
import 'local_database_service.dart';

class EnvironmentalResult {
  const EnvironmentalResult(this.data, this.fromCache);
  final EnvironmentalData data;
  final bool fromCache;
}

class EnvironmentalService {
  EnvironmentalService(this.database, [http.Client? client])
    : client = client ?? http.Client();

  static const _url =
      'https://air-quality-api.open-meteo.com/v1/air-quality';
  final LocalDatabaseService database;
  final http.Client client;

  Future<EnvironmentalResult> getData(double lat, double lon) async {
    try {
      final uri = Uri.parse(_url).replace(
        queryParameters: {
          'latitude': '$lat',
          'longitude': '$lon',
          'timezone': 'auto',
          'domains': 'auto',
          'current': 'pm10,european_aqi',
          'hourly': 'pm10,european_aqi',
          'forecast_days': '7',
          'past_days': '1',
        },
      );
      final pollenUri = Uri.parse(_url).replace(
        queryParameters: {
          'latitude': '$lat',
          'longitude': '$lon',
          'timezone': 'auto',
          'domains': 'cams_europe',
          'current':
              'alder_pollen,birch_pollen,grass_pollen,mugwort_pollen,olive_pollen,ragweed_pollen',
        },
      );
      final pollenFuture = fetchEnvironmental(
        pollenUri,
        client,
      ).timeout(AppConstants.timeout).then<EnvironmentalHttpResponse?>(
        (response) => response,
        onError: (_) => null,
      );
      final response = await fetchEnvironmental(
        uri,
        client,
      ).timeout(AppConstants.timeout);
      if (response.statusCode != 200) {
        throw Exception('Qualità aria: errore ${response.statusCode}');
      }
      final json = Map<String, dynamic>.from(
        jsonDecode(response.body) as Map,
      );
      final pollenResponse = await pollenFuture;
      if (pollenResponse?.statusCode == 200) {
        final pollenJson = Map<String, dynamic>.from(
          jsonDecode(pollenResponse!.body) as Map,
        );
        final current = Map<String, dynamic>.from(
          json['current'] as Map? ?? const {},
        );
        final pollenCurrent = Map<String, dynamic>.from(
          pollenJson['current'] as Map? ?? const {},
        );
        for (final key in [
          'alder_pollen',
          'birch_pollen',
          'grass_pollen',
          'mugwort_pollen',
          'olive_pollen',
          'ragweed_pollen',
        ]) {
          current[key] = pollenCurrent[key] ?? 0;
        }
        json['current'] = current;
      }
      final data = EnvironmentalData.fromApi(json);
      unawaited(database.cacheEnvironmental(lat, lon, data));
      return EnvironmentalResult(data, false);
    } catch (_) {
      final cached = database.getCachedEnvironmental(lat, lon);
      if (cached != null) return EnvironmentalResult(cached, true);
      throw Exception('Altri dati non disponibili per questa posizione.');
    }
  }

  void dispose() => client.close();
}
