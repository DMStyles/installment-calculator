import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings.dart';
import 'provider_select_screen.dart';
import 'comparison_screen.dart';
import 'guide_screen.dart';
import 'tracker_screen.dart';
import 'settings_screen.dart';
import 'update_checker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _globalHistory = [];
  bool _isLoading = true;
  UpdateInfo? _updateBanner; // non-null = show banner
  bool _bannerDismissed = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ');
  final DateFormat _dateFormat = DateFormat('MMM d, h:mm a');

  @override
  void initState() {
    super.initState();
    _loadGlobalHistory();
    _silentUpdateCheck();
  }

  /// Runs in background — never blocks the UI.
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

    // Load Koko History
    final String? kokoJson = prefs.getString('kokoHistory');
    if (kokoJson != null) {
      final List<dynamic> decoded = json.decode(kokoJson);
      for (var item in decoded) {
        allItems.add({
          ...Map<String, dynamic>.from(item),
          'provider': 'Koko',
          'color': const Color(0xFFFFB6C1),
          'icon': Icons.shopping_bag,
        });
      }
    }

    // Load PayZy History
    final String? payzyJson = prefs.getString('payzyHistory');
    if (payzyJson != null) {
      final List<dynamic> decoded = json.decode(payzyJson);
      for (var item in decoded) {
        allItems.add({
          ...Map<String, dynamic>.from(item),
          'provider': 'PayZy',
          'color': const Color(0xFF00AEEF),
          'icon': Icons.bolt,
        });
      }
    }

    // Load MintPay History
    final String? mintpayJson = prefs.getString('mintpayHistory');
    if (mintpayJson != null) {
      final List<dynamic> decoded = json.decode(mintpayJson);
      for (var item in decoded) {
        allItems.add({
          ...Map<String, dynamic>.from(item),
          'provider': 'MintPay',
          'color': const Color(0xFF10B981),
          'icon': Icons.eco,
        });
      }
    }

    // Sort by timestamp descending
    allItems.sort((a, b) {
      final DateTime timeA = DateTime.parse(a['timestamp'] ?? '');
      final DateTime timeB = DateTime.parse(b['timestamp'] ?? '');
      return timeB.compareTo(timeA);
    });

    // Take top 3
    setState(() {
      _globalHistory = allItems.take(3).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettings>();
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, isDark),
                  if (_updateBanner != null && !_bannerDismissed) ...[
                    const SizedBox(height: 14),
                    _buildUpdateBanner(_updateBanner!),
                  ],
                  const SizedBox(height: 24),
                  _buildDashboardGrid(),
                  const SizedBox(height: 32),
                  _buildRecentCalculationsHeader(),
                  const SizedBox(height: 12),
                  _buildRecentCalculationsList(),
                  const SizedBox(height: 32),
                  _buildSurchargeWarning(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Installment Hub',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
              icon: Icon(
                Icons.settings_outlined,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                size: 24,
              ),
              tooltip: 'Settings',
            ),
          ],
        ),
        Text(
          'Plan your purchases and find hidden BNPL fees.',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        ),
      ],
    );
  }

  Widget _buildUpdateBanner(UpdateInfo info) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.new_releases_rounded, color: Color(0xFF3B82F6), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v${info.latestVersion} is available!',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
                Text(
                  'A new update is ready to download.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Update',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _bannerDismissed = true),
            child: Icon(Icons.close_rounded, color: Colors.grey.shade500, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardGrid() {
    return Column(
      children: [
        _buildDashboardCard(
          title: 'BNPL Calculators',
          subtitle: 'Calculate Koko, PayZy, and MintPay plans',
          icon: Icons.calculate,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProviderSelectScreen()),
          ).then((_) => _loadGlobalHistory()),
        ),
        const SizedBox(height: 16),
        _buildDashboardCard(
          title: 'Installment Manager',
          subtitle: 'Track payments, remaining terms & get reminders',
          icon: Icons.receipt_long,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TrackerScreen()),
          ).then((_) => _loadGlobalHistory()),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSquareDashboardCard(
                title: 'Compare Prices',
                icon: Icons.compare_arrows,
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ComparisonScreen()),
                ).then((_) => _loadGlobalHistory()),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSquareDashboardCard(
                title: 'Shopping Guides',
                icon: Icons.menu_book,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GuideScreen()),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF6B7280)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquareDashboardCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Open tool', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                  Icon(Icons.arrow_forward, color: color, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCalculationsHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        'Recent Calculations',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRecentCalculationsList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final borderColor = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    if (_globalHistory.isEmpty) {
      return Card(
        elevation: 0,
        color: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 32.0, horizontal: 20.0),
          child: Column(
            children: [
              Icon(Icons.history_toggle_off, color: Color(0xFF6B7280), size: 36),
              SizedBox(height: 12),
              Text(
                'No calculation history found.',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Use the calculators to save calculations.',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _globalHistory.map((item) {
        final timestamp = DateTime.parse(item['timestamp'] ?? '');
        final provider = item['provider'] ?? '';
        final color = item['color'] as Color;
        final icon = item['icon'] as IconData;

        String details = '';
        if (provider == 'Koko') {
          details = '3M: ${_currencyFormat.format(item['threeMonths'])}';
        } else if (provider == 'PayZy') {
          details = '3M: ${_currencyFormat.format(item['threeMonths'])}';
        } else if (provider == 'MintPay') {
          details = '3M: ${_currencyFormat.format(item['threeMonths'])}';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
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
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
                        ),
                        Text(
                          _dateFormat.format(timestamp),
                          style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Base: ${_currencyFormat.format(item['amount'])}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          details,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSurchargeWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Checkout rates can vary depending on the shop. Always double-check fee structures before purchase.',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD1D5DB),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
