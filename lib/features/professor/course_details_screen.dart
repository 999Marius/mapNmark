import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for Clipboard
import 'generate_qr_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  // 1. State variable to track visibility
  bool _isCodeVisible = false;

  @override
  Widget build(BuildContext context) {
    final String entryCode = widget.course['code'] ?? 'No Code';

    return Scaffold(
      appBar: AppBar(title: const Text("Course Details")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course['name'],
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // --- STUDENT ENTRY CODE SECTION ---
            const Text(
              "STUDENT ENTRY CODE",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  // 2. Conditional Text: Show dots or the actual code
                  Expanded(
                    child: Text(
                      _isCodeVisible ? entryCode : "••••••••",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _isCodeVisible ? Colors.deepPurple : Colors.grey,
                        letterSpacing: _isCodeVisible ? 2.0 : 4.0,
                      ),
                    ),
                  ),

                  // 3. Toggle Visibility Button
                  IconButton(
                    icon: Icon(
                      _isCodeVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey[600],
                    ),
                    onPressed: () {
                      setState(() {
                        _isCodeVisible = !_isCodeVisible;
                      });
                    },
                  ),

                  // 4. Copy Button (Only enabled/visible when code is shown)
                  if (_isCodeVisible)
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.deepPurple),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: entryCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Code '$entryCode' copied!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Reveal and share this code with your students.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const Spacer(),

            // --- ATTENDANCE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenerateQrScreen(
                        courseId: widget.course['id'],
                        courseName: widget.course['name'],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text("GENERATE ATTENDANCE QR",
                    style: TextStyle(fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}