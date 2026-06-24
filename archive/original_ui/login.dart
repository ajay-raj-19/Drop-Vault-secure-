import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultApp());
}

class DropVaultApp extends StatelessWidget {
  const DropVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto', // Replace with your desired font
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isLoading = false;
  bool _isSuccess = false;

  void _handleLogin() async {
    if (_isLoading || _isSuccess) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate network request processing
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    }

    // Simulate navigation/success state delay
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful! Navigating to your vault...'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset state for demo purposes
      setState(() {
        _isSuccess = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient Orbs (Visual Polish)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            right: MediaQuery.of(context).size.width * 0.05,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEB196).withOpacity(0.2), // secondary-container
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.1,
            left: MediaQuery.of(context).size.width * 0.05,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEEDBBF).withOpacity(0.2), // primary-fixed
              ),
            ),
          ),
          // Blur layer for background orbs
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(color: Colors.transparent),
          ),
          
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Brand Anchor
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: const Icon(Icons.security, size: 36, color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Drop Vault',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Welcome back to your digital sanctuary.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A454F), // on-surface-variant
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Glass Panel Card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email Field
                                const Padding(
                                  padding: EdgeInsets.only(left: 16, bottom: 8),
                                  child: Text(
                                    'Email Address',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                      color: Color(0xFF4A454F),
                                    ),
                                  ),
                                ),
                                TextFormField(
                                  decoration: InputDecoration(
                                    hintText: 'name@example.com',
                                    filled: true,
                                    fillColor: const Color(0xFFF8F2F7),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Colors.black26, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Password Field
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, bottom: 8, right: 16),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Password',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF4A454F),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {},
                                        child: const Text(
                                          'Forgot Password?',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF8A4F39), // secondary
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                TextFormField(
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    filled: true,
                                    fillColor: const Color(0xFFF8F2F7),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Colors.black26, width: 2),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Animated Login Button
                                GestureDetector(
                                  onTap: _handleLogin,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: _isSuccess || _isLoading
                                          ? null
                                          : const LinearGradient(
                                              colors: [Color(0xFF6D528E), Color(0xFF8A4F39)],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                      color: _isSuccess 
                                          ? Colors.green[600] 
                                          : _isLoading 
                                              ? const Color(0xFF6D528E) 
                                              : null,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF6D528E).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : _isSuccess
                                              ? const Icon(Icons.check_circle_outline, color: Colors.white)
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Login',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 20,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Icon(Icons.login, color: Colors.white, size: 20),
                                                  ],
                                                ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Divider
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: Colors.black12)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      child: Text(
                                        'OR',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF4A454F).withOpacity(0.7),
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: Colors.black12)),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Google Button
                                OutlinedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.black),
                                  label: const Text(
                                    'Continue with Google',
                                    style: TextStyle(
                                      color: Color(0xFF1D1B1F),
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(0.5),
                                    minimumSize: const Size(double.infinity, 56),
                                    side: const BorderSide(color: Colors.black12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer Links
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(color: Color(0xFF4A454F), fontSize: 16),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Create Account",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}