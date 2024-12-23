class AirportModel {
  final String? gpsCode;
  final String? iataCode;
  final String? name;
  final String? city;
  final String? subd;
  final String? country;
  final String? countryCode;
  final String? elevation;
  final String? lat;
  final String? long;
  final String? tz;
  final String? lid;

  AirportModel({
    this.gpsCode,
    this.iataCode,
    this.name,
    this.city,
    this.subd,
    this.country,
    this.countryCode,
    this.elevation,
    this.lat,
    this.long,
    this.tz,
    this.lid,
  });

  factory AirportModel.fromMap(Map<String, dynamic> map) {
    return AirportModel(
      gpsCode: map['gps_code'] as String?,
      iataCode: map['iata_code'] as String?,
      name: map['name'] as String?,
      city: map['city'] as String?,
      subd: map['subd'] as String?,
      country: map['country'] as String?,
      countryCode: map['country_code'] as String?,
      elevation: map['elevation']?.toString(), // Convert to String if needed
      lat: map['lat']?.toString(), // Ensure it's a String
      long: map['long']?.toString(), // Ensure it's a String
      tz: map['tz'] as String?,
      lid: map['lid'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gps_code': gpsCode,
      'iata_code': iataCode,
      'name': name,
      'city': city,
      'subd': subd,
      'country': country,
      'country_code': countryCode,
      'elevation': elevation,
      'lat': lat,
      'long': long,
      'tz': tz,
      'lid': lid,
    };
  }

  factory AirportModel.fromJson(Map<String, dynamic> json) {
    return AirportModel(
      gpsCode: json['gps_code'],
      iataCode: json['iata_code'],
      name: json['name'],
      city: json['city'],
      subd: json['subd'],
      country: json['country'],
      countryCode: json['country_code'],
      elevation: json['elevation'],
      lat: json['Lat'],
      long: json['Long'],
      tz: json['tz'],
      lid: json['lid'],
    );
  }
}
