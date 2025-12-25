// lib/features/student/widgets/join_course_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/services/attendance_service.dart';

class JoinCourseDialog extends ConsumerStatefulWidget {
  const JoinCourseDialog({super.key});

  @override
  ConsumerState<JoinCourseDialog> createState() => _JoinCourseDialogState();
}

class _JoinCourseDialogState extends ConsumerState<JoinCourseDialog> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (_codeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(attendanceServiceProvider).joinCourse(_codeController.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Joined course successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Join Course"),
      content: TextField(
        controller: _codeController,
        decoration: const InputDecoration(
          labelText: "Entry Code",
          hintText: "e.g. MAT101",
          border: OutlineInputBorder(),
        ),
        textCapitalization: TextCapitalization.characters,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleJoin,
          child: _isLoading ? const CircularProgressIndicator(strokeWidth: 2) : const Text("Join"),
        ),
      ],
    );
  }
}