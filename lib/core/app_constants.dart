import 'package:flutter/material.dart';

abstract final class AppConstants {
  static const weatherUrl = 'https://api.open-meteo.com/v1/forecast';
  static const geocodingUrl = 'https://geocoding-api.open-meteo.com/v1/search';
  static const timeout = Duration(seconds: 12);
  static const sunny = [Color(0xFF168DE2), Color(0xFF67C8F5)];
  static const daySky = [Color(0xFF168DE2), Color(0xFF67C8F5)];
  static const cloudy = [Color(0xFF78909C), Color(0xFF455A64)];
  static const rainy = [
    Color(0xFF667C87),
    Color(0xFF3E5B6D),
    Color(0xFF263C4B),
  ];
  static const snowy = [Color(0xFF90CAF9), Color(0xFF546E7A)];
  static const night = [Color(0xFF172554), Color(0xFF020617)];
}
