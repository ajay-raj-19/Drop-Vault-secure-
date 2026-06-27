import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = context.appColors.primaryText;
    final onSurfaceVariant = context.appColors.secondaryText;
    final outlineVariant = context.appColors.border;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: background.withValues(alpha: 0.8),
                border: Border(bottom: BorderSide(color: outlineVariant.withValues(alpha: 0.2))),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SafeArea(
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: primary),
                      onPressed: () => context.pop(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 110, bottom: 40, left: 24, right: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms of Service for Drop Vault',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Last Updated: June 24, 2026',
                  style: TextStyle(fontSize: 14, color: onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Acceptable Use', primary),
                      _buildSectionText(
                        'Drop Vault is designed to provide you with a secure, organized space for storing private links, notes, files, and images. You agree not to use the app for any illegal purposes or to store content that violates local, state, national, or international laws.',
                        onSurface
                      ),
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle('2. User Responsibilities', primary),
                      _buildSectionText(
                        'Since Drop Vault is a local-first secure space, all files and structures are held entirely on your device. You are solely responsible for backing up your data, setting secure device authentication codes, and preventing unauthorized physical access to your device. We are not responsible for any data loss occurring due to hardware damage, device transfer, or accidental app deletion.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('3. Content Ownership', primary),
                      _buildSectionText(
                        'You maintain complete intellectual property rights and content ownership of everything you import into the vault. We do not inspect, upload, index, or distribute your stored contents.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('4. Limitation of Liability', primary),
                      _buildSectionText(
                        'To the maximum extent permitted by applicable law, Drop Vault and its developer, Ajay Raj, shall not be liable for any direct, indirect, incidental, punitive, special, or consequential damages, or any loss of profits, data, use, or goodwill, arising out of your use of the application.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('5. Account Termination & Data Management', primary),
                      _buildSectionText(
                        'You can terminate your usage of the application and delete your account data at any time via the Danger Zone on the Account screen. This operation will wipe all local application storage and credentials. The developer reserves the right to suspend or discontinue support for the application at any time without prior notice.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('6. Future Cloud Features', primary),
                      _buildSectionText(
                        'Future updates may introduce secure, end-to-end encrypted synchronization services. Use of these cloud features will be governed by supplementary terms that will be provided upon their release.',
                        onSurface
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildSectionText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 15, color: color, height: 1.5),
      ),
    );
  }
}
