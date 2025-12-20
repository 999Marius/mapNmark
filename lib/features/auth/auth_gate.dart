import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:map_n_mark/features/auth/login_screen.dart';
import 'package:map_n_mark/features/professor/professor_home_screen.dart'; // You need to create this
import 'package:map_n_mark/features/student/student_home_screen.dart';     // You need to create this
import 'package:map_n_mark/main.dart';


class AuthGate extends ConsumerStatefulWidget{
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState  extends ConsumerState<AuthGate>{
  bool _isLoading = true;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkUser();
  }

  Future<void> _checkUser() async {
    final session = supabase.auth.currentSession;

    if (session != null) {
      try {
        // 1. Use the correct table name 'profiles'
        // 2. Explicitly type the variable as Map<String, dynamic>
        final Map<String, dynamic> data = await supabase
            .from('profiles')
            .select('role')
            .eq('id', session.user.id)
            .single();

        if (mounted) {
          setState(() {
            _role = data['role'] as String?; // Safely cast the role
            _isLoading = false;
          });
        }
      } catch (e) {
        // If error (e.g., profile doesn't exist), sign out
        print("Error fetching profile: $e");
        await supabase.auth.signOut();
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if(_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator(),),);

    final session = supabase.auth.currentSession;

    if (session == null) {
      return const LoginScreen();
    }

    if (_role == 'professor') {
      return const ProfessorHomeScreen();
    } else if (_role == 'student') {
      return const StudentHomeScreen();
    }

    return const Scaffold(body: Center(child: Text('Role not found'),),);
  }



}

