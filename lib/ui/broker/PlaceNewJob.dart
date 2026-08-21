import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/models/Task.dart';

class PlaceNewJob extends StatefulWidget {
  final Task? data;
  const PlaceNewJob({Key? key, this.data}) : super(key: key);

  @override
  PlaceNewJobState createState() => PlaceNewJobState();
}

class PlaceNewJobState extends State<PlaceNewJob> {
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  final TextEditingController _field3Controller = TextEditingController();
  final TextEditingController _field4Controller = TextEditingController();
  final TextEditingController _field5Controller = TextEditingController();
  final TextEditingController _fieldBidController = TextEditingController();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechAvailable = false;
  String? _activeField; // which field mic is active for

  @override
  void initState() {
    super.initState();
    _initSpeech();
    if (widget.data != null) {
      _field1Controller.text = widget.data!.startDateTime ?? '';
      _field2Controller.text = widget.data!.endDateTime ?? '';
      _field3Controller.text = widget.data!.departureFrom ?? '';
      _field4Controller.text = widget.data!.arriveAt ?? '';
      _fieldBidController.text = widget.data!.bid ?? '';
      _field5Controller.text = widget.data!.flightNumber ?? '';
    }
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _activeField = null),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _activeField = null);
        }
      },
    );
    setState(() => _speechAvailable = available);
  }

  Future<void> _listen(String fieldId, TextEditingController controller, {bool isDateTime = false}) async {
    if (!_speechAvailable) {
      _showSnack('Microphone not available');
      return;
    }

    if (_speech.isListening) {
      await _speech.stop();
      setState(() => _activeField = null);
      return;
    }

    setState(() => _activeField = fieldId);

    await _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          final text = result.recognizedWords;
          if (isDateTime) {
            final dt = _parseSpokenDateTime(text);
            controller.text = dt ?? text;
          } else {
            controller.text = text;
          }
          setState(() => _activeField = null);
        }
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
    );
  }

  String? _parseSpokenDateTime(String text) {
    final months = {
      'january': 1, 'february': 2, 'march': 3, 'april': 4,
      'may': 5, 'june': 6, 'july': 7, 'august': 8,
      'september': 9, 'october': 10, 'november': 11, 'december': 12,
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'jun': 6, 'jul': 7,
      'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };

    final lower = text.toLowerCase();
    int? month, day, year, hour = 0, minute = 0;
    bool pm = lower.contains('pm');
    bool am = lower.contains('am');

    for (final entry in months.entries) {
      if (lower.contains(entry.key)) {
        month = entry.value;
        break;
      }
    }

    final nums = RegExp(r'\d+').allMatches(lower).map((m) => int.parse(m.group(0)!)).toList();

    if (month != null) {
      for (final n in nums) {
        if (n >= 2000 && n <= 2100) { year = n; continue; }
        if (n >= 1 && n <= 31 && day == null) { day = n; continue; }
        if (n >= 0 && n <= 23 && hour == 0) { hour = n; continue; }
        if (n >= 0 && n <= 59 && minute == 0) { minute = n; }
      }
    } else if (nums.length >= 3) {
      day = nums[0]; month = nums[1]; year = nums[2];
      if (nums.length > 3) hour = nums[3];
      if (nums.length > 4) minute = nums[4];
    }

    if (pm && hour != null && hour! < 12) hour = hour! + 12;
    if (am && hour == 12) hour = 0;

    if (year != null && month != null && day != null) {
      try {
        final dt = DateTime(year!, month!, day!, hour ?? 0, minute ?? 0);
        final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
        final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
        return '$date $time';
      } catch (_) {}
    }
    return null;
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _micButton(String fieldId, TextEditingController controller, {bool isDateTime = false}) {
    final isActive = _activeField == fieldId;
    return IconButton(
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isActive ? Icons.mic : Icons.mic_none,
          key: ValueKey(isActive),
          color: isActive ? Palette.errorColor : Palette.primaryColor,
        ),
      ),
      tooltip: isActive ? 'Tap to stop' : 'Tap to speak',
      onPressed: () => _listen(fieldId, controller, isDateTime: isDateTime),
    );
  }

  bool validate() {
    return _field1Controller.text.isNotEmpty &&
        _field2Controller.text.isNotEmpty &&
        _field3Controller.text.isNotEmpty &&
        _field4Controller.text.isNotEmpty &&
        _fieldBidController.text.isNotEmpty &&
        _field5Controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_speechAvailable)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Palette.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Palette.warning.withOpacity(0.4)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, size: 16, color: Palette.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Microphone unavailable — voice input disabled.',
                        style: TextStyle(fontSize: 12, color: Palette.warning)),
                  ),
                ],
              ),
            ),
          _buildDateTimeField('start', 'Start Time & Date', _field1Controller),
          const SizedBox(height: 12),
          _buildDateTimeField('end', 'End Time & Date', _field2Controller),
          const SizedBox(height: 12),
          _buildTextField('dep', 'Departure Location', _field3Controller, Icons.flight_takeoff),
          const SizedBox(height: 12),
          _buildTextField('arr', 'Arrival Location', _field4Controller, Icons.flight_land),
          const SizedBox(height: 12),
          _buildTextField('bid', 'Bid Amount', _fieldBidController, Icons.monetization_on_outlined,
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          _buildTextField('cap', 'Courier Capacity', _field5Controller, Icons.inventory_2_outlined),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDateTimeField(String id, String label, TextEditingController controller) {
    final isActive = _activeField == id;
    return TextField(
      controller: controller,
      readOnly: !isActive,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _micButton(id, controller, isDateTime: true),
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined, size: 20),
              color: Palette.primaryColor,
              onPressed: () => _selectDateAndTime(controller),
            ),
          ],
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isActive ? Palette.errorColor : Palette.primaryColor,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(color: isActive ? Palette.errorColor : null),
        helperText: isActive ? 'Listening… say e.g. "June 24 2026 6 PM"' : null,
        helperStyle: const TextStyle(color: Palette.errorColor, fontSize: 11),
      ),
    );
  }

  Widget _buildTextField(
    String id,
    String label,
    TextEditingController controller,
    IconData prefixIcon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isActive = _activeField == id;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, size: 18),
        suffixIcon: _micButton(id, controller),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isActive ? Palette.errorColor : Palette.primaryColor,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(color: isActive ? Palette.errorColor : null),
        helperText: isActive ? 'Listening… speak now' : null,
        helperStyle: const TextStyle(color: Palette.errorColor, fontSize: 11),
      ),
    );
  }

  Future<void> _selectDateAndTime(TextEditingController controller) async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (selectedDate == null) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (selectedTime == null) return;
    final dt = DateTime(
      selectedDate.year, selectedDate.month, selectedDate.day,
      selectedTime.hour, selectedTime.minute,
    );
    final date = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    final time = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:00';
    controller.text = '$date $time';
  }
}
