enum TemperatureUnit {
  celsius,
  fahrenheit;
  String get symbol => this == celsius ? '°C' : '°F';
  double convert(double value) => this == celsius ? value : value * 9 / 5 + 32;
  static TemperatureUnit parse(String? value) => value == 'fahrenheit' ? fahrenheit : celsius;
}
