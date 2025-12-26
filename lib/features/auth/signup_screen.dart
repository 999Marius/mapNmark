import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/services/auth_service.dart';
import 'package:map_n_mark/util/password_strength.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  // Controllers to get text from input fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _selectedRole = 'student';
  final _nameController = TextEditingController();

  // State variables

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  double _passwordStrength = 0;
  List<String> _passwordRequirements = [];

  @override
  void initState() {
    super.initState();
    // Update password strength whenever user types
    _passwordController.addListener(_updatePasswordStrength);
  }

  // Clean up controllers when screen is closed
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Calculate password strength as user types
  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _passwordStrength = PasswordStrength.calculate(password);
      _passwordRequirements = PasswordStrength.unmentRequirements(password);

      // Clear error when user starts typing
      if (password.isNotEmpty) {
        _passwordError = null;
      }
    });
  }

  // Function to handle sign up
  Future<void> _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Check if email is valid
    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );



    // Validate all fields
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;
    String? roleError;
    if(_selectedRole.isEmpty){
      roleError = 'This field is mandatory';
    }

    if (email.isEmpty) {
      emailError = 'This field is mandatory';
    } else if (!emailRegex.hasMatch(email)) {
      emailError = 'Invalid email address';
    }

    if (password.isEmpty) {
      passwordError = 'This field is mandatory';
    } else if (_passwordStrength < 1.0) {
      passwordError = 'Password is not strong enough';
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError = 'This field is mandatory';
    } else if (password != confirmPassword) {
      confirmPasswordError = 'Passwords do not match';
    }

    // If there are errors, show them and stop
    if (emailError != null || passwordError != null || confirmPasswordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
        _confirmPasswordError = confirmPasswordError;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUp(email, password, _selectedRole, _nameController.text);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed up successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate password strength color
    final Color passwordStrengthColor =
    _passwordController.text.isEmpty || _passwordError != null
        ? Colors.transparent
        : PasswordStrength.interpolateColor(_passwordStrength);

    final borderColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.38);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // SafeArea prevents content from being hidden by notches or status bars
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                // This makes sure the content takes up at least the full height
                // of the screen so that MainAxisAlignment.center still works.
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48, // Subtracting vertical padding
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'mapNmark',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 50),

                    // Email input
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        errorText: _emailError,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password input with strength indicator
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: const OutlineInputBorder(),
                        errorText: _passwordError,
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: passwordStrengthColor == Colors.transparent
                                ? borderColor
                                : passwordStrengthColor,
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: passwordStrengthColor == Colors.transparent
                                ? primaryColor
                                : passwordStrengthColor,
                            width: 2.0,
                          ),
                        ),
                      ),
                    ),

                    // Show password strength bar
                    if (_passwordController.text.isNotEmpty && _passwordError == null) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: Colors.grey[300],
                        color: passwordStrengthColor,
                        minHeight: 5,
                      ),
                      if (_passwordRequirements.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var requirement in _passwordRequirements)
                                Text(
                                  '• $requirement',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                    ],
                    const SizedBox(height: 16),

                    // Confirm password input
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        errorText: _confirmPasswordError,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Role Selection
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'I am a...',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'student', child: Text('Student')),
                        DropdownMenuItem(value: 'professor', child: Text('Professor')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign up button
                    SizedBox(
                      width: double.infinity,
                      height: 50, // Added fixed height for consistency
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signUp,
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Go back to login button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Already have an account?'),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Sign In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}