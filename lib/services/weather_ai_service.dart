import '../core/weather_code.dart';
import '../core/wind_direction.dart';
import '../models/environmental_data.dart';
import '../models/forecast_confidence.dart';
import '../models/laundry_index.dart';
import '../models/marine_data.dart';
import '../models/weather_data.dart';

class WeatherAiService {
  const WeatherAiService();

  String answer({
    required String question,
    required WeatherData weather,
    required String Function(double) temperature,
    String? previousQuestion,
    MarineData? marine,
    EnvironmentalData? environmental,
    LaundryIndex? laundry,
  }) {
    final rawQuery = question.toLowerCase().trim();
    if (rawQuery.isEmpty) return 'Scrivimi una domanda sul meteo.';
    final query = _isFollowUp(rawQuery) && previousQuestion != null
        ? '${previousQuestion.toLowerCase()} $rawQuery'
        : rawQuery;
    final requestedDay = _requestedDay(query, weather);
    final requestedHours = requestedDay == null
        ? <HourlyWeather>[]
        : weather.hoursFor(requestedDay.date);
    final targetHour = _targetHour(query, requestedHours, weather.currentTime);
    final isToday =
        weather.daily.isNotEmpty && requestedDay == weather.daily.first;

    if (_has(query, ['ciao', 'aiuto', 'cosa sai fare', 'come funzioni'])) {
      return 'Posso spiegarti meteo attuale e previsioni, pioggia, vento, UV, '
          'attendibilità, bucato, qualità dell’aria, pollini e condizioni marine. '
          'Puoi anche chiedermi come vestirti, quando uscire o se il meteo è adatto a una tua attività.';
    }

    if (_has(query, [
      'riepilogo',
      'riassunto',
      'che tempo fa',
      'come sarà la giornata',
      'com’è la giornata',
      "com'e la giornata",
      'situazione meteo',
      'meteo di oggi',
    ])) {
      return _dailyBrief(
        requestedDay,
        requestedHours,
        weather,
        temperature,
        query,
      );
    }

    if (_has(query, [
      'alba',
      'tramonto',
      'sorge il sole',
      'sole tramonta',
      'ore di luce',
    ])) {
      if (requestedDay == null) return 'Non ho gli orari solari richiesti.';
      final sunrise = _clock(requestedDay.sunrise);
      final sunset = _clock(requestedDay.sunset);
      return '${_dayLabel(requestedDay, weather)} il sole sorge alle $sunrise e tramonta alle $sunset.';
    }

    if (_has(query, [
      'mare',
      'onda',
      'onde',
      'swell',
      'corrente marina',
      'barca',
      'vela',
      'navigare',
      'navigazione',
      'pesca in mare',
    ])) {
      if (marine == null) {
        return 'I dati marini non sono disponibili per questa località, che potrebbe essere troppo lontana dalla costa.';
      }
      return 'Onde ${marine.waveHeight.toStringAsFixed(1)} m da ${marine.waveDirection.round()}°, '
          'periodo ${marine.wavePeriod.toStringAsFixed(1)} s.';
    }

    if (_has(query, ['aria', 'pm10', 'inquinamento', 'pollini', 'allerg'])) {
      if (environmental == null) {
        return 'Qualità dell’aria e pollini non sono ancora disponibili. Prova ad aggiornare tra poco.';
      }
      return 'Qualità dell’aria ${environmental.airQuality.toLowerCase()}: '
          'PM10 ${environmental.pm10.toStringAsFixed(1)} µg/m³. '
          'Pollini ${environmental.pollenLevel.toLowerCase()}, indice composito '
          '${environmental.pollenComposite.toStringAsFixed(1)} grani/m³.';
    }

    if (_has(query, ['bucato', 'stendere', 'panni', 'asciug'])) {
      return laundry == null
          ? 'Non ho ancora abbastanza dati per valutare il bucato.'
          : 'Indice bucato ${laundry.score}%. ${laundry.verdict}';
    }

    if (_has(query, [
      'come mi vesto',
      'cosa mi metto',
      'come vestirmi',
      'abbigliamento',
      'vestiti',
      'giacca',
      'cappotto',
    ])) {
      final perceived =
          targetHour?.apparentTemperature ??
          (isToday
              ? weather.apparentTemperature
              : ((requestedDay?.min ?? weather.temperature) +
                        (requestedDay?.max ?? weather.temperature)) /
                    2);
      final outfit = perceived <= 5
          ? 'cappotto caldo, maglia pesante e scarpe chiuse'
          : perceived <= 12
          ? 'giacca o piumino leggero e vestiti a strati'
          : perceived <= 18
          ? 'giacca leggera o felpa sopra una maglia'
          : perceived <= 24
          ? 'maglia leggera; porta uno strato sottile per la sera'
          : 'abiti leggeri e traspiranti';
      final today = requestedDay;
      final extras = <String>[];
      if ((today?.rainChance ?? 0) >= 35 || (today?.rainMm ?? 0) >= .5) {
        extras.add('porta ombrello o impermeabile');
      }
      if (weather.windSpeed >= 25 || weather.windGust >= 40) {
        extras.add('meglio anche uno strato antivento');
      }
      final maxUv = requestedHours.fold<double>(
        0,
        (value, hour) => hour.uvIndex > value ? hour.uvIndex : value,
      );
      if (maxUv >= 6)
        extras.add('nelle ore centrali usa cappello e protezione solare');
      final actual =
          targetHour?.temperature ??
          (isToday ? weather.temperature : perceived);
      return '${_dayAndPeriodLabel(query, requestedDay, weather)} con ${temperature(actual)} e ${temperature(perceived)} percepiti, '
          'ti consiglio $outfit.${extras.isEmpty ? '' : ' Inoltre, ${extras.join(', ')}.'}';
    }

    if (_has(query, ['cane', 'zampe', 'asfalto rovente'])) {
      final temperatureValue = targetHour?.temperature ?? weather.temperature;
      final code = targetHour?.code ?? weather.weatherCode;
      if (temperatureValue >= 28 && code <= 1) {
        return 'Con ${temperature(temperatureValue)} e sole l’asfalto può diventare molto più caldo dell’aria. '
            'Per il cane scegli mattino presto o dopo il tramonto, usa zone d’ombra e controlla il terreno col dorso della mano.';
      }
      final best = _bestOutdoorHour(requestedHours);
      return 'Non emerge un forte rischio di asfalto rovente. '
          '${best == null ? '' : 'L’orario più confortevole è intorno alle ${_clock(best.time)}. '}'
          'Controlla comunque il terreno prima della passeggiata.';
    }

    if (_has(query, [
      'quando conviene',
      'orario migliore',
      'ora migliore',
      'quando uscire',
      'momento migliore',
      'a che ora',
    ])) {
      final best = _bestOutdoorHour(requestedHours);
      if (best == null)
        return 'Non ho dati orari sufficienti per scegliere il momento migliore.';
      return 'Il momento migliore ${_dayLabel(requestedDay, weather).toLowerCase()} è intorno alle ${_clock(best.time)}: '
          '${WeatherCode.description(best.code).toLowerCase()}, ${temperature(best.temperature)}, '
          'pioggia ${best.rainChance}% e vento ${best.windSpeed.round()} km/h.';
    }

    if (_has(query, [
      'posso uscire',
      'passeggiata',
      'correre',
      'corsa',
      'bicicletta',
      'bici',
      'picnic',
      'spiaggia',
      'attività',
      'cosa posso fare',
      'cosa consigli',
      'all’aperto',
      "all'aperto",
    ])) {
      final today = requestedDay;
      final rainy = (today?.rainChance ?? 0) >= 50 || (today?.rainMm ?? 0) >= 1;
      final reference = targetHour ?? _bestOutdoorHour(requestedHours);
      final referenceWind = reference?.windSpeed ?? weather.windSpeed;
      final referenceGust = reference?.windGust ?? weather.windGust;
      final referenceFeels =
          reference?.apparentTemperature ?? weather.apparentTemperature;
      final windy = referenceWind >= 30 || referenceGust >= 45;
      final uncomfortable = referenceFeels <= 3 || referenceFeels >= 33;
      if (rainy || windy || uncomfortable) {
        final reasons = <String>[
          if (rainy) 'rischio di pioggia ${today?.rainChance ?? 0}%',
          if (windy) 'raffiche fino a ${referenceGust.round()} km/h',
          if (uncomfortable)
            'temperatura percepita ${temperature(referenceFeels)}',
        ];
        return 'Le attività all’aperto sono possibili con cautela, ma oggi ci sono ${reasons.join(' e ')}. '
            'Preferisci un’attività breve, un percorso riparato o un’alternativa al coperto.';
      }
      return 'Le condizioni sono favorevoli per uscire: ${temperature(referenceFeels)} percepiti, '
          'vento ${referenceWind.round()} km/h e rischio pioggia ${today?.rainChance ?? 0}%. '
          '${reference == null ? '' : 'La finestra migliore è attorno alle ${_clock(reference.time)}. '}'
          'Passeggiata, corsa o bici sono buone opzioni.';
    }

    if (_has(query, ['guidare', 'guida', 'auto', 'viaggio', 'strada'])) {
      final today = weather.daily.isEmpty ? null : weather.daily.first;
      final hazards = <String>[];
      if ((today?.rainMm ?? 0) >= 1) hazards.add('asfalto bagnato');
      if (weather.windGust >= 45) hazards.add('raffiche laterali');
      if (weather.weatherCode >= 45 && weather.weatherCode <= 48)
        hazards.add('visibilità ridotta per nebbia');
      return hazards.isEmpty
          ? 'Non emergono criticità meteo importanti per la guida. Controlla comunque gli aggiornamenti prima di partire.'
          : 'Per la guida attenzione a ${hazards.join(', ')}. Riduci la velocità e aumenta la distanza di sicurezza.';
    }

    if (_has(query, [
      'uv',
      'ultraviolett',
      'crema solare',
      'protezione solare',
    ])) {
      final today = weather.hoursFor(weather.currentTime);
      final maxUv = today.fold<double>(
        0,
        (value, hour) => hour.uvIndex > value ? hour.uvIndex : value,
      );
      final level = maxUv < 3
          ? 'basso'
          : maxUv < 6
          ? 'moderato'
          : maxUv < 8
          ? 'alto'
          : maxUv < 11
          ? 'molto alto'
          : 'estremo';
      return 'L’indice UV massimo di oggi è ${maxUv.toStringAsFixed(1)} su 11, livello $level. '
          '${maxUv >= 6 ? 'Meglio usare protezione solare e cercare ombra nelle ore centrali.' : 'Protezione normale consigliata durante l’esposizione.'}';
    }

    if (_has(query, ['vento', 'raffica', 'raffiche', 'direzione'])) {
      final gap = weather.windSpeed <= 0
          ? 0
          : ((weather.windGust / weather.windSpeed - 1) * 100).round();
      return 'Vento ${weather.windSpeed.round()} km/h da ${WindDirection.label(weather.windDirection)}, '
          'raffiche fino a ${weather.windGust.round()} km/h. '
          '${gap >= 40 ? 'Le raffiche superano il vento medio del $gap%: attenzione a instabilità e sbandate.' : 'Raffiche senza scarti particolarmente critici.'}';
    }

    if (_has(query, ['attendibil', 'affidabil', 'sicura la previsione'])) {
      final hours = weather.daily.isEmpty
          ? weather.hourly
          : weather.hoursFor(weather.daily.first.date);
      final confidence = ForecastConfidence.calculate(0, hours);
      return 'L’attendibilità della previsione odierna è $confidence%, '
          '${ForecastConfidence.label(confidence).toLowerCase()}. In genere diminuisce andando avanti nei giorni.';
    }

    if (_has(query, ['piove', 'piover', 'pioggia', 'ombrello', 'precipit'])) {
      final day = requestedDay;
      if (day == null)
        return 'Non ho una giornata disponibile per questa richiesta.';
      final wetHours = requestedHours
          .where((hour) => hour.rainChance >= 40 || hour.rainMm >= .2)
          .toList(growable: false);
      final interval = wetHours.isEmpty
          ? ''
          : ' La fascia più a rischio va circa dalle ${_clock(wetHours.first.time)} alle ${_clock(wetHours.last.time)}.';
      return '${_dayLabel(day, weather)} la probabilità massima di pioggia è ${day.rainChance}% '
          'con ${day.rainMm.toStringAsFixed(1)} mm previsti. '
          '${day.rainChance >= 50 || day.rainMm >= 1 ? 'Portare l’ombrello è una buona idea.' : 'Il rischio di pioggia è contenuto.'}$interval';
    }

    if (_has(query, ['posso', 'conviene', 'meglio', 'consigli', 'adatto'])) {
      return _genericActivityAdvice(
        rawQuery,
        requestedDay,
        requestedHours,
        targetHour,
        weather,
        temperature,
      );
    }

    final asksOnlyForDay = RegExp(
      r'^(?:e\s+)?(?:domani|dopodomani)\??$',
    ).hasMatch(rawQuery);
    if (_has(query, [
          'prossimi giorni',
          'prevision',
          'che tempo',
          'come sarà',
          'come sara',
          'meteo domani',
          'meteo dopodomani',
        ]) ||
        asksOnlyForDay) {
      final day = requestedDay;
      if (day == null) return 'La previsione richiesta non è disponibile.';
      return '${_dayLabel(day, weather)}: ${WeatherCode.description(day.code).toLowerCase()}, minima ${temperature(day.min)}, '
          'massima ${temperature(day.max)}, pioggia ${day.rainChance}% '
          '(${day.rainMm.toStringAsFixed(1)} mm), vento fino a ${day.windMax.round()} km/h '
          'con raffiche di ${day.gustMax.round()} km/h.';
    }

    if (targetHour != null &&
        _has(query, [
          'alle ',
          'ore ',
          'mattina',
          'pomeriggio',
          'stasera',
          'sera',
          'notte',
          'temperatura',
          'che tempo',
        ])) {
      return '${_dayLabel(requestedDay, weather)} alle ${_clock(targetHour.time)}: '
          '${WeatherCode.description(targetHour.code).toLowerCase()}, '
          '${temperature(targetHour.temperature)} e ${temperature(targetHour.apparentTemperature)} percepiti. '
          'Pioggia ${targetHour.rainChance}% (${targetHour.rainMm.toStringAsFixed(1)} mm), '
          'vento ${targetHour.windSpeed.round()} km/h con raffiche ${targetHour.windGust.round()} km/h, '
          'umidità ${targetHour.humidity}% e UV ${targetHour.uvIndex.toStringAsFixed(1)}.';
    }

    if (_has(query, ['umid', 'pression'])) {
      final currentHour = weather.upcomingHours.isEmpty
          ? null
          : weather.upcomingHours.first;
      final pressure = currentHour == null
          ? ''
          : ' Pressione ${currentHour.pressure.round()} mb.';
      return 'Umidità ${weather.humidity}%.$pressure Temperatura percepita ${temperature(weather.apparentTemperature)}.';
    }

    if (_has(query, ['posso', 'conviene', 'meglio', 'consigli', 'adatto'])) {
      return _genericActivityAdvice(
        rawQuery,
        requestedDay,
        requestedHours,
        targetHour,
        weather,
        temperature,
      );
    }

    return _dailyBrief(
      requestedDay,
      requestedHours,
      weather,
      temperature,
      query,
      intro: 'Per la tua domanda “$question”, ',
    );
  }

  DailyWeather? _requestedDay(String query, WeatherData weather) {
    if (weather.daily.isEmpty) return null;
    final afterDays = RegExp(r'tra\s+(\d+)\s+giorn').firstMatch(query);
    if (afterDays != null) {
      final index = int.tryParse(afterDays.group(1) ?? '') ?? 0;
      return weather.daily[index.clamp(0, weather.daily.length - 1)];
    }
    if (query.contains('dopodomani')) {
      return weather.daily.length > 2 ? weather.daily[2] : weather.daily.last;
    }
    if (query.contains('domani')) {
      return weather.daily.length > 1 ? weather.daily[1] : weather.daily.first;
    }
    const weekdays = <String, int>{
      'lunedi': DateTime.monday,
      'lunedì': DateTime.monday,
      'martedi': DateTime.tuesday,
      'martedì': DateTime.tuesday,
      'mercoledi': DateTime.wednesday,
      'mercoledì': DateTime.wednesday,
      'giovedi': DateTime.thursday,
      'giovedì': DateTime.thursday,
      'venerdi': DateTime.friday,
      'venerdì': DateTime.friday,
      'sabato': DateTime.saturday,
      'domenica': DateTime.sunday,
    };
    for (final entry in weekdays.entries) {
      if (!query.contains(entry.key)) continue;
      for (final day in weather.daily) {
        if (day.date.weekday == entry.value) return day;
      }
    }
    final dateMatch = RegExp(r'\b(\d{1,2})[\/-](\d{1,2})\b').firstMatch(query);
    if (dateMatch != null) {
      final dayNumber = int.tryParse(dateMatch.group(1) ?? '');
      final month = int.tryParse(dateMatch.group(2) ?? '');
      for (final day in weather.daily) {
        if (day.date.day == dayNumber && day.date.month == month) return day;
      }
    }
    return weather.daily.first;
  }

  HourlyWeather? _targetHour(
    String query,
    List<HourlyWeather> hours,
    DateTime currentTime,
  ) {
    if (hours.isEmpty) return null;
    final match = RegExp(r'(?:alle|verso|ore)\s*(\d{1,2})').firstMatch(query);
    if (match != null) {
      final requested = (int.tryParse(match.group(1) ?? '') ?? 12).clamp(0, 23);
      return hours.reduce(
        (a, b) =>
            (a.time.hour - requested).abs() <= (b.time.hour - requested).abs()
            ? a
            : b,
      );
    }
    int? start;
    int? end;
    int? center;
    if (_has(query, ['mattina', 'mattino'])) {
      start = 6;
      end = 12;
      center = 9;
    } else if (query.contains('pomeriggio')) {
      start = 12;
      end = 18;
      center = 15;
    } else if (_has(query, ['stasera', 'sera'])) {
      start = 18;
      end = 24;
      center = 20;
    } else if (query.contains('notte')) {
      start = 0;
      end = 6;
      center = 2;
    }
    if (start != null && end != null && center != null) {
      final candidates = hours
          .where((hour) => hour.time.hour >= start! && hour.time.hour < end!)
          .toList(growable: false);
      if (candidates.isNotEmpty) {
        return candidates.reduce(
          (a, b) =>
              (a.time.hour - center!).abs() <= (b.time.hour - center).abs()
              ? a
              : b,
        );
      }
    }
    if (_has(query, ['adesso', 'ora', 'tra poco'])) {
      return hours.firstWhere(
        (hour) => !hour.time.isBefore(currentTime),
        orElse: () => hours.first,
      );
    }
    return null;
  }

  HourlyWeather? _bestOutdoorHour(List<HourlyWeather> hours) {
    final candidates = hours
        .where((hour) => hour.time.hour >= 7 && hour.time.hour <= 21)
        .toList(growable: false);
    if (candidates.isEmpty) return null;
    double score(HourlyWeather hour) {
      final comfortPenalty = hour.apparentTemperature < 10
          ? (10 - hour.apparentTemperature) * 2
          : hour.apparentTemperature > 27
          ? (hour.apparentTemperature - 27) * 2
          : 0;
      return hour.rainChance * .7 +
          hour.rainMm * 18 +
          hour.windSpeed * .35 +
          hour.windGust * .18 +
          comfortPenalty +
          (hour.code >= 95 ? 80 : 0);
    }

    return candidates.reduce((a, b) => score(a) <= score(b) ? a : b);
  }

  String _dailyBrief(
    DailyWeather? day,
    List<HourlyWeather> hours,
    WeatherData weather,
    String Function(double) temperature,
    String query, {
    String intro = '',
  }) {
    if (day == null)
      return 'Non ho dati sufficienti per la giornata richiesta.';
    final best = _bestOutdoorHour(hours);
    final maxUv = hours.fold<double>(
      0,
      (value, hour) => hour.uvIndex > value ? hour.uvIndex : value,
    );
    final rainAdvice = day.rainChance >= 50 || day.rainMm >= 1
        ? 'ombrello consigliato'
        : 'ombrello generalmente non necessario';
    final bestText = best == null
        ? ''
        : ' La fascia più favorevole è intorno alle ${_clock(best.time)}, con ${temperature(best.temperature)} e pioggia ${best.rainChance}%.';
    return '$intro${_dayLabel(day, weather)} a ${weather.locationName}: '
        '${WeatherCode.description(day.code).toLowerCase()}, minima ${temperature(day.min)} e massima ${temperature(day.max)}. '
        'Pioggia ${day.rainChance}% (${day.rainMm.toStringAsFixed(1)} mm), $rainAdvice; '
        'vento fino a ${day.windMax.round()} km/h e raffiche ${day.gustMax.round()} km/h. '
        'UV massimo ${maxUv.toStringAsFixed(1)}.$bestText';
  }

  String _genericActivityAdvice(
    String question,
    DailyWeather? day,
    List<HourlyWeather> hours,
    HourlyWeather? targetHour,
    WeatherData weather,
    String Function(double) temperature,
  ) {
    if (day == null)
      return 'Non ho dati sufficienti per valutare questa attività.';
    final best = targetHour ?? _bestOutdoorHour(hours);
    final hazards = <String>[];
    if (day.rainChance >= 55 || day.rainMm >= 2) {
      hazards.add('pioggia ${day.rainChance}%');
    }
    if (day.gustMax >= 45)
      hazards.add('raffiche fino a ${day.gustMax.round()} km/h');
    if (best != null && best.apparentTemperature >= 33) {
      hazards.add('caldo percepito ${temperature(best.apparentTemperature)}');
    }
    if (best != null && best.apparentTemperature <= 3) {
      hazards.add('freddo percepito ${temperature(best.apparentTemperature)}');
    }
    if (hours.any((hour) => hour.code >= 95))
      hazards.add('possibili temporali');
    if (hazards.isEmpty) {
      return 'Sì, le condizioni sono adatte. '
          '${best == null ? '' : 'Il momento migliore è verso le ${_clock(best.time)}, con ${temperature(best.temperature)}, vento ${best.windSpeed.round()} km/h e pioggia ${best.rainChance}%. '}'
          'Controlla comunque gli aggiornamenti poco prima di uscire.';
    }
    return 'Puoi farlo con cautela, ma considera ${hazards.join(', ')}. '
        '${best == null ? 'Valuta un’alternativa al coperto.' : 'La finestra meno sfavorevole è intorno alle ${_clock(best.time)}.'}';
  }

  String _dayLabel(DailyWeather? day, WeatherData weather) {
    if (day == null) return 'La giornata richiesta';
    final index = weather.daily.indexOf(day);
    if (index == 0) return 'Oggi';
    if (index == 1) return 'Domani';
    const names = [
      'lunedì',
      'martedì',
      'mercoledì',
      'giovedì',
      'venerdì',
      'sabato',
      'domenica',
    ];
    return '${names[day.date.weekday - 1]} ${day.date.day}/${day.date.month}';
  }

  String _dayAndPeriodLabel(
    String query,
    DailyWeather? day,
    WeatherData weather,
  ) {
    final period = query.contains('mattina') || query.contains('mattino')
        ? ' mattina'
        : query.contains('pomeriggio')
        ? ' pomeriggio'
        : query.contains('sera')
        ? ' sera'
        : query.contains('notte')
        ? ' notte'
        : '';
    return '${_dayLabel(day, weather)}$period,';
  }

  String _clock(DateTime? value) => value == null
      ? '—'
      : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  bool _isFollowUp(String query) =>
      RegExp(
        r'^(e |invece |allora |quindi |ma )(oggi|domani|dopodomani|stasera|la mattina|il pomeriggio|la sera)?',
      ).hasMatch(query) ||
      _has(query, ['e domani', 'e oggi', 'e stasera', 'e la sera']);

  bool _has(String query, List<String> terms) => terms.any(query.contains);
}
