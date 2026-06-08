import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final supabase = Supabase.instance.client;

  String _selectedRole = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;    // 👈 for show/hide password
  bool _rememberMe = false;        // 👈 for remember me
  String _errorMessage = '';

  final Map<String, Color> roleColors = {
    'student':   Color(0xFF1565C0),
    'lecturer':  Color(0xFF2E7D32),
    'registrar': Color(0xFF6A1B9A),
    'treasury':  Color(0xFFE65100),
    'pusatadab': Color(0xFF00838F),
  };

  final Map<String, IconData> roleIcons = {
    'student':   Icons.school,
    'lecturer':  Icons.cast_for_education,
    'registrar': Icons.admin_panel_settings,
    'treasury':  Icons.account_balance_wallet,
    'pusatadab': Icons.emoji_events,
  };

  final Map<String, String> roleLabels = {
    'student':   'Student',
    'lecturer':  'Lecturer',
    'registrar': 'Registrar',
    'treasury':  'Treasury',
    'pusatadab': 'Pusat Adab',
  };

  @override
  void initState() {
    super.initState();
    _loadRememberedCredentials(); // 👈 load saved credentials on start
  }

  // Load saved credentials
  Future<void> _loadRememberedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe) {
      setState(() {
        _rememberMe = true;
        _emailController.text = prefs.getString('saved_email') ?? '';
        _passwordController.text = prefs.getString('saved_password') ?? '';
        _selectedRole = prefs.getString('saved_role') ?? 'student';
      });
    }
  }

  // Save or clear credentials
  Future<void> _saveCredentials(String email, String password, String role) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('saved_email', email);
      await prefs.setString('saved_password', password);
      await prefs.setString('saved_role', role);
    } else {
      await prefs.remove('remember_me');
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.remove('saved_role');
    }
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        setState(() => _errorMessage = 'Login failed. Please try again.');
        return;
      }

      final profile = await supabase
          .from('profiles')
          .select('role, name')
          .eq('id', response.user!.id)
          .maybeSingle();

      if (profile == null) {
        setState(() => _errorMessage = 'Profile not found. Contact admin.');
        await supabase.auth.signOut();
        return;
      }

      final role = profile['role'] as String;
      final name = profile['name'] as String;

      if (role != _selectedRole) {
        setState(() => _errorMessage =
            'This account is not a ${roleLabels[_selectedRole]}. Please select the correct role.');
        await supabase.auth.signOut();
        return;
      }

      // Save credentials if remember me is checked
      await _saveCredentials(email, password, role);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(role: role, name: name),
        ),
      );

    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = roleColors[_selectedRole]!;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.7)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Icon & Title
                  Icon(roleIcons[_selectedRole], size: 64, color: Colors.white),
                  const SizedBox(height: 12),
                  const Text('SAMS',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 4)),
                  const Text('UMPSA Academic System',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 28),

                  // Role Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: roleLabels.keys.map((role) {
                          final isSelected = _selectedRole == role;
                          return GestureDetector(
                            onTap: () => setState(() {
                              _selectedRole = role;
                              _errorMessage = '';
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Icon(roleIcons[role],
                                      size: 20,
                                      color: isSelected
                                          ? roleColors[role]
                                          : Colors.white70),
                                  const SizedBox(height: 4),
                                  Text(roleLabels[role]!,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? roleColors[role]
                                              : Colors.white70)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Login as ${roleLabels[_selectedRole]}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: color)),
                        const SizedBox(height: 20),

                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email, color: color),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: color, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field with Show/Hide
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword, // 👈
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock, color: color),
                            suffixIcon: IconButton(  // 👈 eye icon
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: color,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: color, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Remember Me Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              activeColor: color,
                              onChanged: (value) =>
                                  setState(() => _rememberMe = value ?? false),
                            ),
                            const Text('Remember Me',
                                style: TextStyle(fontSize: 14)),
                          ],
                        ),

                        // Error Message
                        if (_errorMessage.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_errorMessage,
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: color,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _login,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)
                                : const Text('Login',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}