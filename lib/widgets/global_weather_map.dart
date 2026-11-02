import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/weather_data.dart';

enum GlobalWeatherLayer { radar, wind, clouds, airQuality }

class GlobalWeatherMap extends StatefulWidget {
  const GlobalWeatherMap({required this.weather, super.key});

  final WeatherData weather;

  @override
  State<GlobalWeatherMap> createState() => _GlobalWeatherMapState();
}

class _GlobalWeatherMapState extends State<GlobalWeatherMap> {
  late final WebViewController _controller;
  GlobalWeatherLayer _layer = GlobalWeatherLayer.radar;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController();
    if (!kIsWeb) {
      _controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      _controller.setBackgroundColor(Colors.transparent);
    }
    _loadLayer();
  }

  Uri _uri(GlobalWeatherLayer layer) {
    final latitude = widget.weather.latitude.toStringAsFixed(5);
    final longitude = widget.weather.longitude.toStringAsFixed(5);
    final overlay = switch (layer) {
      GlobalWeatherLayer.radar => 'rain',
      GlobalWeatherLayer.wind => 'wind',
      GlobalWeatherLayer.clouds => 'clouds',
      GlobalWeatherLayer.airQuality => 'pm2p5',
    };
    final product = switch (layer) {
      GlobalWeatherLayer.radar => 'ecmwf',
      GlobalWeatherLayer.airQuality => 'cams',
      _ => 'ecmwf',
    };
    // Sul radar apriamo la sequenza a 12 ore: Windy mantiene radar e
    // fulminazioni nella stessa animazione e la timeline prosegue nel futuro.
    final calendar = layer == GlobalWeatherLayer.radar ? '12' : 'now';
    return Uri.https('embed.windy.com', '/embed.html', {
      'type': 'map',
      'location': 'coordinates',
      'metricRain': 'mm',
      'metricTemp': '°C',
      'metricWind': 'km/h',
      'zoom': '10',
      'overlay': overlay,
      'product': product,
      'level': 'surface',
      'lat': latitude,
      'lon': longitude,
      'detailLat': latitude,
      'detailLon': longitude,
      'detail': 'false',
      'marker': 'true',
      'calendar': calendar,
      'play': '1',
    });
  }

  void _loadLayer() => _controller.loadRequest(_uri(_layer));

  void _select(GlobalWeatherLayer layer) {
    if (layer == _layer) return;
    setState(() => _layer = layer);
    _loadLayer();
  }

  String _name(GlobalWeatherLayer layer) => switch (layer) {
    GlobalWeatherLayer.radar => 'Radar pioggia e fulmini',
    GlobalWeatherLayer.wind => 'Vento',
    GlobalWeatherLayer.clouds => 'Nuvole',
    GlobalWeatherLayer.airQuality => 'Qualità aria',
  };

  IconData _icon(GlobalWeatherLayer layer) => switch (layer) {
    GlobalWeatherLayer.radar => Icons.radar,
    GlobalWeatherLayer.wind => Icons.air,
    GlobalWeatherLayer.clouds => Icons.cloud_outlined,
    GlobalWeatherLayer.airQuality => Icons.eco_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mappa meteo globale',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Radar e previsioni animate su tutto il mondo',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: GlobalWeatherLayer.values
              .map(
                (layer) => ChoiceChip(
                  avatar: Icon(_icon(layer), size: 17),
                  label: Text(_name(layer)),
                  selected: _layer == layer,
                  onSelected: (_) => _select(layer),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            height: 440,
            width: double.infinity,
            child: WebViewWidget(controller: _controller),
          ),
        ),
      ],
    );
  }
}
