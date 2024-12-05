import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/services.dart';

class DatabaseHelper {
  static const String tableName = 'airports';

  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;
  DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'airports.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gps_code TEXT,
        iata_code TEXT,
        name TEXT,
        city TEXT,
        subd TEXT,
        country TEXT,
        country_code TEXT,
        elevation TEXT,
        latitude TEXT,
        longitude TEXT,
        tz TEXT,
        lid TEXT
      )
    ''');
  }


  Future<void> importAirportsInBackground(BuildContext context, String jsonFilePath) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if data is already imported
    bool isDataImported = prefs.getBool('isDataImported') ?? false;
    if (isDataImported) {
      print("Data already imported, skipping...");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data already imported!")),
      );
      return;
    }

    try {
      // Run the heavy task in the background
      await compute(_importTask, {'jsonFilePath': jsonFilePath});

      // Set the flag to true
      await prefs.setBool('isDataImported', true);

      print("Data imported successfully in background!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data imported in the background!")),
      );
    } catch (e) {
      print("Error importing data in background: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

// The actual background task
  Future<void> _importTask(Map<String, String> params) async {
    final dbHelper = DatabaseHelper();
    final db = await dbHelper.database;

    // Load JSON file
    String jsonString = await rootBundle.loadString(params['jsonFilePath']!);
    List<dynamic> data = json.decode(jsonString);

    // Insert into SQLite
    for (var airport in data) {
      await db.insert(DatabaseHelper.tableName, {
        'gps_code': airport['gps_code'],
        'iata_code': airport['iata_code'],
        'name': airport['name'],
        'city': airport['city'],
        'subd': airport['subd'],
        'country': airport['country'],
        'country_code': airport['country_code'],
        'elevation': airport['elevation'],
        'latitude': airport['Lat'],
        'longitude': airport['Long'],
        'tz': airport['tz'],
        'lid': airport['lid'],
      });
    }
  }


  Future<void> importAirports(BuildContext context, String jsonFilePath) async {
    final prefs = await SharedPreferences.getInstance();

    // Check if data is already imported
    bool isDataImported = prefs.getBool('isDataImported') ?? false;
    if (isDataImported) {
      print("Data already imported, skipping...");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data already imported!")),
      );
      return;
    }

    final db = await database;

    try {
      // Load JSON from file
      String jsonString = await rootBundle.loadString(jsonFilePath);
      List<dynamic> data = json.decode(jsonString);

      // Insert into SQLite
      for (var airport in data) {
        await db.insert(tableName, {
          'gps_code': airport['gps_code'],
          'iata_code': airport['iata_code'],
          'name': airport['name'],
          'city': airport['city'],
          'subd': airport['subd'],
          'country': airport['country'],
          'country_code': airport['country_code'],
          'elevation': airport['elevation'],
          'latitude': airport['Lat'],
          'longitude': airport['Long'],
          'tz': airport['tz'],
          'lid': airport['lid'],
        });
      }

      // Set the flag to true
      await prefs.setBool('isDataImported', true);

      print("Data imported successfully!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data imported successfully!")),
      );
    } catch (e) {
      print("Error importing data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error importing data: $e")),
      );
    }
  }
  Future<List<Map<String, dynamic>>> fetchAirportsByGpsCode(String query) async {
    final db = await database;
    try {
      return await db.query(
        tableName,
        where: 'gps_code LIKE ?',
        whereArgs: ['$query%'], // Starts with the query
      );
    } catch (e) {
      print('Database query error: $e');
      return [];
    }
  }



  Future<List<Map<String, dynamic>>> fetchAirports() async {
    final db = await database;
    return await db.query(tableName);
  }
}
