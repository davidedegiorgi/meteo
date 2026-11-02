import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/models/marine_data.dart';

void main() {
  test('legge altezza, direzione e periodo dalla Marine API', () {
    final data = MarineData.fromApi({
      'latitude': 40.2,
      'longitude': 17.9,
      'current': {
        'time': '2026-10-22T16:45',
        'wave_height': .84,
        'wave_direction': 203,
        'wave_period': 5.25,
      },
    });

    expect(data.waveHeight, .84);
    expect(data.waveDirection, 203);
    expect(data.wavePeriod, 5.25);
  });

  test('rifiuta punti senza copertura marina', () {
    expect(
      () => MarineData.fromApi({
        'latitude': 0,
        'longitude': 0,
        'current': {
          'time': '2026-10-22T16:45',
          'wave_height': null,
          'wave_direction': null,
          'wave_period': null,
        },
      }),
      throwsFormatException,
    );
  });
}
