import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../services/location_currency_service.dart';
import '../widgets/premium_background.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Minimalist Premium Dark Palette
  static const Color _bg         = Color(0xFF090E17);
  static const Color _cardBg     = Color(0xFF141415);
  static const Color _primary    = Color(0xFF2563EB);
  static const Color _secondary  = Color(0xFF06B6D4);
  static const Color _text       = Color(0xFFFFFFFF);
  static const Color _textMuted  = Color(0xFF94A3B8);
  static const Color _border     = Colors.transparent;
  static const Color _error      = Color(0xFFEF4444);

  final _currencies = [
    'USD', 'EUR', 'GBP', 'INR', 'PKR',
    'AED', 'SAR', 'CAD', 'AUD', 'JPY',
    'CNY', 'SGD', 'CHF',
  ];

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: error ? _error : const Color(0xFF1E293B),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ));
  }

  Future<void> _changePhoto() async {
    final settings = context.read<SettingsProvider>();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            leading: const Icon(Icons.camera_alt_outlined, color: _text),
            title: const Text('Take a photo', style: TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 16)),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
            leading: const Icon(Icons.photo_library_outlined, color: _text),
            title: const Text('Choose from library', style: TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 16)),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          if (settings.profilePhotoPath != null)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              leading: const Icon(Icons.delete_outline_rounded, color: _error),
              title: const Text('Remove photo', style: TextStyle(color: _error, fontWeight: FontWeight.w500, fontSize: 16)),
              onTap: () {
                settings.setProfilePhoto(null);
                Navigator.pop(context);
                _snack('Profile photo removed.');
              },
            ),
          const SizedBox(height: 24),
        ]),
      ),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: choice, imageQuality: 80);
    if (file != null && mounted) {
      settings.setProfilePhoto(file.path);
      _snack('Profile photo updated.');
    }
  }

  Future<void> _editName(AuthProvider auth) async {
    final ctrl = TextEditingController(text: auth.user?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Edit Name', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: _text, fontWeight: FontWeight.w500),
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            labelStyle: TextStyle(color: _textMuted),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: _border)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _primary)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textMuted, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await auth.updateName(result);
      _snack('Name updated.');
    }
  }

  Future<void> _changePassword(AuthProvider auth) async {
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureOld = true, obscureNew = true, obscureConfirm = true;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF111A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Update Password', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: oldCtrl,
                  obscureText: obscureOld,
                  style: const TextStyle(color: _text, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _border)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primary)),
                    suffixIcon: IconButton(
                      icon: Icon(obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _textMuted, size: 20),
                      onPressed: () => setS(() => obscureOld = !obscureOld),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: newCtrl,
                  obscureText: obscureNew,
                  style: const TextStyle(color: _text, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'New password',
                    labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _border)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primary)),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _textMuted, size: 20),
                      onPressed: () => setS(() => obscureNew = !obscureNew),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: confirmCtrl,
                  obscureText: obscureConfirm,
                  style: const TextStyle(color: _text, fontSize: 15),
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    labelStyle: const TextStyle(color: _textMuted, fontSize: 14),
                    enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _border)),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: _primary)),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _textMuted, size: 20),
                      onPressed: () => setS(() => obscureConfirm = !obscureConfirm),
                    ),
                  ),
                  validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: _textMuted, fontWeight: FontWeight.w500)),
            ),
            TextButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                try {
                  await auth.updatePassword(oldCtrl.text, newCtrl.text);
                  if (mounted) _snack('Password updated successfully.');
                } catch (e) {
                  if (mounted) {
                    final msg = e.toString().replaceAll('Exception: ', '');
                    _snack('Error: $msg', error: true);
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: _primary, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCurrency() async {
    final settings = context.read<SettingsProvider>();
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                const Text('Select Currency', style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded, color: _textMuted), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),
          Expanded(
            child: ListView(
              controller: ctrl,
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.my_location_rounded, color: _primary, size: 20),
                  ),
                  title: const Text('Auto-detect', style: TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 16)),
                  subtitle: const Text('Uses your location', style: TextStyle(color: _textMuted, fontSize: 14)),
                  onTap: () => Navigator.pop(context, '__auto__'),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Currencies', style: TextStyle(color: _textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                ),
                ..._currencies.map((c) {
                  final symbol = LocationCurrencyService.currencySymbols[c] ?? c;
                  final selected = c == settings.currency;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                    title: Text('$symbol  $c', style: TextStyle(color: _text, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, fontSize: 16)),
                    trailing: selected ? const Icon(Icons.check_circle_rounded, color: _primary) : null,
                    onTap: () => Navigator.pop(context, c),
                  );
                }),
              ],
            ),
          ),
        ]),
      ),
    );
    if (chosen == null) return;
    if (chosen == '__auto__') {
      _snack('Detecting location...');
      await settings.resetCurrencyToAutoDetect();
      if (mounted) _snack('Currency set to: ${settings.currency}');
    } else {
      await settings.setCurrency(chosen);
      _snack('Currency set to $chosen');
    }
  }

  Future<void> _exportData() async {
    _snack('Export feature coming soon.', error: false);
  }



  void _showLegal(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close_rounded, color: _textMuted), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.all(24),
            child: Text(content, style: const TextStyle(color: _textMuted, fontSize: 15, height: 1.6)),
          )),
        ]),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 48, height: 4, decoration: BoxDecoration(color: const Color(0xFF334155), borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Help & FAQ', style: TextStyle(color: _text, fontSize: 20, fontWeight: FontWeight.w600)),
                IconButton(icon: const Icon(Icons.close_rounded, color: _textMuted), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(color: _border, height: 1),
          Expanded(child: ListView(controller: ctrl, padding: const EdgeInsets.symmetric(vertical: 8), children: [
            _helpTile('How do I scan a receipt?', 'Go to the Scan tab, point your camera at a receipt and take a photo. Our AI will handle the rest.'),
            _helpTile('Can I edit receipt details?', 'Yes, after a scan is processed you will be taken to a review screen where you can modify any details before saving.'),
            _helpTile('How do I export my data?', 'Data export functionality is currently being built and will be available in a future update.'),
            _helpTile('How do I delete a receipt?', 'In the History tab, simply swipe left on any transaction, or tap it and select delete from the details view.'),
            const SizedBox(height: 32),
          ])),
        ]),
      ),
    );
  }

  Widget _helpTile(String q, String a) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        iconColor: _text,
        collapsedIconColor: _textMuted,
        title: Text(q, style: const TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 16)),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Text(a, style: const TextStyle(color: _textMuted, fontSize: 15, height: 1.5)),
          )
        ],
      ),
    );
  }

  Future<void> _logout(AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF111A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Log out', style: TextStyle(color: _text, fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: _textMuted, fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted, fontWeight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: _error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await auth.logout();
      } catch (e) {
        if (mounted) _snack('Error logging out.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
        child: Consumer2<AuthProvider, SettingsProvider>(
          builder: (context, auth, settings, _) {
            final name = auth.user?.name ?? 'User';
            final email = auth.user?.email ?? '';

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Profile', style: TextStyle(color: _text, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.5)),

                      ],
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Column(children: [
                      Stack(children: [
                        GestureDetector(
                          onTap: _changePhoto,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _cardBg,
                              border: Border.all(color: _border, width: 2),
                            ),
                            child: ClipOval(child: settings.profilePhotoPath != null
                                ? Image.file(File(settings.profilePhotoPath!), fit: BoxFit.cover)
                                : Center(child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: _textMuted)))),
                          ),
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: _changePhoto,
                            child: Container(
                              width: 32, height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle, color: _primary,
                                border: Border.all(color: _bg, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 20),
                      Text(name, style: const TextStyle(color: _text, fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.2)),
                      const SizedBox(height: 4),
                      Text(email, style: const TextStyle(color: _textMuted, fontSize: 15, fontWeight: FontWeight.w400)),
                    ]),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(delegate: SliverChildListDelegate([
                    _sectionTitle('Account'),
                    _card([
                      _tile(Icons.person_outline_rounded, 'Name', subtitle: name, onTap: () => _editName(auth)),
                      _tile(Icons.lock_outline_rounded, 'Password', onTap: () => _changePassword(auth)),
                    ]),
                    const SizedBox(height: 24),

                    _sectionTitle('Preferences'),
                    _card([
                      _tile(Icons.payments_outlined, 'Currency', trailing: Text(settings.currency, style: const TextStyle(color: _textMuted, fontSize: 15)), onTap: _pickCurrency),

                    ]),
                    const SizedBox(height: 24),

                    _sectionTitle('About'),
                    _card([
                      _tile(Icons.help_outline_rounded, 'Help & FAQ', onTap: _showHelp),
                      _tile(Icons.privacy_tip_outlined, 'Privacy Policy', onTap: () => _showLegal('Privacy Policy', _privacyText)),
                      _tile(Icons.description_outlined, 'Terms of Service', onTap: () => _showLegal('Terms of Service', _termsText)),
                    ]),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _logout(auth),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        ),
                        child: const Text('Log out', style: TextStyle(color: _error, fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ])),
                ),
              ],
            );
          },
        ),
      ),
    ));
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(left: 8, bottom: 12),
    child: Text(t, style: const TextStyle(color: _textMuted, fontSize: 14, fontWeight: FontWeight.w500)),
  );

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: _border),
    ),
    child: Column(children: children.asMap().entries.map((e) {
      if (e.key == children.length - 1) return e.value;
      return Column(children: [
        e.value,
        const Divider(height: 1, thickness: 1, indent: 64, endIndent: 24, color: _border),
      ]);
    }).toList()),
  );

  Widget _tile(IconData icon, String label, {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: _primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _text, fontWeight: FontWeight.w500, fontSize: 16)),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: _textMuted, fontSize: 14, fontWeight: FontWeight.w400)),
                ],
              ])),
          trailing ?? const Icon(Icons.chevron_right_rounded, color: _textMuted, size: 20),
        ]),
      ),
    );
  }
}

const _privacyText = '''
Last updated: May 2026

1. Information We Collect
ScanSpend collects receipt images, extracted expense data, and account information (name, email) to provide our services.

2. How We Use Your Information
We use your data to process receipts, display spending summaries, and sync data across your devices.

3. Data Storage
All expense data is stored securely in Google Firebase Firestore. Receipt images are processed securely and are not permanently stored.

4. Your Rights
You may request deletion of your account and all associated data at any time by contacting support.
''';

const _termsText = '''
Last updated: May 2026

1. Acceptance
By using ScanSpend, you agree to these Terms of Service.

2. Use of Service
ScanSpend is provided for personal expense tracking. You may not use it for illegal purposes.

3. Account Responsibility
You are responsible for maintaining the security of your account credentials.

4. AI Processing
Receipt data is analysed by AI. Results may not be 100% accurate. Always verify important financial data.
''';
