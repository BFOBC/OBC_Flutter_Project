import 'package:broker_flutter_pp/data/sqflitelocal/DatabaseOperation.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
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
            courierID = data['courierID']?.toString() ?? "N/A";

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
                              backgroundColor: Palette.primaryColor,
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
                                size: 40, color: Palette.primaryColor)
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
                                  backgroundColor: Palette.primaryColor,
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
      backgroundColor: Palette.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Arrival Search Bar
            _buildSearchField(
              controller: _searchController2,
              hint: 'Arrival Airport',
              onChanged: (v) { _fetchFromAirportData(v); },
              onClear: () { setState(() { _searchController2.clear(); }); },
            ),

            if (fromAirportSuggestions.isNotEmpty)
              _buildSuggestionList(fromAirportSuggestions, (airport) {
                setState(() {
                  FocusScope.of(context).unfocus();
                  _searchController2.text = airport.name ?? '';
                  selectedFromAirport = airport;
                  fromAirportSuggestions = [];
                });
              }),

            const SizedBox(height: 12),

            // Departure Search Bar
            _buildSearchField(
              controller: _searchController1,
              hint: 'Departure Airport',
              onChanged: (v) { _fetchToAirportData(v); },
              onClear: () { setState(() { _searchController1.clear(); }); },
            ),

            if (toAirportSuggestions.isNotEmpty)
              _buildSuggestionList(toAirportSuggestions, (airport) {
                setState(() {
                  FocusScope.of(context).unfocus();
                  _searchController1.text = airport.name ?? '';
                  selectedToAirport = airport;
                  toAirportSuggestions = [];
                });
              }),

            const SizedBox(height: 14),

            // Search & Reset buttons row
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _filterFlights,
                    icon: const Icon(Icons.search_rounded, size: 16),
                    label: const Text('Search'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetFlights,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Palette.textSecondary,
                      side: const BorderSide(color: Palette.border, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Filtered Items List
            Expanded(
              child: filteredFlights.isEmpty
                  ? Center(
                      child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72, height: 72,
                          decoration: BoxDecoration(color: Palette.errorColor.withOpacity(0.08), shape: BoxShape.circle),
                          child: const Icon(Icons.airplanemode_inactive_rounded, color: Palette.errorColor, size: 36),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Empty Legs Available',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Palette.textSecondary,
                          ),
                        ),
                      ],
                    ))
                  : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: filteredFlights.length,
                    itemBuilder: (context, index) {
                      final flight = filteredFlights[index];

                      final DateTime startLocal = flight.fromDateTime.toLocal();
                      final DateTime endLocal = flight.toDateTime.toLocal();
                      final DateTime now = DateTime.now();

                      if (now.isAfter(endLocal)) return const SizedBox.shrink();

                      double progress = _calculateProgress(startLocal, endLocal);
                      String startDate = DateFormat('dd MMM yyyy, hh:mm a').format(startLocal);
                      String endDate = DateFormat('dd MMM yyyy, hh:mm a').format(endLocal);

                      return GestureDetector(
                        onTap: () => _showFlightDialog(context, flight),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Palette.surface,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Palette.primaryColor.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Colored left accent
                                Container(
                                  width: 4,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    color: Palette.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Route row
                                      Row(
                                        children: [
                                          const Icon(Icons.flight_land_rounded, size: 15, color: Palette.secondaryColor),
                                          const SizedBox(width: 5),
                                          const Text('Arrival', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Palette.textSecondary)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(flight.toLocation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.textPrimary)),

                                      const SizedBox(height: 8),

                                      Row(
                                        children: [
                                          const Icon(Icons.flight_takeoff_rounded, size: 15, color: Palette.primaryColor),
                                          const SizedBox(width: 5),
                                          const Text('Departure', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Palette.textSecondary)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(flight.fromLocation, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Palette.textPrimary)),

                                      const SizedBox(height: 10),

                                      // Progress bar
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: progress,
                                          backgroundColor: Palette.border,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            progress < 0.5 ? Palette.success : (progress < 0.8 ? Palette.warning : Palette.errorColor),
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          const Icon(Icons.schedule_rounded, size: 14, color: Palette.secondaryColor),
                                          const SizedBox(width: 5),
                                          Expanded(child: Text('Start: $startDate', style: const TextStyle(fontSize: 12, color: Palette.textSecondary))),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.event_rounded, size: 14, color: Palette.errorColor),
                                          const SizedBox(width: 5),
                                          Expanded(child: Text('End: $endDate', style: const TextStyle(fontSize: 12, color: Palette.textSecondary))),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const Icon(Icons.chevron_right_rounded, color: Palette.textDisabled, size: 20),
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

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.border, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 14, color: Palette.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Palette.textDisabled, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: Palette.primaryColor, size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Palette.textSecondary, size: 18),
                  onPressed: onClear,
                  splashRadius: 18,
                )
              : null,
        ),
        onChanged: onChanged,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
      ),
    );
  }

  Widget _buildSuggestionList(List<AirportModel> airports, Function(AirportModel) onSelect) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 160),
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Palette.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Palette.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: airports.length,
        itemBuilder: (context, index) {
          final airport = airports[index];
          return InkWell(
            onTap: () => onSelect(airport),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.flight_rounded, size: 14, color: Palette.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(child: Text(airport.name ?? 'Unknown', style: const TextStyle(fontSize: 13, color: Palette.textPrimary))),
                ],
              ),
            ),
          );
        },
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
          child: Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Palette.primaryColor.withOpacity(0.1),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.check_circle_rounded, color: Palette.primaryColor, size: 48),
                ),
                const SizedBox(height: 20),
                Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Palette.textSecondary, height: 1.5)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Palette.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BrokerMissions(),
                        ),
                      );
                    },
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
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
