// lib/services/attendance_service.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/main.dart';
import 'package:geolocator/geolocator.dart';

class AttendanceService {
  /// 1. Calls the secure database function to join a course
  Future<void> joinCourse(String entryCode) async {
    try {
      final response = await supabase.rpc(
        'join_course_by_code',
        params: {'input_code': entryCode.trim()},
      );

      if (response['success'] == false) {
        throw Exception(response['message']);
      }
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('An unexpected error occurred while joining.');
    }
  }

  // Add this to your AttendanceService class
  Future<void> deleteCourse(String courseId) async {
    await supabase.from('courses').delete().eq('id', courseId);
  }

// Add this at the bottom of the file (outside the class)

  /// 2. Deletes the enrollment record (Leaving a course)
  Future<void> leaveCourse(String courseId) async {
    final userId = supabase.auth.currentUser!.id;

    try {
      await supabase
          .from('course_enrollments')
          .delete()
          .match({'course_id': courseId, 'student_id': userId});
    } catch (e) {
      throw Exception("Failed to leave course: $e");
    }
  }

  /// 3. Logic to verify location and mark attendance
  Future<void> markAttendance(String sessionId) async {
    final userId = supabase.auth.currentUser!.id;

    // A. Fetch Session Data from Supabase
    final session = await supabase
        .from('sessions')
        .select()
        .eq('id', sessionId)
        .single();

    // B. Security Checks: Active & Not Expired
    if (!session['is_active']) {
      throw Exception('This attendance session has been closed by the professor.');
    }


    final expiresAt = DateTime.parse(session['expires_at']);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('This QR code has expired.');
    }

    // C. Get Student's Current Location
    Position studentPos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // D. Calculate Distance (in meters)
    double distance = Geolocator.distanceBetween(
      studentPos.latitude,
      studentPos.longitude,
      session['latitude'],
      session['longitude'],
    );

    // E. Verify Geofence (Radius)
    int allowedRadius = session['radius_meters'] ?? 50;

    if (distance > allowedRadius) {
      throw Exception('You are not in the classroom. (${distance.toInt()}m away)');
    }

    // F. Record Attendance in Database
    try {
      await supabase.from('attendance_records').insert({
        'session_id': sessionId,
        'student_id': userId,
        'distance_verified': distance,
        'status': 'present',
      });
    } catch (e) {
      if (e.toString().contains('duplicate key')) {
        throw Exception('You have already marked attendance for this session.');
      }
      rethrow;
    }
  }
}

// --- PROVIDERS (KEEP THESE AT THE BOTTOM OUTSIDE THE CLASS) ---

// 1. Provider for the service class itself
final attendanceServiceProvider = Provider((ref) => AttendanceService());

// 2. Global Stream Provider for Enrollments (The Single Source of Truth)
final studentEnrollmentsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = supabase.auth.currentUser!.id;

  return supabase
      .from('course_enrollments')
      .stream(primaryKey: ['id'])
      .eq('student_id', userId);
});

final professorCoursesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final user = supabase.auth.currentUser;
  if (user == null) return Stream.value([]);

  return supabase
      .from('courses')
      .stream(primaryKey: ['id'])
      .eq('professor_id', user.id)
      .order('created_at');
});
