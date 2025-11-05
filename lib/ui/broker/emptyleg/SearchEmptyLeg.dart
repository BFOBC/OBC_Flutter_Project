import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/ui/broker/emptyleg/AddNewMilestoneEmptLeg.dart';
import 'package:broker_flutter_pp/ui/broker/mission/BrokerMissions.dart';
import 'package:broker_flutter_pp/ui/chat/ChatDetailScreen.dart';
import 'package:broker_flutter_pp/ui/common/models/AirportModel.dart';
import 'package:broker_flutter_pp/ui/common/models/FlightData.dart';
import 'package:broker_flutter_pp/ui/common/utils/DateTimePicker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../common/utils/CustomDialog.dart';



class SearchEmptyLegScreen extends StatefulWidget {
  SearchEmptyLegScreen({super.key});

  @override
  _SearchEmptyLegScreenState createState() => _SearchEmptyLegScreenState();
}

class _SearchEmptyLegScreenState extends State<SearchEmptyLegScreen> {
  String courierID = "";
  final TextEditingController _searchController1 = TextEditingController();
  final TextEditingController _searchController2 = TextEditingController();

  List<FlightData> flights = [];
  List<FlightData> filteredFlights = [];
  List<AirportModel> fromAirportSuggestions =
      []; // Suggestions for "From Location"
  List<AirportModel> toAirportSuggestions = []; // Suggestions for "To Location"
  AirportModel? selectedFromAirport;
  AirportModel? selectedToAirport;
  String? departureLocation;
  String? arrivalLocation;
  String? endDateTime;
  String? startDateTime;
  String? emptyLegTBLNodeID;

  @override
  void initState() {
    super.initState();
    _fetchFlights(); // Fetch model from Firestore when screen initializes
  }

  // Fetch airports that match the query for From Location
  Future<void> _fetchFromAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() {
          fromAirportSuggestions = airports;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() {
        fromAirportSuggestions = [];
      });
    }
  }

  // Fetch airports that match the query for To Location
  Future<void> _fetchToAirportData(String query) async {
    if (query.isNotEmpty) {
      try {
        final airports = await fetchAirportsFromDatabase(query);
        setState(() {
          toAirportSuggestions = airports;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error fetching airports: $e')));
      }
    } else {
      setState(() {
        toAirportSuggestions = [];
      });
    }
  }

  Future<List<AirportModel>> fetchAirportsFromDatabase(String query) async {
    final dbHelper = DatabaseOperation();
    try {
      List<AirportModel> airports =
          await dbHelper.fetchAirportsFromDatabase(query);
      return airports;
    } catch (e) {
      print('Error _fetchAirports $e');
      return [];
    }
  }

  void _fetchFlights() {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('User is not authenticated');
        return;
      }

      FirebaseFirestore.instance
          .collection('emptyLegs')
          .where('status', isEqualTo: 'new')
          .snapshots()
          .listen((snapshot) {
        final List<FlightData> flightList = [];

        for (var doc in snapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;

            // Defensive null checks
            if (!data.containsKey('fromDateTime') ||
                !data.containsKey('toDateTime') ||
                data['fromDateTime'] == null ||
                data['toDateTime'] == null) {
              print('⛔ Skipped invalid record: missing date field');
              continue; // skip invalid flight
            }

            final fromDateTime = data['fromDateTime'] is Timestamp
                ? (data['fromDateTime'] as Timestamp).toDate()
                : DateTime.tryParse(data['fromDateTime'].toString());

            final toDateTime = data['toDateTime'] is Timestamp
                ? (data['toDateTime'] as Timestamp).toDate()
                : DateTime.tryParse(data['toDateTime'].toString());

            if (fromDateTime == null || toDateTime == null) {
              print('⚠️ Skipped invalid datetime parse for doc: ${doc.id}');
              continue;
            }

            final capacity = data['capacity']?.toString() ?? "N/A";
            final courierID2 = data['courierID']?.toString() ?? "N/A";

            flightList.add(FlightData(
              fromDateTime: fromDateTime,
              toDateTime: toDateTime,
              fromLocation: data['fromLocation'] ?? '',
              toLocation: data['toLocation'] ?? '',
              flightNumber: data['flightNumber'] ?? '',
              emptyLegTBLNodeID: data['emptyLegNodeID'] ?? '',
              capacity: capacity,
              courierID: courierID2,
            ));
          } catch (innerError, st) {
            print('⚠️ Error parsing doc ${doc.id}: $innerError');
            print(st);
          }
        }

        setState(() {
          flights = flightList;
          filteredFlights = flightList;
        });
      });
    } catch (e, st) {
      print("❌ Error fetching flights: $e");
      print(st);
    }
  }


  void _filterFlights() {
    final departureQuery = _searchController1.text.toLowerCase();
    final arrivalQuery = _searchController2.text.toLowerCase();

    setState(() {
      filteredFlights = flights.where((flight) {
        final matchesDeparture =
            flight.fromLocation.toLowerCase().contains(departureQuery);
        final matchesArrival =
            flight.toLocation.toLowerCase().contains(arrivalQuery);
        return matchesDeparture && matchesArrival;
      }).toList();
    });
  }

  double _calculateProgress(DateTime start, DateTime end) {
    try {
      // 🔹 Convert UTC → Local time for proper comparison
      final DateTime localStart = start.toLocal();
      final DateTime localEnd = end.toLocal();
      final DateTime now = DateTime.now();

      // 🔹 Grace buffer (5 min) to avoid false early completion
      final DateTime bufferedEnd = localEnd.add(const Duration(minutes: 5));

      // 🛑 Invalid or same datetimes
      if (localEnd.isBefore(localStart) || localEnd.isAtSameMomentAs(localStart)) {
        return 0.0;
      }

      // 🔹 Before start
      if (now.isBefore(localStart)) {
        return 0.0;
      }

      // 🔹 After end (with grace period)
      if (now.isAfter(bufferedEnd)) {
        return 1.0;
      }

      // 🔹 Use milliseconds for precision
      final totalDuration = localEnd.difference(localStart).inMilliseconds;
      final elapsed = now.difference(localStart).inMilliseconds;

      // 🔹 Avoid divide-by-zero errors
      if (totalDuration <= 0) return 0.0;

      // 🔹 Compute progress safely
      double progress = elapsed / totalDuration;

      // 🔹 Clamp 0–1 range
      return progress.clamp(0.0, 1.0);
    } catch (e, st) {
      print('⚠️ Error in _calculateProgress: $e');
      print(st);
      return 0.0; // Safe fallback
    }
  }

  void _showFlightDialog(BuildContext context, FlightData flight) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: StatefulBuilder(
            builder: (context, setState) {
              bool isBooked = false;

              return Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Header with close button
                      Stack(
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(
                                top: 20, left: 8, right: 50, bottom: 10),
                            child: Center(
                              child: Text(
                                '✈️ Empty Leg Details',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      /// Main detail card with FAB at bottom-right
                      Stack(
                        children: [
                          /// Info Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabelValue(
                                    "Flight Number", flight.flightNumber),
                                _buildLabelValue(
                                    "Start Time",
                                    DateFormat('dd MMMM yyyy HH:mm:ss')
                                        .format(flight.fromDateTime.toLocal())),
                                _buildLabelValue(
                                    "End Time",
                                    DateFormat('dd MMMM yyyy HH:mm:ss')
                                        .format(flight.toDateTime.toLocal())),
                                _buildLabelValue("Arrival", flight.toLocation),
                                _buildLabelValue(
                                    "Departure", flight.fromLocation),
                                _buildLabelValue("Capacity", flight.capacity),
                              ],
                            ),
                          ),

                          /// FAB at bottom-right of the info card
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: FloatingActionButton(
                              heroTag: 'chatBtn',
                              mini: true,
                              backgroundColor: Colors.blue,
                              onPressed: () {
                                print('Chatttttttttttt');
                                print(flight.courierID);
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ChatDetailScreen(userID: flight.courierID),
                                  ),
                                );
                              },
                              child: const Icon(Icons.chat,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      /// Book Button (centered)
                      Center(
                        child: isBooked
                            ? const Icon(Icons.airplane_ticket,
                                size: 40, color: Colors.green)
                            : ElevatedButton.icon(
                                onPressed: () {
                                  departureLocation =
                                      flight.fromLocation.toString();
                                  arrivalLocation =
                                      flight.toLocation.toString();
                                  startDateTime =
                                      flight.fromDateTime.toString();
                                  endDateTime = flight.toDateTime.toString();
                                  emptyLegTBLNodeID=flight.emptyLegTBLNodeID.toString();
                                  //_sendBookRequest();
                                  navigateToMileStone(flight);
                                  setState(() => isBooked = true);
                                },
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.white, size: 14),
                                label: const Text('Add Mile Stones'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 45, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                ),
                              ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLabelValue(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text(
              value != null && value.toString().isNotEmpty
                  ? value.toString()
                  : 'N/A',
              style: const TextStyle(fontSize: 15, color: Colors.black54)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arrival Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController2,
                decoration: InputDecoration(
                  hintText: 'Arrival',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController2.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController2.clear();
                          },
                        )
                      : null,
                ),
                onChanged: (String value) {
                  print("Arrival text changed: $value");
                  _fetchFromAirportData(value);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  // ✅ Letters + spaces only
                ],
              ),
            ),

            // Show suggestions below 'From Location'
            if (fromAirportSuggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: fromAirportSuggestions.length,
                itemBuilder: (context, index) {
                  final airport = fromAirportSuggestions[index];
                  return ListTile(
                    title: Text(airport.name ?? 'Unknown'),
                    onTap: () {
                      setState(() {
                        FocusScope.of(context).unfocus();
                        _searchController2.text = airport.name ?? '';
                        selectedFromAirport = airport;
                        fromAirportSuggestions = [];
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 15),

            // Departure Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                border: Border.all(color: Colors.green, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController1,
                decoration: InputDecoration(
                  hintText: 'Departure',
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController1.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            _searchController1.clear(); // Clear text input
                          },
                        )
                      : null, // Don't show the icon if text is empty
                ),
                onChanged: (String value) {
                  // This callback is triggered every time the user types.
                  print("Departure text changed: $value");

                  _fetchToAirportData(value);
                },
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  // Allows only letters and spaces
                ],
              ),
            ),
            // Show suggestions below 'From Location'
            if (toAirportSuggestions.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                itemCount: toAirportSuggestions.length,
                itemBuilder: (context, index) {
                  final airport = toAirportSuggestions[index];
                  return ListTile(
                    title: Text(airport.name ?? 'Unknown'),
                    onTap: () {
                      setState(() {
                        FocusScope.of(context).unfocus();
                        _searchController1.text = airport.name ?? '';
                        selectedToAirport = airport;
                        toAirportSuggestions = [];
                      });
                    },
                  );
                },
              ),
            const SizedBox(height: 15),
            // Search Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 120,
                  height: 35,
                  child: ElevatedButton(
                    onPressed: _filterFlights,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                    ),
                    child: const Text(
                      'Search',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10), // بٹنوں کے درمیان فاصلہ
                SizedBox(
                  width: 120, // برابر width
                  height: 35, // برابر height
                  child: ElevatedButton(
                    onPressed: _resetFlights,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40.0),
                      ),
                    ),
                    child: const Text(
                      'Reset',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 5),

            // Filtered Items List
            // Filtered Items List
            Expanded(
              child: filteredFlights.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.airplanemode_inactive,
                            color: Colors.red, size: 50),
                        const SizedBox(height: 10),
                        const Text(
                          'No Empty Legs Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ))
                  : ListView.builder(
                itemCount: filteredFlights.length,
                itemBuilder: (context, index) {
                  final flight = filteredFlights[index];

                  // 🕒 Convert UTC → Local
                  final DateTime startLocal = flight.fromDateTime.toLocal();
                  final DateTime endLocal = flight.toDateTime.toLocal();
                  final DateTime now = DateTime.now();

                  // ❌ Skip expired flights (end time passed)
                  if (now.isAfter(endLocal)) {
                    return const SizedBox.shrink();
                  }

                  // 🔹 Calculate progress
                  double progress = _calculateProgress(startLocal, endLocal);

                  // 🔹 Format dates for UI
                  String startDate = DateFormat('dd MMM yyyy, hh:mm a').format(startLocal);
                  String endDate = DateFormat('dd MMM yyyy, hh:mm a').format(endLocal);

                  return GestureDetector(
                    onTap: () => _showFlightDialog(context, flight),
                    child: Card(
                      color: Colors.white,
                      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Blue Vertical Line
                            Container(
                              width: 4,
                              height: 190,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 10),

                            // Flight Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Arrival:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    flight.toLocation,
                                    style: const TextStyle(fontSize: 16),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    'Departure:',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    flight.fromLocation,
                                    style: const TextStyle(fontSize: 16),
                                  ),

                                  const SizedBox(height: 8),

                                  // Progress Bar
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[300],
                                    color: Colors.red,
                                  ),

                                  const SizedBox(height: 10),

                                  // 🗓️ Start Date
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today,
                                          size: 18, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Start: $startDate',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // 🗓️ End Date
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month,
                                          size: 18, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text(
                                        'End: $endDate',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            ),
          ],
        ),
      ),
    );
  }

// Function to Reset Flights List
  void _resetFlights() {
    setState(() {
      _searchController1.clear();
      _searchController2.clear();
      filteredFlights =
          List.from(flights); // Reset the list to original flights
    });
  }

  @override
  void dispose() {
    _searchController1.dispose();
    _searchController2.dispose();
    super.dispose();
  }

  String getCurrentUserId() {
    // Replace this with your actual logic to retrieve the user ID
    return FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  }

  Future<void> _sendBookRequest() async {
    try {
      String brokerID = getCurrentUserId();
      // Generate a custom nodeID (you can replace this with any unique value generator)
      String nodeID =
          FirebaseFirestore.instance.collection('emptyLegRequests').doc().id;
      String currentDateTime = DateTime.now().toString();
      //String UTCTime=  convertToUTCFromCustomFormat(currentDateTime.toString());
      String UTCTime =
          convertToUTCFromStandardFormat(currentDateTime.toString());
      await FirebaseFirestore.instance
          .collection('emptyLegRequests')
          .doc(nodeID)
          .set({
        'emptyLegRequestID': nodeID, // Add nodeID explicitly
        'brokerID': brokerID,
        'status': "pending",
        'requestDateTime': UTCTime,
        'courierID': courierID,
        'arrivalLocation': arrivalLocation,
        'departureLocation': departureLocation,
        'endTimeDate': endDateTime.toString(),
        'startTimeDate': startDateTime.toString(),
        'emptyLegTBLNodeID':emptyLegTBLNodeID.toString()
      });

      showCustomDialog2(context, "Request Successfully");
    } catch (e) {
      CustomDialog.showCustomDialog2(context, "Error: ${e.toString()}");
    }
  }

  Future<void> showCustomDialog2(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      // 👈 true = dialog closes on back press or tap outside
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async {
            Navigator.of(dialogContext).pop(); // Close the dialog on back press
            return false; // prevent pushing anything else
          },
          child: AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 10),
                Text(message),
              ],
            ),
            actions: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  margin: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      Navigator.pushReplacement(
                        // ✅ replace so it doesn't go back
                        context,
                        MaterialPageRoute(
                          builder: (context) => BrokerMissions(),
                        ),
                      );
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void navigateToMileStone(FlightData flight) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNewMilestoneEmptyLeg(courierID: courierID,flightData: flight)),
    );
  }
}
