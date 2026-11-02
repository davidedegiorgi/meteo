class MarineData {
  const MarineData({
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
    required this.time,
    required this.waveHeight,
    required this.waveDirection,
    required this.wavePeriod,
  });

  final double latitude;
  final double longitude;
  final DateTime fetchedAt;
  final DateTime time;
  final double waveHeight;
  final double waveDirection;
  final double wavePeriod;

  factory MarineData.fromApi(Map<String, dynamic> json) {
    final current = Map<String, dynamic>.from(json['current'] as Map);

    double value(String key) {
      final result = current[key];
      if (result is! num) {
        throw const FormatException(
          'Il modello non copre il punto marino più vicino.',
        );
      }
      return result.toDouble();
    }

    return MarineData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fetchedAt: DateTime.now(),
      time: DateTime.parse(current['time'] as String),
      waveHeight: value('wave_height'),
      waveDirection: value('wave_direction'),
      wavePeriod: value('wave_period'),
    );
  }

  factory MarineData.fromJson(Map<String, dynamic> json) => MarineData(
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    time: DateTime.parse(json['time'] as String),
    waveHeight: (json['waveHeight'] as num).toDouble(),
    waveDirection: (json['waveDirection'] as num).toDouble(),
    wavePeriod: (json['wavePeriod'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'fetchedAt': fetchedAt.toIso8601String(),
    'time': time.toIso8601String(),
    'waveHeight': waveHeight,
    'waveDirection': waveDirection,
    'wavePeriod': wavePeriod,
  };
}
