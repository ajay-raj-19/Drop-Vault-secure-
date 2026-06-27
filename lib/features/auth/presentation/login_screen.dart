import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/widgets/brand_logo.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_isLoading || _isSuccess) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).signIn(email, password);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() {
          _isSuccess = false;
        });
      }
    } catch (e) {
      final errMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (errMsg == 'Unverified Account') {
          _showVerificationCodeDialog(email);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errMsg),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showVerificationCodeDialog(String email) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Account Verification', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the 6-digit verification code sent to your email to activate your account.'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: 'Verification Code', hintText: 'Enter 6-digit code...'),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                try {
                  Navigator.pop(ctx);
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (c) => const Center(child: CircularProgressIndicator()),
                  );
                  await ref.read(authStateProvider.notifier).verifyEmail(email, code);
                  if (mounted) {
                    Navigator.pop(context); // close spinner
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Account verified and logged in successfully!'), backgroundColor: Colors.green),
                    );
                    context.go('/main/dashboard');
                  }
                } catch (err) {
                  if (mounted) {
                    Navigator.pop(context); // close spinner
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(err.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final email = await ref.read(authStateProvider.notifier).pickGoogleAccount();
      if (email != null && email.isNotEmpty) {
        final registered = await ref.read(authStateProvider.notifier).isEmailRegistered(email);
        if (registered) {
          await ref.read(authStateProvider.notifier).signInWithGoogle(email, '');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            context.go('/signup', extra: {'email': email});
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        body: Stack(
        children: [
          // Background Gradient Orbs (Visual Polish)
          Positioned(
            top: size.height * 0.1,
            right: size.width * 0.05,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFEB196).withValues(alpha: 0.2), // secondary-container
              ),
            ),
          ),
          Positioned(
            bottom: size.height * 0.1,
            left: size.width * 0.05,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFEEDBFF).withValues(alpha: 0.2), // primary-fixed
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
                      // Brand Logo
                      const BrandLogo(),
                      const SizedBox(height: 24),
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
                        'Save Everything. Find Anything.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF4A454F), // on-surface-variant
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Glass Panel Card
                      GlassCard(
                        padding: const EdgeInsets.all(32),
                        borderRadius: 16,
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
                              controller: _emailController,
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
                                  borderSide: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.primaryFixedDim
                                        : AppColors.secondary,
                                    width: 2,
                                  ),
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
                                    onTap: () => context.go('/forgot-password'),
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
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: const Color(0xFF7B757F),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF8F2F7),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppColors.primaryFixedDim
                                        : AppColors.secondary,
                                    width: 2,
                                  ),
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
                                      color: const Color(0xFF6D528E).withValues(alpha: 0.3),
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
                                      color: const Color(0xFF4A454F).withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider(color: Colors.black12)),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Google Button
                            OutlinedButton.icon(
                              onPressed: _handleGoogleLogin,
                              icon: Image.asset(
                                AppAssets.googleLogo,
                                width: 24,
                                height: 24,
                              ),
                              label: Text(
                                'Continue with Google',
                                style: TextStyle(
                                  color: const Color(0xFF1D1B1F).withValues(alpha: 0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.5),
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
                            onTap: () => context.go('/signup'),
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
    ),
    );
  }
}
