import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import 'providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  final String? email;
  const ResetPasswordPage({super.key, this.email});

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
    
    // Check if recovery session is active
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _errorMessage = 'Invalid or expired password recovery link. Please request a new recovery link from the Forgot Password screen.';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _getPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) return '';
    if (password.length < 8) return 'Weak';
    
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

  void _handleResetPassword() async {
    if (_isLoading) return;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Password must be at least 8 characters long.';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = widget.email ?? Supabase.instance.client.auth.currentUser?.email ?? '';
      await ref.read(authStateProvider.notifier).updatePassword(email, password);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
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
            // Background Orbs
            Positioned(
              top: size.height * 0.1,
              right: size.width * 0.05,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEB196).withValues(alpha: 0.2),
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
                  color: const Color(0xFFEEDBFF).withValues(alpha: 0.2),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),

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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
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
                          'Reset Account Password',
                          style: TextStyle(fontSize: 16, color: Color(0xFF4A454F)),
                        ),
                        const SizedBox(height: 40),

                        // Glass Panel Card
                        GlassCard(
                          padding: const EdgeInsets.all(32),
                          borderRadius: 16,
                          child: _isSuccess
                              ? const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline, size: 72, color: Colors.green),
                                    SizedBox(height: 16),
                                    Text(
                                      'Password Updated',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Your password has been reset successfully. Redirecting you to login...',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_errorMessage != null) ...[
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red[200]!),
                                        ),
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(color: Colors.red, fontSize: 13),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    
                                    if (Supabase.instance.client.auth.currentSession != null) ...[
                                      // Password fields
                                      const Padding(
                                        padding: EdgeInsets.only(left: 16, bottom: 8),
                                        child: Text(
                                          'New Password',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A454F)),
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          filled: true,
                                          fillColor: const Color(0xFFF8F2F7),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                          ),
                                        ),
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                      _buildPasswordStrengthIndicator(),
                                      const SizedBox(height: 16),
                                      
                                      const Padding(
                                        padding: EdgeInsets.only(left: 16, bottom: 8),
                                        child: Text(
                                          'Confirm Password',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A454F)),
                                        ),
                                      ),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          filled: true,
                                          fillColor: const Color(0xFFF8F2F7),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                          suffixIcon: IconButton(
                                            icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                          ),
                                        ),
                                        style: const TextStyle(color: Colors.black),
                                      ),
                                      const SizedBox(height: 24),
                                      
                                      GestureDetector(
                                        onTap: _isLoading ? null : _handleResetPassword,
                                        child: Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(28),
                                            gradient: _isLoading
                                                ? null
                                                : const LinearGradient(colors: [Color(0xFF6D528E), Color(0xFF8A4F39)]),
                                            color: _isLoading ? const Color(0xFF6D528E) : null,
                                          ),
                                          child: Center(
                                            child: _isLoading
                                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                                : const Text('Update Password', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                          ),
                                        ),
                                      ),
                                    ],
                                    
                                    const SizedBox(height: 24),
                                    TextButton(
                                      onPressed: () => context.go('/login'),
                                      child: const Text(
                                        'Back to Login',
                                        style: TextStyle(color: Color(0xFF8A4F39), fontWeight: FontWeight.bold),
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
          ],
        ),
      ),
    );
  }
}
