// lib/features/student/widgets/attendance_receipt_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class AttendanceReceiptSheet extends StatelessWidget {
  final Map<String, dynamic> record;
  final Map<String, dynamic> session;

  const AttendanceReceiptSheet({super.key, required this.record, required this.session});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(record['created_at']).toLocal();
    final sessionPos = LatLng(session['latitude'], session['longitude']);

    return Container(
      padding: const EdgeInsets.all(24),
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(session['name'] ?? "Unnamed Session",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text("Status: ${record['status'].toString().toUpperCase()}",
              style: TextStyle(color: record['status'] == 'present' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Date: ${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute}"),
          const SizedBox(height: 20),

          const Text("SESSION LOCATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: FlutterMap(
                options: MapOptions(initialCenter: sessionPos, initialZoom: 16, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                  CircleLayer(circles: [
                    CircleMarker(
                      point: sessionPos,
                      radius: (session['radius_meters'] as num).toDouble(),
                      useRadiusInMeter: true,
                      color: Colors.green.withOpacity(0.2),
                      borderColor: Colors.green,
                    ),
                  ]),
                  MarkerLayer(markers: [
                    Marker(point: sessionPos, child: const Icon(Icons.location_on, color: Colors.red, size: 30)),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          )
        ],
      ),
    );
  }
}