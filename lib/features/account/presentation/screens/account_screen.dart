import 'package:corevia_mobile/core/providers/notifiers.dart';
import 'package:corevia_mobile/core/routes/route_persistence.dart';
import 'package:corevia_mobile/core/theme/colors.dart';
import 'package:corevia_mobile/features/ai_chat/data/rag_chat_storage.dart';
import 'package:corevia_mobile/l10n/app_localizations.dart';
import 'package:corevia_mobile/networking/api_service.dart';
import 'package:corevia_mobile/networking/routes/user_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../widgets/initials_avatar.dart';
import '../../../../widgets/pro_member.dart';
import '../providers/user_provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool isNotificationsEnabled = true;
  Map<String, dynamic>? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final res = await ApiService.authGet(UserRoutes.me());
      if (mounted) {
        setState(() {
          _user = res['user'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    const storage = FlutterSecureStorage();
    await storage.delete(key: 'auth_token');
    await RagChatStorage().clearAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(lastRouteStorageKey);

    if (!mounted) return;
    context.read<UserProvider>().clear();
    final authNotifier = Provider.of<AuthNotifier>(context, listen: false);
    authNotifier.value = false;
    context.go('/login');

    ApiService.signOut().ignore();
  }

  String get _name => _user?['name'] as String? ?? '—';
  String get _email => _user?['email'] as String? ?? '—';
  String? get _imageUrl => _user?['image'] as String?;

  Map<String, dynamic>? get _patientProfile =>
      _user?['patientProfile'] as Map<String, dynamic>?;

  String get _phone => _patientProfile?['phone'] as String? ?? '—';
  String get _dateOfBirth => _patientProfile?['dateOfBirth'] as String? ?? '—';

  String _languageLabel(BuildContext context, Locale? locale) {
    final languageCode = locale?.languageCode ??
        Localizations.localeOf(context).languageCode;
    return languageCode == 'en' ? context.l10n.english : context.l10n.french;
  }

  Future<void> _showLanguageSelector() async {
    final localeNotifier = context.read<LocaleNotifier>();
    final currentLocale = localeNotifier.value;
    final selectedLanguageCode =
        currentLocale?.languageCode ?? Localizations.localeOf(context).languageCode;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final mediaQuery = MediaQuery.of(sheetContext);
        final bottomInset = mediaQuery.padding.bottom + kBottomNavigationBarHeight;
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: Text(context.l10n.language),
                ),
                RadioListTile<String>(
                  value: 'fr',
                  groupValue: selectedLanguageCode,
                  title: Text(context.l10n.french),
                  onChanged: (_) async {
                    await localeNotifier.updateLocale(const Locale('fr'));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                RadioListTile<String>(
                  value: 'en',
                  groupValue: selectedLanguageCode,
                  title: Text(context.l10n.english),
                  onChanged: (_) async {
                    await localeNotifier.updateLocale(const Locale('en'));
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildTopHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 30),
                          _buildProfileCard(),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: context.l10n.accountInformation,
                            children: [
                              _buildInfoTile(
                                icon: Icons.email_outlined,
                                title: context.l10n.email,
                                value: _email,
                              ),
                              _buildInfoTile(
                                icon: Icons.phone_outlined,
                                title: context.l10n.phone,
                                value: _phone,
                              ),
                              _buildInfoTile(
                                icon: Icons.cake_outlined,
                                title: context.l10n.dateOfBirth,
                                value: _dateOfBirth,
                              ),
                              _buildActionTile(
                                icon: LucideIcons.fileText,
                                title: context.l10n.documents,
                                onTap: () => context.push('/documents'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: context.l10n.settings,
                            children: [
                              _buildActionTile(
                                icon: Icons.notifications_outlined,
                                title: context.l10n.notifications,
                                trailing: Switch(
                                  value: isNotificationsEnabled,
                                  onChanged: (value) =>
                                      setState(() => isNotificationsEnabled = value),
                                  activeThumbColor: AppColors.green,
                                ),
                              ),
                              _buildActionTile(
                                icon: Icons.lock_outline,
                                title: context.l10n.privacySecurity,
                              ),
                              _buildActionTile(
                                icon: Icons.language_outlined,
                                title: context.l10n.language,
                                subtitle: _languageLabel(
                                  context,
                                  context.watch<LocaleNotifier>().value,
                                ),
                                onTap: _showLanguageSelector,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildSection(
                            title: context.l10n.actions,
                            children: [
                              _buildActionTile(
                                icon: Icons.help_outline,
                                title: context.l10n.helpSupport,
                              ),
                              _buildActionTile(
                                icon: Icons.info_outline,
                                title: context.l10n.about,
                              ),
                              _buildActionTile(
                                icon: Icons.logout,
                                title: context.l10n.logout,
                                iconColor: Colors.red,
                                titleColor: Colors.red,
                                onTap: () => _logout(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            context.l10n.myAccount,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              InitialsAvatar(
                name: _name,
                imageUrl: _imageUrl,
                size: 100,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => context.push('/edit-account'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _name,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 8),
          const ProMemberBadge(),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D1D1F),
                letterSpacing: -0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? iconColor,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    final enabled = onTap != null || trailing != null;
    final effectiveIconColor = enabled
        ? (iconColor ?? AppColors.green)
        : Colors.grey.shade400;
    final effectiveTitleColor = enabled
        ? (titleColor ?? const Color(0xFF1D1D1F))
        : Colors.grey.shade500;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: effectiveIconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: effectiveTitleColor,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing
          else if (enabled)
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 24),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      );
    }
    return content;
  }
}
