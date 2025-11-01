
import 'package:flutter/material.dart';

class PasswordStrength{
  static double calculate(String password) {
    if (password.isEmpty) return 0;

    double strength = 0;

    if (password.length >= 8) strength += 0.25;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.25;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.25;

    return strength.clamp(0, 1);
  }

  static Color interpolateColor(double strength) {
    strength = strength.clamp(0, 1);

    if (strength <= 0.25) {
      return Color.lerp(Colors.red, Colors.orange, strength / 0.25)!;
    } else if (strength <= 0.5) {
      return Color.lerp(Colors.orange, Colors.yellow, (strength - 0.25) / 0.25)!;
    } else if (strength <= 0.75) {
      return Color.lerp(Colors.yellow, Colors.lightGreen, (strength - 0.5) / 0.25)!;
    } else {
      return Color.lerp(Colors.lightGreen, Colors.green, (strength - 0.75) / 0.25)!;
    }
  }

  static List<String> unmentRequirements(String password) {
    List<String> missing = [];
    if (password.length < 8) missing.add('At least 8 characters');
    if (!RegExp(r'[A-Z]').hasMatch(password)) missing.add('At least one uppercase letter');
    if (!RegExp(r'[a-z]').hasMatch(password)) missing.add('At least one lowercase letter');
    if(!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) missing.add('At least one special character');
    return missing;
  }
}