import 'package:flutter/material.dart';

import '../../data/DatabaseHelper.dart';

class AirportsScreen extends StatelessWidget {
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Airports"),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_download),
            onPressed: () async {
              await dbHelper.importAirports(context, 'assets/airports.json');
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: dbHelper.fetchAirports(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            final airports = snapshot.data!;
            if (airports.isEmpty) {
              return Center(child: Text("No airports found!"));
            }
            return ListView.builder(
              itemCount: airports.length,
              itemBuilder: (context, index) {
                final airport = airports[index];
                return ListTile(
                  title: Text(airport['name']),
                  subtitle: Text("${airport['city']}, ${airport['country']}"),
                );
              },
            );
          }
        },
      ),
    );
  }
}
