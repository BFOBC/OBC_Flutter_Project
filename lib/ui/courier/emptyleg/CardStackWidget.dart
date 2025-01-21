import 'package:broker_flutter_pp/data/FirestoreService.dart';
import 'package:flutter/material.dart';

class CardStackWidget extends StatefulWidget {
  const CardStackWidget({
    Key? key,
  }) : super(key: key);

  @override
  _CardStackWidgetState createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget> {
  List<Map<String, dynamic>> brokerRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBrokerRequests();
  }

  Future<void> _fetchBrokerRequests() async {
    try {
      FirestoreService firestoreService = FirestoreService(context);
      List<Map<String, dynamic>> requests =
      await firestoreService.getEmptyLegRequestsWithBrokers();

      List<Map<String, dynamic>> formattedRequests = requests.map((request) {
        return {
          'brokerName': request['broker']?['name'] ?? 'N/A',
          'profileUrl': request['broker']?['profilePictureUrl'] ??
              'https://via.placeholder.com/50',
          'fromLocation': request['departureLocation'] ?? 'Unknown',
          'toLocation': request['arrivalLocation'] ?? 'Unknown',
          'requestDate': request['requestDateTime']?.split('T')[0] ?? 'N/A',
          'capacity': request['courierCapacity']?.toString() ?? 'N/A',
          'rating': (request['broker']?['rating'] ?? 0).toInt(),
        };
      }).toList();
      print('Broker Requests');
      print(requests);

      setState(() {
        brokerRequests = formattedRequests;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching broker requests: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : brokerRequests.isEmpty
        ? const Center(child: Text("No requests found"))
        : Container(
      height: MediaQuery.of(context).size.height * 0.3, // 30% of screen height
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: brokerRequests.length,
        itemBuilder: (context, index) {
          return _buildBrokerCard(brokerRequests[index], screenWidth);
        },
      ),
    );
  }

  Widget _buildBrokerCard(Map<String, dynamic> brokerDetails, double screenWidth) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BrokerDetailsScreen(brokerDetails: brokerDetails),
          ),
        );
      },
      child: Card(
        elevation: 4,
        child: Container(
          width: screenWidth * 0.75, // 75% of screen width for better fitting
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Prevent unnecessary space
            children: [
              // Broker name and details
              Text(
                brokerDetails['brokerName'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text('From: ${brokerDetails['fromLocation']}'),
              Text('To: ${brokerDetails['toLocation']}'),
              Text('Date: ${brokerDetails['requestDate']}'),
              Text('Capacity: ${brokerDetails['capacity']}'),

              // Rating stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < brokerDetails['rating'] ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
              const SizedBox(height: 5),  // This ensures no extra space below the content
            ],
          ),
        ),
      ),
    );
  }

}

class BrokerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> brokerDetails;

  const BrokerDetailsScreen({Key? key, required this.brokerDetails})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(brokerDetails['brokerName'])),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipOval(
                child: Image.network(
                  brokerDetails['profileUrl'],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Name: ${brokerDetails['brokerName']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text('Rating: ${brokerDetails['rating']}'),
            const Divider(height: 20),
            Text('Request Details:',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('From: ${brokerDetails['fromLocation']}'),
            Text('To: ${brokerDetails['toLocation']}'),
            Text('Date: ${brokerDetails['requestDate']}'),
            Text('Capacity: ${brokerDetails['capacity']}'),
          ],
        ),
      ),
    );
  }
}
