import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app_settings.dart';
import 'update_checker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _checkingUpdate = false;
  UpdateInfo? _updateResult;
  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = info.version;
        _buildNumber = info.buildNumber;
      });
    }
  }

  Future<void> _checkForUpdate() async {
    setState(() {
      _checkingUpdate = true;
      _updateResult = null;
    });
    final result = await UpdateChecker.check();
    if (mounted) {
      setState(() {
        _checkingUpdate = false;
        _updateResult = result;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    final bg = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final dividerColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final textPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: borderColor),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        children: [
          // ─── Appearance ────────────────────────────────────────────────
          _sectionHeader('Appearance', textSecondary),
          const SizedBox(height: 8),
          _card(
            cardBg: cardBg,
            borderColor: borderColor,
            child: _toggleTile(
              icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: isDark ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
              title: 'Dark Mode',
              subtitle: isDark ? 'Switch to light theme' : 'Switch to dark theme',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              value: isDark,
              onChanged: (v) => settings.setDarkMode(v),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Notifications ─────────────────────────────────────────────
          _sectionHeader('Notifications', textSecondary),
          const SizedBox(height: 8),
          _card(
            cardBg: cardBg,
            borderColor: borderColor,
            child: Column(
              children: [
                _toggleTile(
                  icon: Icons.notifications_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Payment Reminders',
                  subtitle: 'Get notified before installments are due',
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  value: settings.notificationsEnabled,
                  onChanged: (v) => settings.setNotificationsEnabled(v),
                ),
                if (settings.notificationsEnabled) ...[
                  Divider(height: 1, color: dividerColor),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.schedule_rounded, color: Color(0xFF3B82F6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Notify me before due date',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
                              ),
                              Text(
                                'Days before payment to send reminder',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: Row(
                      children: [1, 2, 3].map((days) {
                        final selected = settings.notificationLeadDays == days;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('$days day${days > 1 ? 's' : ''}'),
                            selected: selected,
                            onSelected: (_) => settings.setNotificationLeadDays(days),
                            selectedColor: const Color(0xFF3B82F6),
                            backgroundColor: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : textSecondary,
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: selected ? const Color(0xFF3B82F6) : borderColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── Updates ───────────────────────────────────────────────────
          _sectionHeader('Updates', textSecondary),
          const SizedBox(height: 8),
          _card(
            cardBg: cardBg,
            borderColor: borderColor,
            child: Column(
              children: [
                InkWell(
                  onTap: _checkingUpdate ? null : _checkForUpdate,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.system_update_alt_rounded, color: Color(0xFF8B5CF6), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Check for Updates',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                              Text(
                                _appVersion.isNotEmpty ? 'Current version: v$_appVersion' : 'Tap to check',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        if (_checkingUpdate)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B5CF6)),
                          )
                        else
                          Icon(Icons.refresh_rounded, color: textSecondary, size: 20),
                      ],
                    ),
                  ),
                ),
                if (_updateResult != null) ...[
                  Divider(height: 1, color: dividerColor),
                  _buildUpdateResultBanner(_updateResult!, textPrimary, textSecondary),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ─── About ─────────────────────────────────────────────────────
          _sectionHeader('About', textSecondary),
          const SizedBox(height: 8),
          _card(
            cardBg: cardBg,
            borderColor: borderColor,
            child: Column(
              children: [
                // App name + version badge
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Installment Hub',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          _appVersion.isNotEmpty ? 'v$_appVersion (build $_buildNumber)' : 'v1.2.0',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF3B82F6),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your smart BNPL companion for Koko, PayZy & MintPay in Sri Lanka.',
                        style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: dividerColor),
                _infoTile(
                  icon: Icons.person_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Developer',
                  trailing: Text('DMStyles', style: TextStyle(fontSize: 13, color: textSecondary)),
                  textPrimary: textPrimary,
                ),
                Divider(height: 1, color: dividerColor, indent: 54),
                _infoTile(
                  icon: Icons.code_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Source Code',
                  trailing: Icon(Icons.open_in_new_rounded, color: textSecondary, size: 16),
                  textPrimary: textPrimary,
                  onTap: () => _launchUrl('https://github.com/DMStyles/installment-calculator'),
                ),
                Divider(height: 1, color: dividerColor, indent: 54),
                _infoTile(
                  icon: Icons.public_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Web Version',
                  trailing: Icon(Icons.open_in_new_rounded, color: textSecondary, size: 16),
                  textPrimary: textPrimary,
                  onTap: () => _launchUrl('https://dmstyles.github.io/installment-calculator/'),
                ),
                Divider(height: 1, color: dividerColor, indent: 54),
                _infoTile(
                  icon: Icons.star_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Releases & Changelog',
                  trailing: Icon(Icons.open_in_new_rounded, color: textSecondary, size: 16),
                  textPrimary: textPrimary,
                  onTap: () => _launchUrl('https://github.com/DMStyles/installment-calculator/releases'),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'Made with ❤️ in Sri Lanka',
              style: TextStyle(fontSize: 12, color: textSecondary),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildUpdateResultBanner(UpdateInfo info, Color textPrimary, Color textSecondary) {
    if (info.checkFailed) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.wifi_off_rounded, color: Color(0xFF9CA3AF), size: 18),
            const SizedBox(width: 8),
            Text('Could not check for updates. Check your internet connection.',
                style: TextStyle(fontSize: 12, color: textSecondary)),
          ],
        ),
      );
    }
    if (!info.hasUpdate) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Text('You\'re on the latest version (v${info.currentVersion})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF10B981))),
          ],
        ),
      );
    }
    // Update available
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const Icon(Icons.new_releases_rounded, color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('v${info.latestVersion} is available!',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                Text('You have v${info.currentVersion}',
                    style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _launchUrl(info.releaseUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Download', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 1.2),
      ),
    );
  }

  Widget _card({required Widget child, required Color cardBg, required Color borderColor}) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: child,
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Color textPrimary,
    required Color textSecondary,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: textSecondary)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget trailing,
    required Color textPrimary,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
