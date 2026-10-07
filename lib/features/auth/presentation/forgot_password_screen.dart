import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import 'providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

enum ForgotStep { enterEmail, success }

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  
  bool _isLoading = false;
  ForgotStep _currentStep = ForgotStep.enterEmail;
  int _retryCount = 0;
  static const int _maxRetries = 3;
  
  int _secondsRemaining = 0;
  Timer? _timer;

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _secondsRemaining = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    return emailRegex.hasMatch(email);
  }

  void _handleSendLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email address.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_retryCount >= _maxRetries) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum resend attempts exceeded. Please try again later.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).recoverPassword(email);
      _startResendTimer();
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = ForgotStep.success;
          _retryCount++;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recovery link sent successfully! Please check your inbox.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
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
                          'Password Recovery',
                          style: TextStyle(fontSize: 16, color: Color(0xFF4A454F)),
                        ),
                        const SizedBox(height: 40),

                        // Glass Panel Card
                        GlassCard(
                          padding: const EdgeInsets.all(32),
                          borderRadius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_currentStep == ForgotStep.enterEmail) ...[
                                const Padding(
                                  padding: EdgeInsets.only(left: 16, bottom: 8),
                                  child: Text(
                                    'Email Address',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4A454F)),
                                  ),
                                ),
                                TextFormField(
                                  controller: _emailController,
                                  decoration: InputDecoration(
                                    hintText: 'name@example.com',
                                    filled: true,
                                    fillColor: const Color(0xFFF8F2F7),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                  style: const TextStyle(color: Colors.black),
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 24),
                                GestureDetector(
                                  onTap: _isLoading ? null : _handleSendLink,
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(28),
                                      gradient: _isLoading
                                          ? null
                                          : const LinearGradient(
                                              colors: [Color(0xFF6D528E), Color(0xFF8A4F39)],
                                            ),
                                      color: _isLoading ? const Color(0xFF6D528E) : null,
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : const Text('Send Recovery Link', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                                    ),
                                  ),
                                ),
                              ] else if (_currentStep == ForgotStep.success) ...[
                                const Icon(Icons.mark_email_read_outlined, size: 72, color: Colors.green),
                                const SizedBox(height: 16),
                                const Text(
                                  'Email Sent',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'We\'ve sent a recovery link to ${_emailController.text.trim()}. Please click the link to reset your password.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                
                                // Cooldown resend timer
                                TextButton(
                                  onPressed: _secondsRemaining > 0 || _retryCount >= _maxRetries ? null : _handleSendLink,
                                  child: Text(
                                    _secondsRemaining > 0 ? 'Resend link in ${_secondsRemaining}s' : 'Resend Email',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _secondsRemaining > 0 || _retryCount >= _maxRetries ? Colors.grey : const Color(0xFF8A4F39),
                                    ),
                                  ),
                                ),
                                
                                if (_retryCount >= _maxRetries)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: Text(
                                      'Resend limit reached.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 24),
                              TextButton(
                                onPressed: () {
                                  _timer?.cancel();
                                  context.go('/login');
                                },
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
