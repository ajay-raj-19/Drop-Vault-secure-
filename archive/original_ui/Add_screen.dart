import 'package:flutter/material.dart';

void main() {
  runApp(const DropVaultAddItemApp());
}

class DropVaultAddItemApp extends StatelessWidget {
  const DropVaultAddItemApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drop Vault - Add Item',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFFEF7FD),
        primaryColor: Colors.black,
      ),
      home: const AddItemPage(),
    );
  }
}

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  // Theme Colors
  static const Color background = Color(0xFFFEF7FD);
  static const Color primary = Colors.black;
  static const Color primaryFixed = Color(0xFFEEDBFF);
  static const Color onPrimaryFixed = Color(0xFF270B46);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF8F2F7);
  static const Color surfaceContainerHigh = Color(0xFFEDE6EC);
  static const Color onSurface = Color(0xFF1D1B1F);
  static const Color onSurfaceVariant = Color(0xFF4A454F);
  static const Color outlineVariant = Color(0xFFCCC4D0);
  static const Color secondary = Color(0xFF8A4F39);
  static const Color secondaryContainer = Color(0xFFFEB196);
  static const Color onSecondaryContainer = Color(0xFF79422D);

  bool _isReminderEnabled = true;
  final List<String> _tags = ['research', '2024'];
  final TextEditingController _tagController = TextEditingController();

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  void _addTag(String tag) {
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
    }
    _tagController.clear();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background Overlay
          Container(color: primary.withOpacity(0.05)),

          // Main Layout
          Row(
            children: [
              if (isDesktop) _buildDesktopSideNav(),
              Expanded(
                child: Column(
                  children: [
                    _buildAppBar(isDesktop),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 672), // max-w-2xl
                            child: _buildMainContent(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Bottom Nav (Mobile Only)
          if (!isDesktop)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildMobileBottomNav(),
            ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDesktop) {
    return Container(
      height: 72,
      padding: EdgeInsets.only(
        left: isDesktop ? 40 : 24,
        right: 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: onSurface),
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: onSurfaceVariant.withOpacity(0.1),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Drop Vault',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
              ),
            ],
          ),
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFDBCF),
              image: DecorationImage(
                image: NetworkImage('https://lh3.googleusercontent.com/aida-public/AB6AXuDsxLur2JxojRH4GAHT8Pb--Pxk-EM3bSmhJnZ8tcwojyKvMMmhsJZBtmTXNGxEDx-dCNVys75Gbte9Xubx8SqzJ1wZNyJR5ytLMWqP00lenJo7j4CUEkd5Wz9iU0MxHYEOUgbjARPMFUikH68gaiFhD5Ofy2q_QUe-A8syC47kJ_hUClS6_gcYh2k1Fq74ZQ-nGX-eicZGvAi1cYWykMjasXdVA4lSjDd0HacLMxxeCHPuekCvjzgSyHv6hRy_76v1coRXp-dEhqyT'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Container(
      margin: const EdgeInsets.only(bottom: 100),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text('Add New Item', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 8),
          const Text('Securely store a new piece of your digital world.', style: TextStyle(fontSize: 16, color: onSurfaceVariant)),
          const SizedBox(height: 32),

          // Action Grid
          _buildActionGrid(),
          const SizedBox(height: 32),

          // Dropdown
          _buildDropdown(),
          const SizedBox(height: 24),

          // Tags Input
          _buildTagsInput(),
          const SizedBox(height: 24),

          // Reminders
          _buildReminderSection(),
          const SizedBox(height: 32),

          // Save Button
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return GridView.count(
      crossAxisCount: isMobile ? 2 : 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildQuickAction('Add Link', Icons.link, secondary, surfaceContainerLow, outlineVariant.withOpacity(0.5)),
        _buildQuickAction('Add Note', Icons.note_add, onPrimaryFixed, primaryFixed, Colors.transparent),
        _buildQuickAction('Upload File', Icons.upload_file, secondary, surfaceContainerLow, outlineVariant.withOpacity(0.5)),
        _buildQuickAction('Add Image', Icons.image, secondary, surfaceContainerLow, outlineVariant.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildQuickAction(String title, IconData icon, Color iconColor, Color bgColor, Color borderColor) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SELECT COLLECTION', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: 'Personal Research',
              icon: const Icon(Icons.expand_more, color: onSurfaceVariant),
              items: ['Personal Research', 'Project Phoenix', 'Financial Documents', 'Inspiration Box']
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: onSurface)),
                );
              }).toList(),
              onChanged: (_) {},
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ADD TAGS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1, color: onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          minHeight: 56,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: secondary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outlineVariant.withOpacity(0.5)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ..._tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('#$tag', style: const TextStyle(fontSize: 12, color: onSecondaryContainer)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeTag(tag),
                          child: const Icon(Icons.close, size: 16, color: onSecondaryContainer),
                        ),
                      ],
                    ),
                  )),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    hintText: 'Type and enter...',
                    hintStyle: TextStyle(fontSize: 14),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: _addTag,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.notifications, color: primary),
                  SizedBox(width: 12),
                  Text('Set Reminder', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
              Switch(
                value: _isReminderEnabled,
                onChanged: (val) {
                  setState(() {
                    _isReminderEnabled = val;
                  });
                },
                activeColor: Colors.white,
                activeTrackColor: primary,
                inactiveThumbColor: Colors.white,
                inactiveTrackColor: outlineVariant,
              ),
            ],
          ),
          const SizedBox(height: 16),
          IgnorePointer(
            ignoring: !_isReminderEnabled,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isReminderEnabled ? 1.0 : 0.4,
              child: Row(
                children: [
                  _buildQuickPickButton('Tomorrow', true),
                  const SizedBox(width: 8),
                  _buildQuickPickButton('Next Week', false),
                  const SizedBox(width: 8),
                  _buildQuickPickButton('Custom', false, icon: Icons.calendar_today),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickPickButton(String label, bool isSelected, {IconData? icon}) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: surfaceContainerLowest,
          border: Border.all(color: isSelected ? primary.withOpacity(0.2) : outlineVariant.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? primary : onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(28),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [secondary, primary],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Save Item',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSideNav() {
    return Container(
      width: 80,
      color: surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text('D', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary)),
          const SizedBox(height: 32),
          IconButton(icon: const Icon(Icons.inventory_2, color: onSurfaceVariant), onPressed: () {}),
          const SizedBox(height: 24),
          IconButton(icon: const Icon(Icons.star, color: onSurfaceVariant), onPressed: () {}),
          const SizedBox(height: 24),
          Container(
            decoration: BoxDecoration(color: const Color(0xFFEEDBFF), borderRadius: BorderRadius.circular(24)),
            child: IconButton(icon: const Icon(Icons.add, color: primary), onPressed: () {}),
          ),
          const SizedBox(height: 24),
          IconButton(icon: const Icon(Icons.cloud_done, color: onSurfaceVariant), onPressed: () {}),
          const Spacer(),
          IconButton(icon: const Icon(Icons.settings, color: onSurfaceVariant), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildMobileBottomNav() {
    return Container(
      padding: const EdgeInsets.only(bottom: 32, top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.9),
        border: Border(top: BorderSide(color: outlineVariant.withOpacity(0.3))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          const Icon(Icons.home, color: Colors.grey),
          const Icon(Icons.search, color: Colors.grey),
          const Icon(Icons.add_circle, color: primary, size: 40),
          const Icon(Icons.folder_copy, color: Colors.grey),
          const Icon(Icons.person, color: Colors.grey),
        ],
      ),
    );
  }
}