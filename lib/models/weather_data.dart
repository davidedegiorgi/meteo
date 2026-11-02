class HourlyWeather {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.code,
    required this.rainChance,
    required this.rainMm,
    required this.humidity,
    required this.windSpeed,
    required this.windGust,
    required this.windDirection,
    required this.cloudCover,
    required this.pressure,
    required this.uvIndex,
    required this.freezingLevel,
    required this.isDay,
  });
  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final int code;
  final int rainChance;
  final double rainMm;
  final int humidity;
  final double windSpeed;
  final double windGust;
  final double windDirection;
  final int cloudCover;
  final double pressure;
  final double uvIndex;
  final double freezingLevel;
  final bool isDay;

  factory HourlyWeather.fromJson(Map<String, dynamic> json) => HourlyWeather(
    time: DateTime.parse(json['time'] as String),
    temperature: (json['temperature'] as num).toDouble(),
    apparentTemperature:
        (json['apparentTemperature'] as num? ?? json['temperature'] as num)
            .toDouble(),
    code: (json['code'] as num).toInt(),
    rainChance: (json['rainChance'] as num).toInt(),
    rainMm: (json['rainMm'] as num? ?? 0).toDouble(),
    humidity: (json['humidity'] as num? ?? 0).toInt(),
    windSpeed: (json['windSpeed'] as num? ?? 0).toDouble(),
    windGust: (json['windGust'] as num? ?? json['windSpeed'] as num? ?? 0)
        .toDouble(),
    windDirection: (json['windDirection'] as num? ?? 0).toDouble(),
    cloudCover: (json['cloudCover'] as num? ?? 0).toInt(),
    pressure: (json['pressure'] as num? ?? 0).toDouble(),
    uvIndex: (json['uvIndex'] as num? ?? 0).toDouble(),
    freezingLevel: _cachedFreezingLevel(json),
    isDay:
        json['isDay'] as bool? ??
        _fallbackIsDay(DateTime.parse(json['time'] as String)),
  );

  static bool _fallbackIsDay(DateTime time) => time.hour >= 7 && time.hour < 19;

  static double _cachedFreezingLevel(Map<String, dynamic> json) {
    final stored = (json['freezingLevel'] as num? ?? 0).toDouble();
    if (stored > 0) return stored;
    final temperature = (json['temperature'] as num? ?? 0).toDouble();
    // Stima di riserva con gradiente termico standard (6,5 °C ogni 1000 m).
    return (temperature * 153.8).clamp(0, 6000).toDouble();
  }

  Map<String, dynamic> toJson() => {
    'time': time.toIso8601String(),
    'temperature': temperature,
    'apparentTemperature': apparentTemperature,
    'code': code,
    'rainChance': rainChance,
    'rainMm': rainMm,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'windGust': windGust,
    'windDirection': windDirection,
    'cloudCover': cloudCover,
    'pressure': pressure,
    'uvIndex': uvIndex,
    'freezingLevel': freezingLevel,
    'isDay': isDay,
  };
}

class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.max,
    required this.min,
    required this.code,
    required this.rainChance,
    required this.rainMm,
    required this.windMax,
    required this.gustMax,
    required this.windDirection,
    required this.sunrise,
    required this.sunset,
  });
  final DateTime date;
  final double max;
  final double min;
  final int code;
  final int rainChance;
  final double rainMm;
  final double windMax;
  final double gustMax;
  final double windDirection;
  final DateTime? sunrise;
  final DateTime? sunset;

  factory DailyWeather.fromJson(Map<String, dynamic> json) => DailyWeather(
    date: DateTime.parse(json['date'] as String),
    max: (json['max'] as num).toDouble(),
    min: (json['min'] as num).toDouble(),
    code: (json['code'] as num).toInt(),
    rainChance: (json['rainChance'] as num).toInt(),
    rainMm: (json['rainMm'] as num? ?? 0).toDouble(),
    windMax: (json['windMax'] as num? ?? 0).toDouble(),
    gustMax: (json['gustMax'] as num? ?? 0).toDouble(),
    windDirection: (json['windDirection'] as num? ?? 0).toDouble(),
    sunrise: DateTime.tryParse(json['sunrise'] as String? ?? ''),
    sunset: DateTime.tryParse(json['sunset'] as String? ?? ''),
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'max': max,
    'min': min,
    'code': code,
    'rainChance': rainChance,
    'rainMm': rainMm,
    'windMax': windMax,
    'gustMax': gustMax,
    'windDirection': windDirection,
    'sunrise': sunrise?.toIso8601String(),
    'sunset': sunset?.toIso8601String(),
  };
}

class WeatherData {
  const WeatherData({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.fetchedAt,
    required this.currentTime,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.windSpeed,
    required this.windGust,
    required this.windDirection,
    required this.precipitation,
    required this.weatherCode,
    required this.isDay,
    required this.hourly,
    required this.daily,
  });
  final String locationName;
  final double latitude,
      longitude,
      temperature,
      apparentTemperature,
      windSpeed,
      windGust,
      windDirection,
      precipitation;
  final DateTime fetchedAt;
  final DateTime currentTime;
  final int humidity, weatherCode;
  final bool isDay;
  final List<HourlyWeather> hourly;
  final List<DailyWeather> daily;

  factory WeatherData.fromJson(
    Map<String, dynamic> json, {
    String? locationName,
  }) {
    if (!json.containsKey('current')) return WeatherData._fromCache(json);
    final current = json['current'] as Map<String, dynamic>;
    final hourlyJson = json['hourly'] as Map<String, dynamic>;
    final dailyJson = json['daily'] as Map<String, dynamic>;
    final hourlyTimes = hourlyJson['time'] as List<dynamic>;
    final dailyTimes = dailyJson['time'] as List<dynamic>;
    final now = DateTime.parse(current['time'] as String);

    final hourly = List<HourlyWeather>.generate(hourlyTimes.length, (index) {
      num at(String key) => _preferredModelValue(hourlyJson, key, index);
      num optional(String key) {
        try {
          return at(key);
        } on FormatException {
          return 0;
        }
      }

      num nearest(String key) {
        for (var distance = 0; distance < hourlyTimes.length; distance++) {
          for (final candidate in [index + distance, index - distance]) {
            if (candidate < 0 || candidate >= hourlyTimes.length) continue;
            try {
              return _preferredModelValue(hourlyJson, key, candidate);
            } on FormatException {
              // Cerca il valore temporalmente più vicino pubblicato dal modello.
            }
          }
        }
        return 0;
      }

      return HourlyWeather(
        time: DateTime.parse(hourlyTimes[index] as String),
        temperature: at('temperature_2m').toDouble(),
        apparentTemperature: at('apparent_temperature').toDouble(),
        code: at('weather_code').toInt(),
        rainChance: at('precipitation_probability').toInt(),
        rainMm: at('precipitation').toDouble(),
        humidity: at('relative_humidity_2m').toInt(),
        windSpeed: at('wind_speed_10m').toDouble(),
        windGust: at('wind_gusts_10m').toDouble(),
        windDirection: at('wind_direction_10m').toDouble(),
        cloudCover: at('cloud_cover').toInt(),
        pressure: at('pressure_msl').toDouble(),
        uvIndex: optional('uv_index').toDouble(),
        freezingLevel: (() {
          final level = nearest('freezing_level_height').toDouble();
          if (level > 0) return level;
          return (at('temperature_2m').toDouble() * 153.8)
              .clamp(0, 6000)
              .toDouble();
        })(),
        isDay: at('is_day').toInt() == 1,
      );
    });

    final daily = List<DailyWeather>.generate(dailyTimes.length, (index) {
      num at(String key) => _preferredModelValue(dailyJson, key, index);
      String? timeAt(String key) {
        final values = dailyJson[key];
        if (values is List &&
            index < values.length &&
            values[index] is String) {
          return values[index] as String;
        }
        return null;
      }

      return DailyWeather(
        date: DateTime.parse(dailyTimes[index] as String),
        max: at('temperature_2m_max').toDouble(),
        min: at('temperature_2m_min').toDouble(),
        code: at('weather_code').toInt(),
        rainChance: at('precipitation_probability_max').toInt(),
        rainMm: at('precipitation_sum').toDouble(),
        windMax: at('wind_speed_10m_max').toDouble(),
        gustMax: at('wind_gusts_10m_max').toDouble(),
        windDirection: at('wind_direction_10m_dominant').toDouble(),
        sunrise: DateTime.tryParse(timeAt('sunrise') ?? ''),
        sunset: DateTime.tryParse(timeAt('sunset') ?? ''),
      );
    });

    return WeatherData(
      locationName: locationName ?? 'Posizione attuale',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fetchedAt: DateTime.now(),
      currentTime: now,
      temperature: (current['temperature_2m'] as num).toDouble(),
      apparentTemperature: (current['apparent_temperature'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      windGust:
          (current['wind_gusts_10m'] as num? ??
                  current['wind_speed_10m'] as num)
              .toDouble(),
      windDirection: (current['wind_direction_10m'] as num).toDouble(),
      precipitation: (current['precipitation'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      isDay: current['is_day'] == 1,
      hourly: hourly,
      daily: daily,
    );
  }

  static num _preferredModelValue(
    Map<String, dynamic> data,
    String variable,
    int index,
  ) {
    const models = ['italia_meteo_arpae_icon_2i', 'ecmwf_ifs025'];
    final keys = [variable, ...models.map((model) => '${variable}_$model')];
    for (final key in keys) {
      final values = data[key];
      if (values is List && index < values.length && values[index] is num) {
        return values[index] as num;
      }
    }
    throw FormatException('Dato meteo mancante: $variable');
  }

  factory WeatherData._fromCache(Map<String, dynamic> json) {
    final fetchedAt = DateTime.parse(json['fetchedAt'] as String);
    return WeatherData(
      locationName: json['locationName'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      fetchedAt: fetchedAt,
      currentTime:
          DateTime.tryParse(json['currentTime'] as String? ?? '') ?? fetchedAt,
      temperature: (json['temperature'] as num).toDouble(),
      apparentTemperature: (json['apparentTemperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      windGust: (json['windGust'] as num? ?? json['windSpeed'] as num)
          .toDouble(),
      windDirection: (json['windDirection'] as num? ?? 0).toDouble(),
      precipitation: (json['precipitation'] as num).toDouble(),
      weatherCode: (json['weatherCode'] as num).toInt(),
      isDay: json['isDay'] as bool,
      hourly: (json['hourly'] as List<dynamic>)
          .map(
            (item) =>
                HourlyWeather.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      daily: (json['daily'] as List<dynamic>)
          .map(
            (item) =>
                DailyWeather.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }

  List<HourlyWeather> hoursFor(DateTime date) => hourly
      .where(
        (item) =>
            item.time.year == date.year &&
            item.time.month == date.month &&
            item.time.day == date.day,
      )
      .toList(growable: false);
  bool get hasHourlyDetailsForAllDays =>
      daily.isNotEmpty && daily.every((day) => hoursFor(day.date).isNotEmpty);
  List<HourlyWeather> get upcomingHours => hourly
      .where(
        (item) => !item.time.isBefore(
          currentTime.subtract(const Duration(minutes: 30)),
        ),
      )
      .toList(growable: false);
  Map<String, dynamic> toJson() => {
    'locationName': locationName,
    'latitude': latitude,
    'longitude': longitude,
    'fetchedAt': fetchedAt.toIso8601String(),
    'currentTime': currentTime.toIso8601String(),
    'temperature': temperature,
    'apparentTemperature': apparentTemperature,
    'humidity': humidity,
    'windSpeed': windSpeed,
    'windGust': windGust,
    'windDirection': windDirection,
    'precipitation': precipitation,
    'weatherCode': weatherCode,
    'isDay': isDay,
    'hourly': hourly.map((item) => item.toJson()).toList(),
    'daily': daily.map((item) => item.toJson()).toList(),
  };
}
