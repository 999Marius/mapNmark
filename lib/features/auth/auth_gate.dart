import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:map_n_mark/features/auth/login_screen.dart';
import 'package:map_n_mark/features/professor/professor_home_screen.dart'; // You need to create this
import 'package:map_n_mark/features/student/student_home_screen.dart';     // You need to create this
import 'package:map_n_mark/main.dart';

import '../../services/auth_service.dart';


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
    // 1. Watch the auth state
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (data) {
        final session = data.session;

        if (session == null) {
          print("DEBUG: No session found. Showing LoginScreen.");
          return const LoginScreen();
        }

        print("DEBUG: Session found for user: ${session.user.id}. Fetching role...");

        // 2. Fetch the role from the 'profiles' table
        return FutureBuilder<Map<String, dynamic>>(
          future: supabase
              .from('profiles') // <--- DOUBLE CHECK THIS TABLE NAME IN SUPABASE
              .select('role')
              .eq('id', session.user.id)
              .single(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (snapshot.hasError) {
              print("DEBUG: Database Error fetching role: ${snapshot.error}");
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Error: ${snapshot.error}"),
                      ElevatedButton(
                        onPressed: () => supabase.auth.signOut(),
                        child: const Text("Logout & Try Again"),
                      )
                    ],
                  ),
                ),
              );
            }

            final role = snapshot.data?['role'] as String?;
            print("DEBUG: User role found: $role");

            if (role == 'professor') {
              return const ProfessorHomeScreen();
            } else if (role == 'student') {
              return const StudentHomeScreen();
            }

            return const Scaffold(body: Center(child: Text('Role not found in database')));
          },
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text('Stream Error: $e'))),
    );
  }


}

