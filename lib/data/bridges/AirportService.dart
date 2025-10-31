import 'dart:convert';
import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:http/http.dart' as http;

class AirportService {
  final String url = 'https://raw.githubusercontent.com/BFOBC/AirportsJson/main/AirportsJson';
  Future<List<AirportModel>> fetchAirportsFromGitHub() async {
    try {
      // Start by making the HTTP request
      final response = await http.get(Uri.parse(url));

      // Check if the response status code is 200 (OK)
      if (response.statusCode == 200) {
        try {
          // Attempt to parse the response body as JSON
          final List<dynamic> data = json.decode(response.body);

          // Map the parsed JSON model to a list of AirportModel instances
          return data.map((json) => AirportModel.fromJson(json)).toList();
        } catch (jsonError) {
          // If JSON parsing fails, log the error
          print('JSON Parsing Error: $jsonError');
          throw Exception('Failed to parse JSON');
        }
      } else {
        // Log the error if the response code is not 200
        print('Failed to load model from GitHub with status code: ${response.statusCode}');
        throw Exception('Failed to load model from GitHub');
      }
    } catch (error) {
      // Catch any other errors like network issues, connection timeouts, etc.
      print('Error while fetching model from GitHub: $error');
      throw Exception('Failed to fetch model from GitHub');
    }
  }


  Future<void> loadAirports() async {
    final dbHelper = DatabaseOperation();
    final existingData = await dbHelper.getAirports();

    if (existingData.isEmpty) {
      // Fetch from GitHub and store in SQLite
      final airports = await fetchAirportsFromGitHub();
      await dbHelper.insertAirports(airports.map((e) => e.toMap()).toList());
    }
  }

  Future<List<AirportModel>> getAirports() async {
    final dbHelper = DatabaseOperation();
    final data = await dbHelper.getAirports();
    return data.map((json) => AirportModel.fromJson(json)).toList();
  }
  Future<List<AirportModel>> fetchAndDisplayAirports() async {
    print('Fetching and displaying airports...');
    try {
      final airports = await fetchAirportsFromGitHub();
      print('Airports fetched and will be displayed');
      // Optionally, store it in the database here if needed
      //final dbHelper = DatabaseOperation();
      //await dbHelper.insertAirports(airports.map((e) => e.toMap()).toList());

      return airports;
    } catch (e) {
      print('Error while fetching airports: $e');
      return [];
    }
  }

}
