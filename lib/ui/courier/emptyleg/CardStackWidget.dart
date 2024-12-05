import 'package:broker_flutter_pp/ui/courier/emptyleg/EmptyLegMainScreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';

class CardStackWidget extends StatefulWidget {
  final List<String> emptyLegRequestIds;

  const CardStackWidget({Key? key, required this.emptyLegRequestIds, required List<FlightDetails> flightDetailsList}) : super(key: key);

  @override
  _CardStackWidgetState createState() => _CardStackWidgetState();
}

class _CardStackWidgetState extends State<CardStackWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> brokerRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBrokerRequests();
  }

  Future<void> _fetchBrokerRequests() async {
    try {
      List<Map<String, dynamic>> requests = [];

      for (String requestId in widget.emptyLegRequestIds) {
        final requestDoc = await _firestore.collection('emptyLegRequests').doc(requestId).get();

        if (requestDoc.exists) {
          final requestData = requestDoc.data()!;
          final String brokerId = requestData['brokerID'] ?? '';

          if (brokerId.isNotEmpty) {
            final brokerDoc = await _firestore.collection('broker').doc(brokerId).get();

            if (brokerDoc.exists) {
              final brokerData = brokerDoc.data()!;
              requests.add({
                'brokerId': brokerId,
                'brokerName': brokerData['name'] ?? 'Unknown Broker',
                'profileUrl': brokerData['profileUrl'] ?? 'https://via.placeholder.com/150',
                'rating': brokerData['rating'] ?? 0,
                'fromLocation': requestData['fromLocation'] ?? 'N/A',
                'toLocation': requestData['toLocation'] ?? 'N/A',
                'requestDate': requestData['date'] ?? 'N/A',
                'capacity': requestData['capacity'] ?? 'N/A',
              });
            }
          }
        }
      }

      setState(() {
        brokerRequests = requests;
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
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: brokerRequests.length,
                itemBuilder: (context, index) {
                  return _buildBrokerCard(brokerRequests[index], screenWidth);
                },
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
        margin: const EdgeInsets.all(8.0),
        child: Container(
          width: screenWidth * 0.7,
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipOval(
                    child: Image.network(
                      brokerDetails['profileUrl'],
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      brokerDetails['brokerName'],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text('From: ${brokerDetails['fromLocation']}'),
              Text('To: ${brokerDetails['toLocation']}'),
              Text('Date: ${brokerDetails['requestDate']}'),
              Text('Capacity: ${brokerDetails['capacity']}'),
              const Spacer(),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (brokerDetails['rating'] as int).round()
                        ? Icons.star
                        : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrokerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> brokerDetails;

  const BrokerDetailsScreen({Key? key, required this.brokerDetails}) : super(key: key);

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
            Text('Request Details:', style: const TextStyle(fontWeight: FontWeight.bold)),
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
