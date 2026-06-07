import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings.dart';
import 'app_theme.dart';
import 'provider_select_screen.dart';
import 'comparison_screen.dart';
import 'guide_screen.dart';
import 'tracker_screen.dart';
import 'update_checker.dart';
import 'page_transitions.dart';
import 'settings_screen.dart';
import 'widgets/bounce_tap.dart';
import 'widgets/fade_in_item.dart';
import 'widgets/animated_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _globalHistory = [];
  bool _isLoading = true;
  UpdateInfo? _updateBanner;
  bool _bannerDismissed = false;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ');
  final DateFormat _dateFormat = DateFormat('MMM d, h:mm a');

  @override
  void initState() {
    super.initState();
    _loadGlobalHistory();
    _silentUpdateCheck();
  }

  Future<void> _silentUpdateCheck() async {
    final info = await UpdateChecker.check();
    if (mounted && info.hasUpdate && !_bannerDismissed) {
      setState(() => _updateBanner = info);
    }
  }

  Future<void> _loadGlobalHistory() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> allItems = [];

    final providers = [
      {
        'key': 'kokoHistory',
        'provider': 'Koko',
        'color': const Color(0xFFFFB6C1),
        'icon': Icons.shopping_bag_outlined,
      },
      {
        'key': 'payzyHistory',
        'provider': 'PayZy',
        'color': const Color(0xFF00AEEF),
        'icon': Icons.bolt_outlined,
      },
      {
        'key': 'mintpayHistory',
        'provider': 'MintPay',
        'color': const Color(0xFF10B981),
        'icon': Icons.eco_outlined,
      },
    ];

    for (final p in providers) {
      final json = prefs.getString(p['key'] as String);
      if (json != null) {
        final List<dynamic> decoded = jsonDecode(json);
        for (var item in decoded) {
          allItems.add({
            ...Map<String, dynamic>.from(item),
            'provider': p['provider'],
            'color': p['color'],
            'icon': p['icon'],
          });
        }
      }
    }

    allItems.sort((a, b) {
      final timeA = DateTime.parse(a['timestamp'] ?? '');
      final timeB = DateTime.parse(b['timestamp'] ?? '');
      return timeB.compareTo(timeA);
    });

    setState(() {
      _globalHistory = allItems.take(3).toList();
      _isLoading = false;
    });
  }

  void _navigate(Widget screen) {
    Navigator.push(
      context,
      PixelPageRoute(builder: (_) => screen),
    ).then((_) => _loadGlobalHistory());
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AppSettings>();

    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ──────────────────────────────────────────────
                  FadeInItem(
                    delay: const Duration(milliseconds: 0),
                    child: _buildHeader(context),
                  ),

                  // ── Update Banner ────────────────────────────────────────
                  AnimatedSection(
                    visible: _updateBanner != null && !_bannerDismissed,
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        if (_updateBanner != null)
                          _buildUpdateBanner(_updateBanner!),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Dashboard Grid ───────────────────────────────────────
                  FadeInItem(
                    delay: const Duration(milliseconds: 80),
                    child: _buildDashboardGrid(context),
                  ),

                  const SizedBox(height: 32),

                  // ── Recent Calculations ──────────────────────────────────
                  FadeInItem(
                    delay: const Duration(milliseconds: 160),
                    child: _buildRecentHeader(context),
                  ),
                  const SizedBox(height: 12),
                  _buildRecentList(context),

                  const SizedBox(height: 24),

                  // ── Surcharge Warning ────────────────────────────────────
                  FadeInItem(
                    delay: const Duration(milliseconds: 240),
                    child: _buildSurchargeWarning(context),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Installment Hub',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan your BNPL purchases smartly.',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ],
        ),
        BounceTap(
          onTap: () => Navigator.push(
            context,
            PixelPageRoute(builder: (_) => const SettingsScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardAlt(context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border(context)),
            ),
            child: Icon(
              Icons.settings_outlined,
              color: AppTheme.textSecondary(context),
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Update Banner ────────────────────────────────────────────────────────
  Widget _buildUpdateBanner(UpdateInfo info) {
    final primary = AppTheme.primary(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(color: primary.withValues(alpha: 0.30), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.new_releases_rounded, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v${info.latestVersion} is available!',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primary,
                  ),
                ),
                Text(
                  'Tap to download the latest update.',
                  style: TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          BounceTap(
            onTap: () => Navigator.push(
              context,
              PixelPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusPill),
              ),
              child: const Text(
                'Update',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _bannerDismissed = true),
            child: Icon(Icons.close_rounded,
                color: AppTheme.textSecondary(context), size: 18),
          ),
        ],
      ),
    );
  }

  // ─── Dashboard Grid ───────────────────────────────────────────────────────
  Widget _buildDashboardGrid(BuildContext context) {
    return Column(
      children: [
        _dashCard(
          context: context,
          title: 'BNPL Calculators',
          subtitle: 'Koko, PayZy & MintPay fee calculators',
          icon: Icons.calculate_outlined,
          color: AppTheme.primary(context),
          onTap: () => _navigate(const ProviderSelectScreen()),
          delay: const Duration(milliseconds: 100),
        ),
        const SizedBox(height: 12),
        _dashCard(
          context: context,
          title: 'Installment Manager',
          subtitle: 'Track payments & get due-date reminders',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF10B981),
          onTap: () => _navigate(const TrackerScreen()),
          delay: const Duration(milliseconds: 160),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _miniDashCard(
                context: context,
                title: 'Compare',
                icon: Icons.compare_arrows_rounded,
                color: const Color(0xFF818CF8),
                onTap: () => _navigate(const ComparisonScreen()),
                delay: const Duration(milliseconds: 220),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniDashCard(
                context: context,
                title: 'Guides',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFF34D399),
                onTap: () => Navigator.push(
                  context,
                  PixelPageRoute(builder: (_) => const GuideScreen()),
                ),
                delay: const Duration(milliseconds: 260),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dashCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Duration delay,
  }) {
    return FadeInItem(
      delay: delay,
      child: BounceTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: AppTheme.cardDecoration(context, accentBorder: color),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppTheme.iconBg(context, color),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textHint(context),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniDashCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required Duration delay,
  }) {
    return FadeInItem(
      delay: delay,
      child: BounceTap(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: AppTheme.cardDecoration(context, accentBorder: color),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.iconBg(context, color),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Open',
                    style: TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary(context)),
                  ),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 13),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Recent Calculations ──────────────────────────────────────────────────
  Widget _buildRecentHeader(BuildContext context) {
    return Text(
      'Recent Calculations',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary(context),
      ),
    );
  }

  Widget _buildRecentList(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppTheme.primary(context),
          ),
        ),
      );
    }

    if (_globalHistory.isEmpty) {
      return FadeInItem(
        delay: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
          decoration: AppTheme.cardDecoration(context),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off_rounded,
                  color: AppTheme.textHint(context), size: 36),
              const SizedBox(height: 12),
              Text(
                'No calculation history yet.',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary(context)),
              ),
              const SizedBox(height: 4),
              Text(
                'Use the calculators above to get started.',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary(context)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _globalHistory.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final timestamp = DateTime.parse(item['timestamp'] ?? '');
        final provider = item['provider'] as String;
        final color = item['color'] as Color;
        final icon = item['icon'] as IconData;
        final details = '3M: ${_currencyFormat.format(item['threeMonths'])}';

        return FadeInItem(
          delay: Duration(milliseconds: 200 + i * 60),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.cardDecoration(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppTheme.iconBg(context, color),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            provider,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: color),
                          ),
                          Text(
                            _dateFormat.format(timestamp),
                            style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textHint(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Base: ${_currencyFormat.format(item['amount'])}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textPrimary(context)),
                          ),
                          Text(
                            details,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary(context)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Surcharge Warning ────────────────────────────────────────────────────
  Widget _buildSurchargeWarning(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.warningDecoration(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded,
              color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Checkout rates can vary per shop. Always double-check fees before purchasing.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary(context),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
