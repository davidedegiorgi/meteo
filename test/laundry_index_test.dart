import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/models/laundry_index.dart';

void main() {
  test('indice ideale', () {
    final x = LaundryIndexCalculator.calculate(
      temperature: 30,
      humidity: 30,
      windSpeed: 25,
      weatherCode: 0,
      precipitation: 0,
    );
    expect(x.score, 100);
    expect(x.hours, 1.5);
  });
  test('pioggia limita indice', () {
    final x = LaundryIndexCalculator.calculate(
      temperature: 30,
      humidity: 30,
      windSpeed: 25,
      weatherCode: 63,
      precipitation: 2,
    );
    expect(x.score, 25);
    expect(x.hours, isNull);
  });
}
