import 'dart:convert';

import 'package:http/http.dart' as http;

class RadarFrame {
  const RadarFrame({required this.time, required this.path});

  final DateTime time;
  final String path;
}

class RadarTimeline {
  const RadarTimeline({required this.host, required this.frames});

  final String host;
  final List<RadarFrame> frames;

  String tileUrl(int frameIndex, {bool showSnow = true}) {
    final frame = frames[frameIndex];
    return '$host${frame.path}/256/{z}/{x}/{y}/2/1_${showSnow ? 1 : 0}.png';
  }
}

class RainViewerService {
  const RainViewerService();

  static const _endpoint =
      'https://api.rainviewer.com/public/weather-maps.json';

  Future<RadarTimeline> loadTimeline() async {
    final response = await http.get(Uri.parse(_endpoint));
    if (response.statusCode != 200) {
      throw Exception('Radar momentaneamente non disponibile.');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final radar = json['radar'] as Map<String, dynamic>?;
    final past = radar?['past'] as List<dynamic>? ?? const [];
    final frames = past.map((item) {
      final value = item as Map<String, dynamic>;
      return RadarFrame(
        time: DateTime.fromMillisecondsSinceEpoch(
          (value['time'] as num).toInt() * 1000,
          isUtc: true,
        ).toLocal(),
        path: value['path'] as String,
      );
    }).toList(growable: false);

    if (frames.isEmpty) {
      throw Exception('Nessuna immagine radar disponibile.');
    }
    return RadarTimeline(host: json['host'] as String, frames: frames);
  }
}
