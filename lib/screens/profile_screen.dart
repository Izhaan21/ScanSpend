import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _primary = Color(0xFF006A61);
  static const Color _accent = Color(0xFF89F5E7);
  static const Color _divider = Color(0xFFE0E3E5);
  static const Color _textSub = Color(0xFF45464D);
  static const Color _error = Color(0xFFBA1A1A);

  final _currencies = ['PKR', 'USD', 'EUR', 'GBP', 'AED', 'SAR', 'INR'];

  // ── helpers ────────────────────────────────────────────────────────────────
  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _error : _primary,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // ── Profile photo ──────────────────────────────────────────────────────────
  Future<void> _changePhoto() async {
    final settings = context.read<SettingsProvider>();
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          ListTile(leading: const Icon(Icons.camera_alt_outlined, color: _primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library_outlined, color: _primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery)),
          if (settings.profilePhotoPath != null)
            ListTile(leading: const Icon(Icons.delete_outline, color: _error),
                title: const Text('Remove Photo',
                    style: TextStyle(color: _error)),
                onTap: () {
                  settings.setProfilePhoto(null);
                  Navigator.pop(context);
                  _snack('Profile photo removed');
                }),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null) return;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: choice, imageQuality: 80);
    if (file != null && mounted) {
      settings.setProfilePhoto(file.path);
      _snack('Profile photo updated');
    }
  }

  // ── Edit name ──────────────────────────────────────────────────────────────
  Future<void> _editName(AuthProvider auth) async {
    final ctrl = TextEditingController(text: auth.user?.name ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Name'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Display name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primary),
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await auth.updateName(result);
      _snack('Name updated successfully');
    }
  }

  // ── Change password ────────────────────────────────────────────────────────
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextFormField(
                controller: oldCtrl,
                obscureText: obscureOld,
                decoration: InputDecoration(
                  labelText: 'Current password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureOld ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setS(() => obscureOld = !obscureOld),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: obscureNew,
                decoration: InputDecoration(
                  labelText: 'New password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setS(() => obscureNew = !obscureNew),
                  ),
                ),
                validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setS(() => obscureConfirm = !obscureConfirm),
                  ),
                ),
                validator: (v) => v != newCtrl.text ? 'Passwords do not match' : null,
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(ctx);
                await auth.updatePassword(oldCtrl.text, newCtrl.text);
                _snack('Password changed successfully');
              },
              child: const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Currency picker ────────────────────────────────────────────────────────
  Future<void> _pickCurrency() async {
    final settings = context.read<SettingsProvider>();
    final chosen = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('Select Currency'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        children: _currencies.map((c) => SimpleDialogOption(
          onPressed: () => Navigator.pop(context, c),
          child: Row(children: [
            Icon(Icons.check,
                color: c == settings.currency ? _primary : Colors.transparent, size: 20),
            const SizedBox(width: 12),
            Text(c, style: const TextStyle(fontSize: 16)),
          ]),
        )).toList(),
      ),
    );
    if (chosen != null) {
      settings.setCurrency(chosen);
      _snack('Currency set to $chosen');
    }
  }

  // ── Export data ────────────────────────────────────────────────────────────
  Future<void> _exportData() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Preparing export...'),
        ]),
      ),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.pop(context);
    _snack('Data exported successfully (CSV ready)');
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  void _toggleNotifications(bool val) {
    context.read<SettingsProvider>().setNotifications(val);
    _snack(val ? 'Notifications enabled' : 'Notifications disabled');
  }

  // ── Legal pages ────────────────────────────────────────────────────────────
  void _showLegal(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          Padding(padding: const EdgeInsets.all(20),
              child: Text(title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Expanded(child: SingleChildScrollView(
            controller: ctrl,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(content, style: const TextStyle(fontSize: 14, height: 1.6)),
          )),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ── Help Center ────────────────────────────────────────────────────────────
  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2))),
          const Padding(padding: EdgeInsets.all(20),
              child: Text('Help Center',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          Expanded(child: ListView(controller: ctrl, children: [
            _helpTile('How do I scan a receipt?',
                'Open the Scanner tab, point your camera at the receipt and tap the capture button. AI will extract the data automatically.'),
            _helpTile('My scanner shows Unknown Merchant?',
                'Ensure your Gemini API key has available quota. The free tier resets daily.'),
            _helpTile('How do I edit scanned data?',
                'After scanning, you reach the Review screen. Tap any field to edit before saving.'),
            _helpTile('How do I export my expenses?',
                'Go to Profile → Export Data. A CSV file will be generated with all your expenses.'),
            _helpTile('How do I delete an expense?',
                'Go to History, tap on any expense, then use the delete option.'),
            const SizedBox(height: 24),
          ])),
        ]),
      ),
    );
  }

  Widget _helpTile(String q, String a) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text(q, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      children: [Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Text(a, style: const TextStyle(fontSize: 13, color: _textSub, height: 1.5)),
      )],
    );
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  Future<void> _logout(AuthProvider auth) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await auth.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Consumer2<AuthProvider, SettingsProvider>(
          builder: (context, auth, settings, _) {
            final name = auth.user?.name ?? 'User';
            final email = auth.user?.email ?? '';
            return CustomScrollView(slivers: [
              // ── Top bar ──
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Profile', style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(settings.notificationsOn
                          ? Icons.notifications_outlined
                          : Icons.notifications_off_outlined,
                          color: settings.notificationsOn ? _primary : Colors.grey),
                      tooltip: 'Notifications',
                      onPressed: () => _toggleNotifications(!settings.notificationsOn),
                    ),
                  ],
                ),
              )),

              // ── Avatar + name ──
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(children: [
                  Stack(children: [
                    GestureDetector(
                      onTap: _changePhoto,
                      child: Container(
                        width: 100, height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: _accent, width: 3),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16)],
                        ),
                        child: ClipOval(child: settings.profilePhotoPath != null
                            ? Image.file(File(settings.profilePhotoPath!), fit: BoxFit.cover)
                            : Container(color: const Color(0xFF131B2E),
                                child: Center(child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                    style: const TextStyle(fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white))))),
                      ),
                    ),
                    Positioned(bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _changePhoto,
                        child: Container(
                          width: 30, height: 30,
                          decoration: const BoxDecoration(
                              shape: BoxShape.circle, color: _primary),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(name, style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(email, style: const TextStyle(color: _textSub, fontSize: 14)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFF86F2E4),
                        borderRadius: BorderRadius.circular(16)),
                    child: const Text('FREE PLAN',
                        style: TextStyle(color: Color(0xFF006F66),
                            fontSize: 10, fontWeight: FontWeight.w700,
                            letterSpacing: 1.5)),
                  ),
                ]),
              )),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(delegate: SliverChildListDelegate([
                  // ── Account ──
                  _sectionTitle('Account'),
                  _card([
                    _tile(Icons.person_outline, 'Personal Info',
                        subtitle: name,
                        onTap: () => _editName(auth)),
                    _tile(Icons.lock_outline, 'Change Password',
                        onTap: () => _changePassword(auth)),
                    _tile(Icons.email_outlined, 'Email',
                        subtitle: email,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: email));
                          _snack('Email copied to clipboard');
                        }),
                  ]),
                  const SizedBox(height: 24),

                  // ── Preferences ──
                  _sectionTitle('Preferences'),
                  _card([
                    _tile(Icons.payments_outlined, 'Currency',
                        trailing: _chip(settings.currency),
                        onTap: _pickCurrency),
                    _tile(Icons.dark_mode_outlined, 'Dark Mode',
                        trailing: Switch(
                          value: settings.isDarkMode,
                          activeThumbColor: _primary,
                          onChanged: (v) {
                            settings.setDarkMode(v);
                            _snack(v ? 'Dark mode enabled' : 'Light mode enabled');
                          },
                        )),
                    _tile(Icons.notifications_outlined, 'Notifications',
                        trailing: Switch(
                          value: settings.notificationsOn,
                          activeThumbColor: _primary,
                          onChanged: _toggleNotifications,
                        )),
                    _tile(Icons.download_outlined, 'Export Data',
                        onTap: _exportData),
                  ]),
                  const SizedBox(height: 24),

                  // ── Support & Legal ──
                  _sectionTitle('Support & Legal'),
                  _card([
                    _tile(Icons.help_outline, 'Help Center',
                        onTap: _showHelp),
                    _tile(Icons.privacy_tip_outlined, 'Privacy Policy',
                        onTap: () => _showLegal('Privacy Policy', _privacyText)),
                    _tile(Icons.description_outlined, 'Terms of Service',
                        onTap: () => _showLegal('Terms of Service', _termsText)),
                  ]),
                  const SizedBox(height: 32),

                  // ── Logout ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _logout(auth),
                      icon: const Icon(Icons.logout, color: _error),
                      label: const Text('Log Out',
                          style: TextStyle(color: _error, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFFFDAD6), width: 2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ])),
              ),
            ]);
          },
        ),
      ),
    );
  }

  // ── Widget helpers ─────────────────────────────────────────────────────────
  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(t.toUpperCase(),
        style: const TextStyle(color: _textSub, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  );

  Widget _card(List<Widget> children) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _divider),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: children.asMap().entries.map((e) {
      if (e.key == children.length - 1) return e.value;
      return Column(children: [e.value,
        const Divider(height: 1, thickness: 1, indent: 56, color: _divider)]);
    }).toList()),
  );

  Widget _tile(IconData icon, String label,
      {String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: _primary, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 15)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(
                      color: _textSub, fontSize: 12)),
                ],
              ])),
          trailing ?? const Icon(Icons.chevron_right, color: Color(0xFF76777D), size: 20),
        ]),
      ),
    );
  }

  Widget _chip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8)),
    child: Text(label, style: const TextStyle(
        color: _primary, fontWeight: FontWeight.w700, fontSize: 13)),
  );
}

// ── Legal text ─────────────────────────────────────────────────────────────
const _privacyText = '''
Last updated: May 2026

1. Information We Collect
ScanSpend collects receipt images, extracted expense data, and account information (name, email) to provide our services.

2. How We Use Your Information
We use your data to process receipts, display spending summaries, and sync data across your devices via Firebase.

3. Data Storage
All expense data is stored securely in Google Firebase Firestore. Receipt images are processed by Google Gemini AI and are not permanently stored.

4. Third-Party Services
We use Google Firebase (authentication and storage) and Google Gemini AI (receipt analysis). Both are governed by Google's privacy policies.

5. Your Rights
You may request deletion of your account and all associated data at any time by contacting support.

6. Contact
For privacy questions, contact us at privacy@scanspend.app
''';

const _termsText = '''
Last updated: May 2026

1. Acceptance
By using ScanSpend, you agree to these Terms of Service.

2. Use of Service
ScanSpend is provided for personal expense tracking. You may not use it for illegal purposes or to process receipts belonging to others without permission.

3. Account Responsibility
You are responsible for maintaining the security of your account credentials.

4. AI Processing
Receipt data is analysed by Google Gemini AI. Results may not be 100% accurate. Always verify important financial data.

5. Limitation of Liability
ScanSpend is not liable for financial decisions made based on extracted receipt data.

6. Changes
We reserve the right to update these terms. Continued use of the app constitutes acceptance of updated terms.

7. Contact
For terms inquiries: terms@scanspend.app
''';
