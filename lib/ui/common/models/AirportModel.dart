class AirportModel {
  final String gpsCode;
  final String iataCode;
  final String name;
  final String city;
  final String subd;
  final String country;
  final String countryCode;
  final String elevation;
  final String lat;
  final String long;
  final String tz;
  final String lid;

  AirportModel({
    required this.gpsCode,
    required this.iataCode,
    required this.name,
    required this.city,
    required this.subd,
    required this.country,
    required this.countryCode,
    required this.elevation,
    required this.lat,
    required this.long,
    required this.tz,
    required this.lid,
  });

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
}
