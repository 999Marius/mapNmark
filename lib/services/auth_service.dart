import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:map_n_mark/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  Future<void> signIn(String email, String password) async {
    try {
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error during sign-in: $e');
      rethrow;
    }
  }

  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  Future<void> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null &&
          response.user!.identities != null &&
          response.user!.identities!.isEmpty) {
        throw Exception('This email is already registered. Please sign in instead.');
      }
    }catch (e) {
      print('Error during sign-up: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('Error during password reset: $e');
      rethrow;
    }
  }
}



final authServiceProvider = Provider((ref) => AuthService());