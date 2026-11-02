abstract final class WindDirection {
  static const _labels = [
    'N', 'NNE', 'NE', 'ENE',
    'E', 'ESE', 'SE', 'SSE',
    'S', 'SSO', 'SO', 'OSO',
    'O', 'ONO', 'NO', 'NNO',
  ];

  static String label(double degrees) {
    final normalized = ((degrees % 360) + 360) % 360;
    return _labels[(normalized / 22.5).round() % _labels.length];
  }
}
