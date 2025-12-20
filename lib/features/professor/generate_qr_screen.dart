import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_n_mark/main.dart'; // for supabase

class GenerateQrScreen extends StatefulWidget {
  final String courseId;
  final String courseName;

  const GenerateQrScreen({
    super.key,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  String? _sessionId;
  bool _isLoading = false;
  String? _errorMessage;

  // 1. Get Location and Create Session
  Future<void> _createSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // A. Check Permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      // B. Get Current Position (This sets the "Center" of the class)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // C. Insert into Supabase
      final data = await supabase
          .from('sessions')
          .insert({
        'course_id': widget.courseId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'is_active': true,
      })
          .select('id') // Return the ID
          .single();

      setState(() {
        _sessionId = data['id'];
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance: ${widget.courseName}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_sessionId == null && !_isLoading) ...[
                const Icon(Icons.location_on, size: 64, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Start Attendance Session',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This will grab your current location as the valid classroom area.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _createSession,
                    child: const Text('Generate QR Code'),
                  ),
                ),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ] else if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Getting location & creating session...'),
              ] else ...[
                // QR CODE DISPLAY
                const Text(
                  'Scan to Mark Attendance',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: QrImageView(
                    data: _sessionId!, // The Data is just the UUID of the session
                    version: QrVersions.auto,
                    size: 250.0,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Students must be nearby to sign in.',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () {
                    // Logic to end session could go here (update is_active = false)
                    Navigator.pop(context);
                  },
                  child: const Text('End Session'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}