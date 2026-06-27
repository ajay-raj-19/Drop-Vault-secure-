import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/brand_logo.dart';

class SignUpPage extends ConsumerStatefulWidget {
  final String? prefilledEmail;
  final String? prefilledPhoto;
  const SignUpPage({super.key, this.prefilledEmail, this.prefilledPhoto});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

  bool _passwordsMatch = true;
  bool _isLoadingGoogle = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  final TextEditingController _verificationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.prefilledEmail ?? '';
    
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

  @override
  void didUpdateWidget(SignUpPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prefilledEmail != oldWidget.prefilledEmail) {
      _emailController.text = widget.prefilledEmail ?? '';
    }
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

  String _getPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return '';
    if (password.length < 6) return 'Weak';
    
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacters = RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_#@]').hasMatch(password);
    
    int score = 0;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigits) score++;
    if (hasSpecialCharacters) score++;
    
    if (score <= 2) return 'Weak';
    if (score == 3) return 'Medium';
    return 'Strong';
  }

  @override
  void dispose() {
    _floatController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigits = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialCharacters = RegExp(r'[!@#\$%^&*(),.?":{}|<>\-_#@]').hasMatch(password);
    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid email address format.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidPassword(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters, with 1 uppercase, 1 lowercase, 1 number, and 1 special character.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await ref.read(authStateProvider.notifier).signUp(email, password, name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _simulateGoogleLogin() async {
    setState(() {
      _isLoadingGoogle = true;
    });
    try {
      final email = await ref.read(authStateProvider.notifier).pickGoogleAccount();
      if (email != null && email.isNotEmpty) {
        final registered = await ref.read(authStateProvider.notifier).isEmailRegistered(email);
        if (registered) {
          await ref.read(authStateProvider.notifier).signInWithGoogle(email, '');
          if (mounted) {
            setState(() {
              _isLoadingGoogle = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingGoogle = false;
              _emailController.text = email;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingGoogle = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingGoogle = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPasswordStrengthIndicator() {
    final strength = _getPasswordStrength();
    if (strength.isEmpty) return const SizedBox.shrink();
    
    Color color;
    double progress;
    switch (strength) {
      case 'Weak':
        color = Colors.red;
        progress = 0.33;
        break;
      case 'Medium':
        color = Colors.orange;
        progress = 0.66;
        break;
      case 'Strong':
      default:
        color = Colors.green;
        progress = 1.0;
        break;
    }
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Password Strength: ',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              Text(
                strength,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
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
                color: const Color(0xFFD9B9FD).withValues(alpha: 0.2), // primary-fixed-dim
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
                color: const Color(0xFFFEB196).withValues(alpha: 0.2), // secondary-container
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(isDesktop ? 16 : 0),
                boxShadow: isDesktop
                    ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20)]
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
                          color: Color(0xFFF3ECF2),
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
                                    BrandLogo(width: 32),
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
                                    color: const Color(0xFF4A454F).withValues(alpha: 0.8),
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
                                      color: Colors.white.withValues(alpha: 0.7),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                          if (!isDesktop) ...[
                            const Center(child: BrandLogo()),
                            const SizedBox(height: 24),
                            const Text(
                              'Drop Vault',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Save Everything. Find Anything.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF4A454F),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                            
                          const Text(
                            'Create your account',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start your 14-day free trial of premium vault services.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Color(0xFF4A454F)),
                          ),
                          const SizedBox(height: 40),

                          _buildTextField('Full Name', Icons.person_outline, 'John Doe', false, controller: _nameController),
                          const SizedBox(height: 16),
                          _buildTextField(
                            'Email Address',
                            Icons.mail_outline,
                            'name@company.com',
                            false,
                            controller: _emailController,
                            enabled: widget.prefilledEmail == null || widget.prefilledEmail!.isEmpty,
                          ),
                          const SizedBox(height: 16),
                          
                          // Passwords
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTextField(
                                        'Password',
                                        Icons.lock_outline,
                                        '••••••••',
                                        true,
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                      _buildPasswordStrengthIndicator(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildTextField(
                                    'Confirm Password',
                                    Icons.shield_outlined,
                                    '••••••••',
                                    true,
                                    controller: _confirmPasswordController,
                                    isError: !_passwordsMatch,
                                    obscureText: _obscureConfirmPassword,
                                    onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextField(
                                  'Password',
                                  Icons.lock_outline,
                                  '••••••••',
                                  true,
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  onToggleVisibility: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                                _buildPasswordStrengthIndicator(),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  'Confirm Password',
                                  Icons.shield_outlined,
                                  '••••••••',
                                  true,
                                  controller: _confirmPasswordController,
                                  isError: !_passwordsMatch,
                                  obscureText: _obscureConfirmPassword,
                                  onToggleVisibility: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
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
                                  boxShadow: [BoxShadow(color: const Color(0xFF6D528E).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
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
                                child: Text('OR CONTINUE WITH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF4A454F).withValues(alpha: 0.7))),
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
                                : Image.asset(
                                    AppAssets.googleLogo,
                                    width: 24,
                                    height: 24,
                                  ),
                            label: Text(
                              _isLoadingGoogle ? 'Connecting...' : 'Sign up with Google',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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
                                onTap: () => context.go('/login'),
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


        ],
      ),
    ),
    );
  }

  // Reusable TextField Builder
  Widget _buildTextField(
    String label,
    IconData icon,
    String hint,
    bool isPassword, {
    TextEditingController? controller,
    bool isError = false,
    bool? obscureText,
    VoidCallback? onToggleVisibility,
    bool? enabled,
  }) {
    final bool isReadOnly = enabled == false;
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
          obscureText: obscureText ?? isPassword,
          enabled: enabled,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: const Color(0xFF7B757F).withValues(alpha: 0.6)),
            prefixIcon: Icon(icon, color: const Color(0xFF7B757F)),
            suffixIcon: onToggleVisibility != null
                ? IconButton(
                    icon: Icon(
                      (obscureText ?? true) ? Icons.visibility_off : Icons.visibility,
                      color: const Color(0xFF7B757F),
                    ),
                    onPressed: onToggleVisibility,
                  )
                : (isReadOnly && label == 'Email Address'
                    ? const Icon(Icons.lock_outline, color: Color(0xFF7B757F))
                    : null),
            filled: true,
            fillColor: isReadOnly ? Colors.grey[200] : const Color(0xFFF8F2F7),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(28),
              borderSide: BorderSide(
                color: isError
                    ? Colors.red
                    : (Theme.of(context).brightness == Brightness.dark
                        ? AppColors.primaryFixedDim
                        : AppColors.secondary),
                width: 2,
              ),
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
