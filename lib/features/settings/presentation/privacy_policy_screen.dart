import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                color: background.withOpacity(0.8),
                border: Border(bottom: BorderSide(color: outlineVariant.withOpacity(0.2))),
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
                      'Privacy Policy',
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
                  'Privacy Policy for Drop Vault',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Effective Date: June 24, 2026',
                  style: TextStyle(fontSize: 14, color: onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 24),
                
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('1. Zero Cloud Data Collection by Default', primary),
                      _buildSectionText(
                        'Drop Vault is designed as a local-first secure storage application. Your credentials, links, notes, files, images, and other vault contents are stored locally on your device\'s sandbox storage. By default, we do not operate, host, or sync with any remote cloud servers, meaning we do not collect, view, or store your private data on our servers.',
                        onSurface
                      ),
                      const SizedBox(height: 20),
                      
                      _buildSectionTitle('2. Local Storage Usage', primary),
                      _buildSectionText(
                        'The application utilizes SharedPreferences and device sandboxed file storage to locally persist your profile data, collections structure, saved vault items, reminders, and trashed information. This data remains completely under your control and is accessible only on the specific device it was created on.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('3. User Content Ownership', primary),
                      _buildSectionText(
                        'You retain full, exclusive ownership rights to any and all information, links, notes, images, or files you import into Drop Vault. We claim no ownership, licenses, or rights to your digital content.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('4. Future Cloud Synchronization Architecture', primary),
                      _buildSectionText(
                        'In future phases (including upcoming Windows desktop application releases), Drop Vault will support optional cloud sync between your Android and Windows devices. Any future synchronization will be fully end-to-end encrypted (E2EE), meaning only you hold the keys to decrypt your files, and no unauthorized parties (including developers) can read your data.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('5. Account and Data Deletion', primary),
                      _buildSectionText(
                        'You have the absolute right to delete your account at any time. Triggering the account deletion routine in the Danger Zone completely wipes the local SharedPreferences, application databases, files, and credentials from your device. This operation is permanent and cannot be undone.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('6. Security Practices', primary),
                      _buildSectionText(
                        'We implement industry-standard cryptographic practices to secure local sandboxed files and SharedPreferences records. Since your data is stored locally, the physical security of your device remains your responsibility. We recommend securing your device with biometric authentication or secure PIN/passwords.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('7. User Rights and Indian Compliance Context', primary),
                      _buildSectionText(
                        'This privacy policy is designed in compliance with the Digital Personal Data Protection (DPDP) Act, 2023 and the Information Technology Act, 2000 of India. As a user, you have the right to request access, correction, restriction, and erasure of your local data. Since the app is local-first, you can exercise these rights directly within the app without needing developer intervention.',
                        onSurface
                      ),
                      const SizedBox(height: 20),

                      _buildSectionTitle('8. Contact and Support Information', primary),
                      _buildSectionText(
                        'For any privacy concerns, security vulnerability reports, or compliance inquiries, you may contact the developer directly:\n\nAjay Raj\nEmail: ajay.raj.cd24@ggits.net\nInstitution: Gyan Ganga Institute of Technology and Sciences',
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
