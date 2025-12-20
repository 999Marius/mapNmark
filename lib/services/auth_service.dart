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

  Future<void> signUp(String email, String password, String role,
      String fullName) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'role': role,
          'full_name': fullName,
        },
      );

      if (response.user != null &&
          response.user!.identities != null &&
          response.user!.identities!.isEmpty) {
        throw Exception(
            'This email is already registered. Please sign in instead.');
      }
    } catch (e) {
      print('Error during sign-up: $e');
      rethrow;
    }
  }

  Future<String?> getUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .single();
      return data['role'] as String?;
    } catch (e) {
      print('Error during getting user role: $e');
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

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print('Error during sign-out: $e');
      rethrow;
    }
  }
}
final authServiceProvider = Provider((ref) => AuthService());