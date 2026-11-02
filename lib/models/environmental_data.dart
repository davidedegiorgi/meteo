class HourlyAirQuality {
  const HourlyAirQuality({
    required this.time,
    required this.pm10,
    required this.europeanAqi,
  });

  final DateTime time;
  final double pm10;
  final double europeanAqi;

  String get quality => EnvironmentalData.airQualityLabel(europeanAqi);

  factory HourlyAirQuality.fromJson(Map<String, dynamic> json) =>
      HourlyAirQuality(
        time: DateTime.parse(json['time'] as String),
        pm10: (json['pm10'] as num? ?? 0).toDouble(),
        europeanAqi: (json['europeanAqi'] as num? ?? 0).toDouble(),
      );

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'pm10': pm10,
    'europeanAqi': europeanAqi,
  };
}

class EnvironmentalData {
  const EnvironmentalData({
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
    required this.pm10,
    required this.europeanAqi,
    required this.uvIndex,
    required this.pollenComposite,
    required this.hourly,
  });

  final double latitude;
  final double longitude;
  final DateTime fetchedAt;
  final double pm10;
  final double europeanAqi;
  final double uvIndex;
  final double pollenComposite;
  final List<HourlyAirQuality> hourly;

  static String airQualityLabel(double aqi) => switch (aqi) {
    <= 20 => 'Ottima',
    <= 40 => 'Buona',
    <= 60 => 'Media',
    <= 80 => 'Scarsa',
    <= 100 => 'Molto scarsa',
    _ => 'Pessima',
  };

  String get airQuality => airQualityLabel(europeanAqi);

  HourlyAirQuality? forHour(DateTime target) {
    for (final item in hourly) {
      if (item.time.year == target.year &&
          item.time.month == target.month &&
          item.time.day == target.day &&
          item.time.hour == target.hour) {
        return item;
      }
    }
    return null;
  }

  String get pollenLevel => switch (pollenComposite) {
    < 1 => 'Basso',
    < 10 => 'Medio',
    < 50 => 'Alto',
    _ => 'Molto alto',
  };

  String get uvLevel => switch (uvIndex) {
    < 3 => 'Basso',
    < 6 => 'Moderato',
    < 8 => 'Alto',
    < 11 => 'Molto alto',
    _ => 'Estremo',
  };

  factory EnvironmentalData.fromApi(Map<String, dynamic> json) {
    final current = Map<String, dynamic>.from(json['current'] as Map? ?? {});
    double value(String key) => switch (current[key]) {
      final num result => result.toDouble(),
      _ => 0,
    };
    final pollen = [
      'alder_pollen',
      'birch_pollen',
      'grass_pollen',
      'mugwort_pollen',
      'olive_pollen',
      'ragweed_pollen',
    ].map(value).fold<double>(0, (highest, item) => item > highest ? item : highest);
    var uvToday = value('uv_index');
    final currentTime = DateTime.tryParse(current['time'] as String? ?? '');
    final hourly = Map<String, dynamic>.from(json['hourly'] as Map? ?? {});
    final times = hourly['time'] as List? ?? const [];
    final uvValues = hourly['uv_index'] as List? ?? const [];
    final pm10Values = hourly['pm10'] as List? ?? const [];
    final aqiValues = hourly['european_aqi'] as List? ?? const [];
    final hourlyAirQuality = <HourlyAirQuality>[];
    for (var index = 0; index < times.length; index++) {
      final time = DateTime.tryParse(times[index] as String? ?? '');
      final pm10 = index < pm10Values.length ? pm10Values[index] : null;
      final aqi = index < aqiValues.length ? aqiValues[index] : null;
      if (time != null && pm10 is num && aqi is num) {
        hourlyAirQuality.add(
          HourlyAirQuality(
            time: time,
            pm10: pm10.toDouble(),
            europeanAqi: aqi.toDouble(),
          ),
        );
      }
    }
    for (var index = 0; index < times.length && index < uvValues.length; index++) {
      final time = DateTime.tryParse(times[index] as String? ?? '');
      final uv = uvValues[index];
      if (time != null &&
          uv is num &&
          currentTime != null &&
          time.year == currentTime.year &&
          time.month == currentTime.month &&
          time.day == currentTime.day &&
          uv.toDouble() > uvToday) {
        uvToday = uv.toDouble();
      }
    }
    return EnvironmentalData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fetchedAt: DateTime.now(),
      pm10: value('pm10'),
      europeanAqi: value('european_aqi'),
      uvIndex: uvToday,
      pollenComposite: pollen,
      hourly: hourlyAirQuality,
    );
  }

  factory EnvironmentalData.fromJson(Map<String, dynamic> json) =>
      EnvironmentalData(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        fetchedAt: DateTime.parse(json['fetchedAt'] as String),
        pm10: (json['pm10'] as num).toDouble(),
        europeanAqi: (json['europeanAqi'] as num).toDouble(),
        uvIndex: (json['uvIndex'] as num).toDouble(),
        pollenComposite: (json['pollenComposite'] as num).toDouble(),
        hourly: (json['hourly'] as List<dynamic>? ?? const [])
            .map(
              (item) => HourlyAirQuality.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList(),
      );

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'fetchedAt': fetchedAt.toIso8601String(),
    'pm10': pm10,
    'europeanAqi': europeanAqi,
    'uvIndex': uvIndex,
    'pollenComposite': pollenComposite,
    'hourly': hourly.map((item) => item.toJson()).toList(),
  };
}
