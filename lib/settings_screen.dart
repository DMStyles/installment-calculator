import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'app_settings.dart';
import 'app_theme.dart';
import 'update_checker.dart';
import 'widgets/pixel_card.dart';
import 'widgets/bounce_tap.dart';
import 'widgets/fade_in_item.dart';
import 'widgets/animated_section.dart';

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

    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          // ─── Appearance ────────────────────────────────────────────────
          FadeInItem(
            delay: const Duration(milliseconds: 0),
            child: _sectionHeader('Appearance', textSecondary),
          ),
          const SizedBox(height: 8),
          FadeInItem(
            delay: const Duration(milliseconds: 40),
            child: PixelCard(
              padding: EdgeInsets.zero,
              child: _toggleTile(
                icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                iconColor: isDark ? const Color(0xFF818CF8) : const Color(0xFFF59E0B),
                title: 'Dark Mode',
                subtitle: isDark ? 'Switch to light theme' : 'Switch to dark theme',
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                value: isDark,
                onChanged: (v) => settings.setDarkMode(v),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Notifications ─────────────────────────────────────────────
          FadeInItem(
            delay: const Duration(milliseconds: 80),
            child: _sectionHeader('Notifications', textSecondary),
          ),
          const SizedBox(height: 8),
          FadeInItem(
            delay: const Duration(milliseconds: 120),
            child: PixelCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _toggleTile(
                    icon: Icons.notifications_none_outlined,
                    iconColor: const Color(0xFF10B981),
                    title: 'Payment Reminders',
                    subtitle: 'Get notified before installments are due',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    value: settings.notificationsEnabled,
                    onChanged: (v) => settings.setNotificationsEnabled(v),
                  ),
                  AnimatedSection(
                    visible: settings.notificationsEnabled,
                    child: Column(
                      children: [
                        Divider(height: 1, color: AppTheme.border(context)),
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
                                child: const Icon(Icons.schedule_outlined, color: Color(0xFF3B82F6), size: 20),
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
                                  selectedColor: AppTheme.primary(context),
                                  backgroundColor: AppTheme.cardAlt(context),
                                  labelStyle: TextStyle(
                                    color: selected ? Colors.white : textSecondary,
                                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: selected ? AppTheme.primary(context) : AppTheme.border(context),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── Updates ───────────────────────────────────────────────────
          FadeInItem(
            delay: const Duration(milliseconds: 160),
            child: _sectionHeader('Updates', textSecondary),
          ),
          const SizedBox(height: 8),
          FadeInItem(
            delay: const Duration(milliseconds: 200),
            child: PixelCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  InkWell(
                    onTap: _checkingUpdate ? null : _checkForUpdate,
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
                            child: const Icon(Icons.system_update_alt_outlined, color: Color(0xFF8B5CF6), size: 20),
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
                  AnimatedSection(
                    visible: _updateResult != null,
                    child: Column(
                      children: [
                        if (_updateResult != null) ...[
                          Divider(height: 1, color: AppTheme.border(context)),
                          _buildUpdateResultBanner(_updateResult!, textPrimary, textSecondary),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── About ─────────────────────────────────────────────────────
          FadeInItem(
            delay: const Duration(milliseconds: 240),
            child: _sectionHeader('About', textSecondary),
          ),
          const SizedBox(height: 8),
          FadeInItem(
            delay: const Duration(milliseconds: 280),
            child: PixelCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary(context), const Color(0xFF8B5CF6)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.credit_card_outlined, color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Installment Hub',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary(context).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primary(context).withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _appVersion.isNotEmpty ? 'v$_appVersion (build $_buildNumber)' : 'v1.5.0',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.primary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your smart BNPL companion for Koko, PayZy & MintPay in Sri Lanka.',
                          style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: AppTheme.border(context)),
                  _infoTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: const Color(0xFFEC4899),
                    title: 'Developer',
                    trailing: Text('DMStyles', style: TextStyle(fontSize: 13, color: textSecondary)),
                    textPrimary: textPrimary,
                  ),
                  Divider(height: 1, color: AppTheme.border(context), indent: 54),
                  _infoTile(
                    icon: Icons.code_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Source Code',
                    trailing: Icon(Icons.open_in_new_rounded, color: textSecondary, size: 16),
                    textPrimary: textPrimary,
                    onTap: () => _launchUrl('https://github.com/DMStyles/installment-calculator'),
                  ),
                  Divider(height: 1, color: AppTheme.border(context), indent: 54),
                  _infoTile(
                    icon: Icons.public_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: 'Web Version',
                    trailing: Icon(Icons.open_in_new_rounded, color: textSecondary, size: 16),
                    textPrimary: textPrimary,
                    onTap: () => _launchUrl('https://dmstyles.github.io/installment-calculator/'),
                  ),
                  Divider(height: 1, color: AppTheme.border(context), indent: 54),
                  _infoTile(
                    icon: Icons.star_outline_rounded,
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
          ),

          const SizedBox(height: 32),
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
            Expanded(
              child: Text(
                'Could not check for updates. Check internet connection.',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ),
          ],
        ),
      );
    }
    if (!info.hasUpdate) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'You\'re on the latest version (v${info.currentVersion})',
                style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          const Icon(Icons.new_releases_outlined, color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('v${info.latestVersion} is available!',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                Text('You have v${info.currentVersion}', style: TextStyle(fontSize: 11, color: textSecondary)),
              ],
            ),
          ),
          BounceTap(
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
            activeTrackColor: AppTheme.primary(context),
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
