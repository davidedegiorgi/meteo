class LaundryIndex {
  const LaundryIndex(this.score, this.hours, this.verdict);
  final int score;
  final double? hours;
  final String verdict;
  double get progress => score / 100;
}

abstract final class LaundryIndexCalculator {
  static LaundryIndex calculate({
    required double temperature,
    required int humidity,
    required double windSpeed,
    required int weatherCode,
    required double precipitation,
  }) {
    final dry = weatherCode < 51 && precipitation <= .1;
    final raw = ((temperature - 5) / 25).clamp(0, 1) * 35 +
        ((100 - humidity) / 70).clamp(0, 1) * 30 +
        (windSpeed / 25).clamp(0, 1) * 25 +
        (dry ? 10 : 0);
    var score = raw.round().clamp(0, 100);
    if (!dry) {
      score = score.clamp(0, 25);
      return LaundryIndex(score, null, 'Meglio rimandare: rischio pioggia o tessuti umidi.');
    }
    final hours = ((7.5 - score * .06).clamp(1.5, 7) * 2).round() / 2;
    final verdict = score >= 80
        ? 'Ottimo momento: panni asciutti in circa $hours ore!'
        : score >= 60
            ? 'Buone condizioni: serviranno circa $hours ore.'
            : score >= 40
                ? 'Si può fare, ma l’asciugatura sarà lenta.'
                : 'Condizioni poco favorevoli: meglio stendere al coperto.';
    return LaundryIndex(score, hours, verdict);
  }
}
