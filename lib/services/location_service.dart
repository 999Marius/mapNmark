import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_n_mark/services/auth_service.dart';
import 'package:map_n_mark/util/password_strength.dart';

class SignUpScreen extends ConsumerStatefulWidget{
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool isLoading = false;
  String? _emailErrorText;
  String? _passwordErrorText;
  String? _confirmPasswordErrorText;
  double _passwordStrength = 0;
  List<String> _passwordRequirements = [];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _passwordStrength = PasswordStrength.calculate(password);
      _passwordRequirements = PasswordStrength.unmentRequirements(password);
      if (password.isNotEmpty) {
        _passwordErrorText = null;
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {

    setState(() {
      isLoading = true;
      _emailErrorText = null;
      _passwordErrorText = null;
      _confirmPasswordErrorText = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    bool hasError = false;

    if(email.isEmpty){
      setState(() {
        _emailErrorText = 'This field is mandatory';
        hasError = true;
      });
    } else if(!emailRegex.hasMatch(email)){
      setState(() {
        _emailErrorText = 'Invalid email address';
        hasError = true;
      });
    }

    if(password.isEmpty){
      setState(() {
        _passwordErrorText = 'This field is mandatory';
        hasError = true;
      });
    } else if (_passwordStrength < 1.0) {
      setState(() {
        _passwordErrorText = 'Password is not strong enough';
        hasError = true;
      });
    }

    if (password != confirmPassword) {
      setState(() {
        _confirmPasswordErrorText = 'Passwords do not match';
        hasError = true;
      });
    }

    if (hasError) {
      setState(() => isLoading = false);
      return;
    }

    try{
      final authService = ref.read(authServiceProvider);
      await authService.signUp(email, password);

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signed up successfully! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }catch(e){
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final Color passwordStrengthColor = _passwordController.text.isEmpty || _passwordErrorText != null
        ? Colors.transparent
        : PasswordStrength.interpolateColor(_passwordStrength);

    final borderColor = Theme.of(context).colorScheme.onSurface.withOpacity(0.38);
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 50),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  errorText: _emailErrorText,
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  errorText: _passwordErrorText,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: passwordStrengthColor == Colors.transparent
                            ? borderColor
                            : passwordStrengthColor,
                        width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: passwordStrengthColor == Colors.transparent
                            ? primaryColor
                            : passwordStrengthColor,
                        width: 2.0),
                  ),
                ),
              ),

              if (_passwordController.text.isNotEmpty && _passwordErrorText == null) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: _passwordStrength,
                  backgroundColor: Colors.grey[300],
                  color: passwordStrengthColor,
                  minHeight: 5,
                ),
                if(_passwordRequirements.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _passwordRequirements.map((req) => Text('• $req', style: Theme.of(context).textTheme.bodySmall)).toList(),
                    ),
                  ),
              ],

              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  errorText: _confirmPasswordErrorText,
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _signUp,
                  child: isLoading
                      ? const SizedBox(
                      height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}