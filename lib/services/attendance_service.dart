// lib/services/attendance_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/main.dart';

class AttendanceService {
  /// Calls the secure database function to join a course
  Future<void> joinCourse(String entryCode) async {
    try {
      // We call the SQL function 'join_course_by_code'
      // This is safer than doing SELECT and INSERT manually in Flutter
      final response = await supabase.rpc(
        'join_course_by_code',
        params: {'input_code': entryCode.trim()},
      );

      // The SQL function returns a JSON object {success: bool, message: string}
      if (response['success'] == false) {
        throw Exception(response['message']);
      }
    } catch (e) {
      // If it's a known error from our SQL, throw it.
      // Otherwise, throw a generic error.
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print('Database Error: $e');
      throw Exception('An unexpected error occurred while joining.');
    }
  }
}

final attendanceServiceProvider = Provider((ref) => AttendanceService());