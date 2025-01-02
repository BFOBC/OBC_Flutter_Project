import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../ui/common/models/AirportModel.dart';

class DatabaseOperation{
  static final DatabaseOperation _instance = DatabaseOperation._internal();
  static Database? _database;
  static const String tableName = 'airports';
  factory DatabaseOperation() {
    return _instance;
  }

  DatabaseOperation._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'airports.db'),
      onCreate: (db, version) {
        return db.execute('''
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
            lat TEXT,
            long TEXT,
            tz TEXT,
            lid TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  Future<void> insertAirports(List<Map<String, dynamic>> airports) async {
    final db = await database;
    Batch batch = db.batch();
    for (var airport in airports) {
      batch.insert('airports', airport, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit();
  }
  Future<List<Map<String, dynamic>>> fetchAirportsByGpsCode(String query) async {
    final db = await database;
    try {
      final results = await db.query(
        tableName,
        where: 'iata_code LIKE ?',
        whereArgs: ['$query%'],
      );
      print('Fetched results: $results');
      return results;
    } catch (e) {
      print('Database query error: $e');
      return [];
    }
  }
  Future<List<AirportModel>> fetchAirportsFromDatabase(String query) async {
    try {
      final db = await database;
      final results = await db.query(
        tableName,
        where: 'LOWER(iata_code) = ?',
        whereArgs: [query.toLowerCase()],
      );
      return results.map((map) => AirportModel.fromMap(map)).toList();
    } catch (e) {
      print('Error fetching model: $e');
      return [];
    }
  }
  Future<List<Map<String, dynamic>>> getAirports() async {
    final db = await database;
    return db.query('airports');
  }
}
