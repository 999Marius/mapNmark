// lib/features/professor/widgets/add_course_sheet.dart
import 'package:flutter/material.dart';
import 'package:map_n_mark/main.dart';

class AddCourseSheet extends StatefulWidget {
  const AddCourseSheet({super.key});

  @override
  State<AddCourseSheet> createState() => _AddCourseSheetState();
}

class _AddCourseSheetState extends State<AddCourseSheet> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submit() async {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await supabase.from('courses').insert({
        'professor_id': supabase.auth.currentUser!.id,
        'name': _nameController.text,
        'code': _codeController.text,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Add New Course", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Course Name')),
          TextField(controller: _codeController, decoration: const InputDecoration(labelText: 'Course Code')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              child: _isLoading ? const CircularProgressIndicator() : const Text("Create Course"),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}