import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/weather_provider.dart';
import 'screens/main_screen.dart';
import 'services/local_database_service.dart';
import 'services/environmental_service.dart';
import 'services/location_service.dart';
import 'services/marine_service.dart';
import 'services/weather_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = LocalDatabaseService(await SharedPreferences.getInstance());
  final provider = WeatherProvider(
    WeatherService(db),
    MarineService(db),
    EnvironmentalService(db),
    db,
    LocationService(),
  );
  unawaited(provider.initialize());
  runApp(
    ChangeNotifierProvider.value(value: provider, child: const MeteoApp()),
  );
}

class MeteoApp extends StatelessWidget {
  const MeteoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meteo',
      themeMode: ThemeMode.light,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const MainScreen(),
    );
  }
}
