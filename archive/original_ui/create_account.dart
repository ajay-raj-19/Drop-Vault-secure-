import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultSignUpApp());
}

class DropVaultSignUpApp extends StatelessWidget {
  const DropVaultSignUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault Sign Up',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const SignUpPage(),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

  bool _showSuccessOverlay = false;
  bool _passwordsMatch = true;
  bool _isLoadingGoogle = false;

  @override
  void initState() {
    super.initState();
    
    // Setup floating animation for the branding card
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.05),
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // Password match validation listener
    _confirmPasswordController.addListener(_validatePasswords);
    _passwordController.addListener(_validatePasswords);
  }

  void _validatePasswords() {
    if (_confirmPasswordController.text.isNotEmpty) {
      setState(() {
        _passwordsMatch = _passwordController.text == _confirmPasswordController.text;
      });
    } else {
      setState(() {
        _passwordsMatch = true;
      });
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    if (!_passwordsMatch || _passwordController.text.isEmpty) return;

    setState(() {
      _showSuccessOverlay = true;
    });

    // Simulate navigation/redirect delay
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to Home page (Dashboard)...'),
          backgroundColor: Colors.green,
        ),
      );
      // Reset for demo
      setState(() {
        _showSuccessOverlay = false;
      });
    }
  }

  void _simulateGoogleLogin() async {
    setState(() {
      _isLoadingGoogle = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 1500));
    
    setState(() {
      _isLoadingGoogle = false;
    });
    _handleSignup();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Scaffold(
      body: Stack(
        children: [
          // Background Atmospheric Elements
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.1,
            child: Container(
              width: size.width * 0.4,
              height: size.height * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD9B9FD).withOpacity(0.2), // primary-fixed-dim
              ),
            ),
          ),
          Positioned(
            bottom: -size.height * 0.1,
            right: -size.width * 0.1,
            child: Container(
              width: size.width * 0.4,
              height: size.height * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEB196).withOpacity(0.2), // secondary-container
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
            child: Container(color: Colors.transparent),
          ),

          // Main Layout Container
          Center(
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 1200, minHeight: 800),
              margin: EdgeInsets.all(isDesktop ? 24.0 : 0),
              decoration: BoxDecoration(
                color: Colors.white, // surface-container-lowest
                borderRadius: BorderRadius.circular(isDesktop ? 16 : 0),
                boxShadow: isDesktop
                    ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]
                    : [],
              ),
              child: Row(
                children: [
                  // Left Side: Visual/Branding (Desktop Only)
                  if (isDesktop)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(40),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF3ECF2), // surface-container
                          borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.lock_person, size: 32, color: Colors.black),
                                    SizedBox(width: 8),
                                    Text(
                                      'Drop Vault',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 40),
                                const Text(
                                  'Your data, in a digital sanctuary.',
                                  style: TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Experience the premium standard of secure file storage and personal organization.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: const Color(0xFF4A454F).withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Floating Card Element
                            SlideTransition(
                              position: _floatAnimation,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                                  child: Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.7),
                                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFFFDBCF),
                                                borderRadius: BorderRadius.circular(24),
                                              ),
                                              child: const Icon(Icons.verified_user, color: Color(0xFF79422D)),
                                            ),
                                            const SizedBox(width: 16),
                                            const Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('End-to-End Security', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                                Text('Military-grade encryption for every byte.', style: TextStyle(fontSize: 12, color: Color(0xFF4A454F))),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          height: 8,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE7E0E6),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: 0.75,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF8A4F39),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Right Side: Signup Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: isDesktop ? 64 : 24, vertical: 40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!isDesktop)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 32),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_person, size: 32, color: Colors.black),
                                  SizedBox(width: 8),
                                  Text(
                                    'Drop Vault',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            
                          Text(
                            'Create your account',
                            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Start your 14-day free trial of premium vault services.',
                            textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Color(0xFF4A454F)),
                          ),
                          const SizedBox(height: 40),

                          _buildTextField('Full Name', Icons.person_outline, 'John Doe', false),
                          const SizedBox(height: 16),
                          _buildTextField('Email Address', Icons.mail_outline, 'name@company.com', false),
                          const SizedBox(height: 16),
                          
                          // Passwords
                          if (isDesktop)
                            Row(
                              children: [
                                Expanded(child: _buildTextField('Password', Icons.lock_outline, '••••••••', true, controller: _passwordController)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildTextField('Confirm Password', Icons.shield_outlined, '••••••••', true, controller: _confirmPasswordController, isError: !_passwordsMatch)),
                              ],
                            )
                          else
                            Column(
                              children: [
                                _buildTextField('Password', Icons.lock_outline, '••••••••', true, controller: _passwordController),
                                const SizedBox(height: 16),
                                _buildTextField('Confirm Password', Icons.shield_outlined, '••••••••', true, controller: _confirmPasswordController, isError: !_passwordsMatch),
                              ],
                            ),
                          
                          const SizedBox(height: 32),

                          // Submit Button
                          GestureDetector(
                            onTap: _handleSignup,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6D528E), Color(0xFF8A4F39)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [BoxShadow(color: const Color(0xFF6D528E).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Divider
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Colors.black12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text('OR CONTINUE WITH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A454F).withOpacity(0.7))),
                              ),
                              const Expanded(child: Divider(color: Colors.black12)),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Social Login
                          OutlinedButton.icon(
                            onPressed: _simulateGoogleLogin,
                            icon: _isLoadingGoogle 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.g_mobiledata, size: 28, color: Colors.black),
                            label: Text(
                              _isLoadingGoogle ? 'Connecting...' : 'Sign up with Google',
                              style: const TextStyle(color: Colors.black, fontSize: 16),
                            ),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              side: const BorderSide(color: Colors.black12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Footer Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account? ", style: TextStyle(color: Color(0xFF4A454F))),
                              GestureDetector(
                                onTap: () {},
                                child: const Text("Log In", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Success Feedback Overlay
          if (_showSuccessOverlay)
            Positioned.fill(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: _showSuccessOverlay ? 1.0 : 0.0,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    color: const Color(0xFFFEF7FD).withOpacity(0.9),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFDBCF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, size: 64, color: Color(0xFF79422D)),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Account Created!',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Welcome to your new digital sanctuary.',
                            style: TextStyle(fontSize: 18, color: Color(0xFF4A454F)),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'Redirecting you to dashboard...',
                            style: TextStyle(fontSize: 12, color: Color(0xFF7B757F)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Reusable TextField Builder
  Widget _buildTextField(String label, IconData icon, String hint, bool isPassword, {TextEditingController? controller, bool isError = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A454F)),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF7B757F).withOpacity(0.6)),
            prefixIcon: Icon(icon, color: const Color(0xFF7B757F)),
            filled: true,
            fillColor: const Color(0xFFF8F2F7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: isError ? Colors.red : Colors.black, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(color: isError ? Colors.red : Colors.transparent, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}