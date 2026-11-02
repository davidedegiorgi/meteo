import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_constants.dart';
import '../models/marine_data.dart';
import 'local_database_service.dart';
import 'marine_transport.dart';

class MarineResult {
  const MarineResult(this.data, this.fromCache);
  final MarineData data;
  final bool fromCache;
}

class MarineService {
  MarineService(this.database, [http.Client? client])
    : client = client ?? http.Client();

  static const _url = 'https://marine-api.open-meteo.com/v1/marine';
  final LocalDatabaseService database;
  final http.Client client;

  Future<MarineResult> getMarine(double lat, double lon) async {
    try {
      final uri = Uri.parse(_url).replace(
        queryParameters: {
          'latitude': '$lat',
          'longitude': '$lon',
          'timezone': 'auto',
          'forecast_days': '7',
          'cell_selection': 'sea',
          'current': 'wave_height,wave_direction,wave_period',
        },
      );
      final response = await fetchMarine(uri, client).timeout(
        AppConstants.timeout,
      );
      if (response.statusCode != 200) {
        throw Exception('Open-Meteo Marine: errore ${response.statusCode}');
      }
      final data = MarineData.fromApi(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      );
      // La UI non deve restare bloccata in attesa del backend di
      // SharedPreferences (sul Web può essere lento o già occupato).
      unawaited(database.cacheMarine(lat, lon, data));
      return MarineResult(data, false);
    } catch (error) {
      final cached = database.getCachedMarine(lat, lon);
      if (cached != null) return MarineResult(cached, true);
      throw Exception(
        'Dati marini non disponibili per questa posizione. '
        'Riprova tra poco (${error.toString().replaceFirst('Exception: ', '')}).',
      );
    }
  }

  void dispose() => client.close();
}
