import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:map_n_mark/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
class AuthService {
  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      print('Error during sign-in: $e');
    }
  }
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}
final authServiceProvider = Provider((ref) => AuthService());