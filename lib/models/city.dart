class City {
  const City(this.name, this.latitude, this.longitude, [this.country]);
  final String name;
  final double latitude;
  final double longitude;
  final String? country;
  String get id => '${latitude.toStringAsFixed(4)},${longitude.toStringAsFixed(4)}';
  String get displayName => country == null ? name : '$name, $country';
  factory City.fromJson(Map<String, dynamic> j) => City(
        j['name'] as String,
        (j['latitude'] as num).toDouble(),
        (j['longitude'] as num).toDouble(),
        j['country'] as String?,
      );
  Map<String, dynamic> toJson() => {
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'country': country,
      };
}
