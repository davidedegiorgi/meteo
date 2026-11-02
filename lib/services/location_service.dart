import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw Exception('Attiva la localizzazione e riprova.');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) throw Exception('Permesso di localizzazione negato.');
    if (permission == LocationPermission.deniedForever) throw Exception('Abilita la posizione nelle impostazioni.');
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 15)));
  }
}
