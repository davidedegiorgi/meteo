import 'dart:math' as math;

double sunAltitudeDegrees(DateTime date, double latitude, double longitude) =>
    _sunAltitude(date, latitude, longitude) / _rad;

double moonAltitudeDegrees(DateTime date, double latitude, double longitude) =>
    _moonAltitude(date, latitude, longitude) / _rad;

class SunInfo {
  const SunInfo({required this.rise, required this.set});
  final DateTime? rise;
  final DateTime? set;

  factory SunInfo.calculate(DateTime date, double latitude, double longitude) {
    final start = DateTime(date.year, date.month, date.day);
    const stepMinutes = 10;
    const horizon = -.833 * _rad;
    var previous = _sunAltitude(start, latitude, longitude) - horizon;
    DateTime? rise;
    DateTime? set;

    for (var minute = stepMinutes; minute <= 24 * 60; minute += stepMinutes) {
      final current =
          _sunAltitude(
            start.add(Duration(minutes: minute)),
            latitude,
            longitude,
          ) -
          horizon;
      if ((previous <= 0 && current > 0) || (previous >= 0 && current < 0)) {
        final fraction = previous.abs() / (previous.abs() + current.abs());
        final event = start.add(
          Duration(
            milliseconds:
                ((minute - stepMinutes + stepMinutes * fraction) * 60000)
                    .round(),
          ),
        );
        if (previous <= 0 && current > 0) {
          rise ??= event;
        } else {
          set ??= event;
        }
      }
      previous = current;
    }
    return SunInfo(rise: rise, set: set);
  }
}

class MoonInfo {
  const MoonInfo({
    required this.rise,
    required this.set,
    required this.phase,
    required this.illumination,
    required this.label,
    required this.emoji,
  });

  final DateTime? rise;
  final DateTime? set;
  final double phase;
  final double illumination;
  final String label;
  final String emoji;

  factory MoonInfo.calculate(DateTime date, double latitude, double longitude) {
    final times = _moonTimes(date, latitude, longitude);
    final illumination = _moonIllumination(date);
    final phase = illumination.phase;
    return MoonInfo(
      rise: times.rise,
      set: times.set,
      phase: phase,
      illumination: illumination.fraction,
      label: _phaseLabel(phase),
      emoji: _phaseEmoji(phase),
    );
  }

  static String _phaseLabel(double phase) {
    if (phase < .03 || phase >= .97) return 'Luna nuova';
    if (phase < .22) return 'Luna crescente';
    if (phase < .28) return 'Primo quarto';
    if (phase < .47) return 'Gibbosa crescente';
    if (phase < .53) return 'Luna piena';
    if (phase < .72) return 'Gibbosa calante';
    if (phase < .78) return 'Ultimo quarto';
    return 'Luna calante';
  }

  static String _phaseEmoji(double phase) {
    if (phase < .03 || phase >= .97) return '🌑';
    if (phase < .22) return '🌒';
    if (phase < .28) return '🌓';
    if (phase < .47) return '🌔';
    if (phase < .53) return '🌕';
    if (phase < .72) return '🌖';
    if (phase < .78) return '🌗';
    return '🌘';
  }
}

const _rad = math.pi / 180;
const _dayMs = 86400000.0;
const _j1970 = 2440588.0;
const _j2000 = 2451545.0;
const _earthObliquity = _rad * 23.4397;

double _toJulian(DateTime date) =>
    date.toUtc().millisecondsSinceEpoch / _dayMs - .5 + _j1970;
double _toDays(DateTime date) => _toJulian(date) - _j2000;
double _rightAscension(double longitude, double latitude) => math.atan2(
  math.sin(longitude) * math.cos(_earthObliquity) -
      math.tan(latitude) * math.sin(_earthObliquity),
  math.cos(longitude),
);
double _declination(double longitude, double latitude) => math.asin(
  math.sin(latitude) * math.cos(_earthObliquity) +
      math.cos(latitude) * math.sin(_earthObliquity) * math.sin(longitude),
);
double _siderealTime(double days, double lw) =>
    _rad * (280.16 + 360.9856235 * days) - lw;
double _altitude(double hourAngle, double latitude, double declination) =>
    math.asin(
      math.sin(latitude) * math.sin(declination) +
          math.cos(latitude) * math.cos(declination) * math.cos(hourAngle),
    );

_Coordinates _sunCoordinates(double days) {
  final meanAnomaly = _rad * (357.5291 + .98560028 * days);
  final equation =
      _rad *
      (1.9148 * math.sin(meanAnomaly) +
          .02 * math.sin(2 * meanAnomaly) +
          .0003 * math.sin(3 * meanAnomaly));
  final longitude = meanAnomaly + equation + _rad * 102.9372 + math.pi;
  return _Coordinates(
    _rightAscension(longitude, 0),
    _declination(longitude, 0),
    149598000,
  );
}

_Coordinates _moonCoordinates(double days) {
  final longitude = _rad * (218.316 + 13.176396 * days);
  final meanAnomaly = _rad * (134.963 + 13.064993 * days);
  final meanDistance = _rad * (93.272 + 13.229350 * days);
  final eclipticLongitude = longitude + _rad * 6.289 * math.sin(meanAnomaly);
  final eclipticLatitude = _rad * 5.128 * math.sin(meanDistance);
  final distance = 385001 - 20905 * math.cos(meanAnomaly);
  return _Coordinates(
    _rightAscension(eclipticLongitude, eclipticLatitude),
    _declination(eclipticLongitude, eclipticLatitude),
    distance,
  );
}

double _moonAltitude(DateTime date, double latitude, double longitude) {
  final lw = -longitude * _rad;
  final phi = latitude * _rad;
  final days = _toDays(date);
  final moon = _moonCoordinates(days);
  final hourAngle = _siderealTime(days, lw) - moon.rightAscension;
  var altitude = _altitude(hourAngle, phi, moon.declination);
  final refractionAltitude = altitude < 0 ? 0.0 : altitude;
  altitude +=
      _rad *
      .017 /
      math.tan(
        refractionAltitude + _rad * 10.26 / (refractionAltitude + _rad * 5.10),
      );
  return altitude;
}

double _sunAltitude(DateTime date, double latitude, double longitude) {
  final lw = -longitude * _rad;
  final phi = latitude * _rad;
  final days = _toDays(date);
  final sun = _sunCoordinates(days);
  final hourAngle = _siderealTime(days, lw) - sun.rightAscension;
  return _altitude(hourAngle, phi, sun.declination);
}

_MoonTimes _moonTimes(DateTime source, double latitude, double longitude) {
  final date = DateTime(source.year, source.month, source.day);
  const horizon = .133 * _rad;
  var previous = _moonAltitude(date, latitude, longitude) - horizon;
  double? riseHour;
  double? setHour;

  for (var hour = 1; hour <= 23; hour += 2) {
    final middle =
        _moonAltitude(date.add(Duration(hours: hour)), latitude, longitude) -
        horizon;
    final next =
        _moonAltitude(
          date.add(Duration(hours: hour + 1)),
          latitude,
          longitude,
        ) -
        horizon;
    final a = (previous + next) / 2 - middle;
    final b = (next - previous) / 2;
    if (a.abs() > 1e-12) {
      final extremum = -b / (2 * a);
      final extremumValue = (a * extremum + b) * extremum + middle;
      final discriminant = b * b - 4 * a * middle;
      if (discriminant >= 0) {
        final spread = math.sqrt(discriminant) / (2 * a.abs());
        var first = extremum - spread;
        final second = extremum + spread;
        var roots = 0;
        if (first.abs() <= 1) roots++;
        if (second.abs() <= 1) roots++;
        if (first < -1) first = second;
        if (roots == 1) {
          if (previous < 0) {
            riseHour ??= hour + first;
          } else {
            setHour ??= hour + first;
          }
        } else if (roots == 2) {
          riseHour ??= hour + (extremumValue < 0 ? second : first);
          setHour ??= hour + (extremumValue < 0 ? first : second);
        }
      }
    }
    if (riseHour != null && setHour != null) break;
    previous = next;
  }

  DateTime? at(double? hour) => hour == null
      ? null
      : date.add(Duration(milliseconds: (hour * 3600000).round()));
  return _MoonTimes(at(riseHour), at(setHour));
}

_Illumination _moonIllumination(DateTime date) {
  final days = _toDays(date);
  final sun = _sunCoordinates(days);
  final moon = _moonCoordinates(days);
  const sunDistance = 149598000.0;
  final phi = math.acos(
    math.sin(sun.declination) * math.sin(moon.declination) +
        math.cos(sun.declination) *
            math.cos(moon.declination) *
            math.cos(sun.rightAscension - moon.rightAscension),
  );
  final incidence = math.atan2(
    sunDistance * math.sin(phi),
    moon.distance - sunDistance * math.cos(phi),
  );
  final angle = math.atan2(
    math.cos(sun.declination) *
        math.sin(sun.rightAscension - moon.rightAscension),
    math.sin(sun.declination) * math.cos(moon.declination) -
        math.cos(sun.declination) *
            math.sin(moon.declination) *
            math.cos(sun.rightAscension - moon.rightAscension),
  );
  return _Illumination(
    (1 + math.cos(incidence)) / 2,
    .5 + .5 * incidence * (angle < 0 ? -1 : 1) / math.pi,
  );
}

class _Coordinates {
  const _Coordinates(this.rightAscension, this.declination, this.distance);
  final double rightAscension;
  final double declination;
  final double distance;
}

class _MoonTimes {
  const _MoonTimes(this.rise, this.set);
  final DateTime? rise;
  final DateTime? set;
}

class _Illumination {
  const _Illumination(this.fraction, this.phase);
  final double fraction;
  final double phase;
}
