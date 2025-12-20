import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:map_n_mark/features/auth/login_screen.dart';
import 'package:map_n_mark/features/auth/signup_screen.dart';

import 'features/auth/auth_gate.dart';
final supabase = Supabase.instance.client;

Future<void> main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ainxxpfgfkwyzufufjgx.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFpbnh4cGZnZmt3eXp1ZnVmamd4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE5Mjk3MzIsImV4cCI6MjA3NzUwNTczMn0.s69qyD5yKFadgF-zJS2qibi3lEbAcd2ZZ9ua1cSVRXA',
  );
  runApp(const ProviderScope(child: MyApp()));
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'mapNmark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true),

      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignUpScreen(),
        // Define your home routes here if you want to pushNamed later
      },
    );
  }
}
