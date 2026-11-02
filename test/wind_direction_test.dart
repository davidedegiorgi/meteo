import 'package:flutter_test/flutter_test.dart';
import 'package:meteo/core/wind_direction.dart';

void main() {
  test('converte i gradi nei punti cardinali italiani', () {
    expect(WindDirection.label(0), 'N');
    expect(WindDirection.label(45), 'NE');
    expect(WindDirection.label(180), 'S');
    expect(WindDirection.label(225), 'SO');
    expect(WindDirection.label(270), 'O');
  });
}
