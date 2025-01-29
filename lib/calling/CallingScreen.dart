/*
import 'package:flutter/material.dart';
import 'package:jitsi_meet/jitsi_meet.dart';

class CallingScreen extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  CallingScreen({required this.currentUserId, required this.otherUserId});

  @override
  _CallingScreenState createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  bool isCallActive = false;
  bool isAudioMuted = false;
  bool isVideoMuted = false;

  @override
  void initState() {
    super.initState();
    _initializeCall();

    // Initialize the event listeners
    JitsiMeetingListener meetingListener = JitsiMeetingListener(
      onConferenceJoined: (message) {
        print("Conference Joined: $message");
        setState(() {
          isCallActive = true;
        });
      },
      onConferenceTerminated: (message) {
        print("Conference Terminated: $message");
        setState(() {
          isCallActive = false;
        });
      },
      onError: (error) {
        print("Error: $error");
      },
    );

    JitsiMeet.addListener(meetingListener);
  }

  // Initialize the call
  void _initializeCall() async {
    var options = JitsiMeetingOptions(room: "room_${widget.currentUserId}_${widget.otherUserId}")
      ..serverURL = "https://meet.jit.si"
      ..subject = "Video Call"
      ..userDisplayName = "User ${widget.currentUserId}"
      ..audioOnly = false
      ..videoMuted = false;

    try {
      await JitsiMeet.joinMeeting(options, listener: JitsiMeetingListener(
        onConferenceJoined: (message) {
          print("Conference Joined: $message");
        },
        onConferenceTerminated: (message) {
          print("Conference Terminated: $message");
        },
        onError: (error) {
          print("Error: $error");
        },
      ));
    } catch (e) {
      print("Error in starting the call: $e");
    }
  }

  // End the call
  void _endCall() async {
    try {
      await JitsiMeet.closeMeeting();
      setState(() {
        isCallActive = false;
      });
    } catch (e) {
      print("Error in ending the call: $e");
    }
  }

  // Toggle audio mute (Using available methods)
  void _toggleAudio() async {
    setState(() {
      isAudioMuted = !isAudioMuted;
    });
    try {
      // If toggleAudioMute does not exist, try setting audioOnly
      await JitsiMeet.joinMeeting(JitsiMeetingOptions(room: "room_${widget.currentUserId}_${widget.otherUserId}")
        ..audioMuted = isAudioMuted);  // Update this based on available options
    } catch (e) {
      print("Error in toggling audio mute: $e");
    }
  }


  // Toggle video mute (Using available methods)
  void _toggleVideo() async {
    setState(() {
      isVideoMuted = !isVideoMuted;
    });
    try {
      // If toggleVideoMute does not exist, try setting videoMuted
      await JitsiMeet.joinMeeting(JitsiMeetingOptions(room: "room_${widget.currentUserId}_${widget.otherUserId}")
        ..videoMuted = isVideoMuted);  // Update this based on available options
    } catch (e) {
      print("Error in toggling video mute: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    // Remove listeners when the screen is disposed
    JitsiMeet.removeAllListeners();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calling Screen"),
        actions: [
          IconButton(
            icon: Icon(Icons.close),
            onPressed: _endCall,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Calling ${widget.otherUserId}",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            isCallActive
                ? Column(
              children: [
                ElevatedButton(
                  onPressed: _toggleAudio,
                  child: Text(isAudioMuted ? "Unmute Audio" : "Mute Audio"),
                ),
                ElevatedButton(
                  onPressed: _toggleVideo,
                  child: Text(isVideoMuted ? "Unmute Video" : "Mute Video"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _endCall,
                  child: Text("End Call"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            )
                : ElevatedButton(
              onPressed: _initializeCall,
              child: Text("Start Call"),
            ),
          ],
        ),
      ),
    );
  }
}
*/
