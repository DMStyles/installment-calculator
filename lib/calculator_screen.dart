import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'widgets/pixel_card.dart';
import 'widgets/animated_section.dart';
import 'widgets/fade_in_item.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final TextEditingController _baseAmountCtrl = TextEditingController();
  final TextEditingController _procFeeCtrl = TextEditingController(text: '9');
  final TextEditingController _secRateCtrl = TextEditingController(text: '6');
  final TextEditingController _rawPriceCtrl = TextEditingController();
  final TextEditingController _checkoutPriceCtrl = TextEditingController();

  double? _baseAmount;
  double _procFeeAmount = 0.0;
  double _amtPlusProcFee = 0.0;
  double _secRateAmount = 0.0;
  double _amtPlusSecRate = 0.0;
  double _threeMonths = 0.0;
  double _sixMonths = 0.0;

  double? _rawPrice;
  double? _checkoutPrice;
  double? _calculatedFeePercent;

  List<Map<String, dynamic>> _history = [];
  bool _showSavedFeedback = false;

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ');
  final DateFormat _dateFormat = DateFormat('MMM d, h:mm a');

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _baseAmountCtrl.addListener(_calculate);
    _procFeeCtrl.addListener(_calculate);
    _secRateCtrl.addListener(_calculate);
    _rawPriceCtrl.addListener(_calculateShopFee);
    _checkoutPriceCtrl.addListener(_calculateShopFee);
  }

  @override
  void dispose() {
    _baseAmountCtrl.dispose();
    _procFeeCtrl.dispose();
    _secRateCtrl.dispose();
    _rawPriceCtrl.dispose();
    _checkoutPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('kokoHistory');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() => _history = decoded.cast<Map<String, dynamic>>());
    }
  }

  Future<void> _saveHistory() async {
    if (_baseAmount == null || _baseAmount! <= 0) return;
    final newEntry = {
      'amount': _baseAmount,
      'threeMonths': _threeMonths,
      'sixMonths': _sixMonths,
      'timestamp': DateTime.now().toIso8601String(),
    };
    setState(() {
      _history.insert(0, newEntry);
      if (_history.length > 50) _history.removeLast();
      _showSavedFeedback = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kokoHistory', json.encode(_history));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSavedFeedback = false);
    });
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content:
            const Text('Are you sure you want to clear all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kokoHistory');
      setState(() => _history.clear());
    }
  }

  void _calculate() {
    final double? amount = double.tryParse(_baseAmountCtrl.text);
    final double? procFee = double.tryParse(_procFeeCtrl.text);
    final double? secRate = double.tryParse(_secRateCtrl.text);
    if (amount == null || amount <= 0 || procFee == null || secRate == null) {
      setState(() => _baseAmount = null);
      return;
    }
    setState(() {
      _baseAmount = amount;
      _procFeeAmount = amount * (procFee / 100);
      _amtPlusProcFee = amount + _procFeeAmount;
      _secRateAmount = _amtPlusProcFee * (secRate / 100);
      _amtPlusSecRate = _amtPlusProcFee + _secRateAmount;
      _threeMonths = _amtPlusProcFee / 3;
      _sixMonths = _amtPlusSecRate / 6;
    });
  }

  void _calculateShopFee() {
    final double? raw = double.tryParse(_rawPriceCtrl.text);
    final double? checkout = double.tryParse(_checkoutPriceCtrl.text);
    if (raw == null || raw <= 0 || checkout == null || checkout <= 0) {
      setState(() {
        _rawPrice = null;
        _checkoutPrice = null;
        _calculatedFeePercent = null;
      });
      return;
    }
    setState(() {
      _rawPrice = raw;
      _checkoutPrice = checkout;
      _calculatedFeePercent = ((checkout - raw) / raw) * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surface(context),
        appBar: AppBar(
          title: Text('Koko Calculator',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: textPrimary)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Installments', icon: Icon(Icons.calculate_outlined)),
              Tab(text: 'Find Shop Fee', icon: Icon(Icons.percent_rounded)),
            ],
            indicatorColor: AppTheme.primary(context),
            labelColor: AppTheme.primary(context),
            unselectedLabelColor: AppTheme.textSecondary(context),
            dividerColor: Colors.transparent,
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildCalculatorTab(),
              _buildFindShopFeeTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalculatorTab() {
    final bool showResults = _baseAmount != null && _baseAmount! > 0;
    final primary = AppTheme.primary(context);
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ── Config Card ──────────────────────────────────────────────
              FadeInItem(
                delay: const Duration(milliseconds: 0),
                child: PixelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Configuration',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textPrimary)),
                          Icon(Icons.tune_rounded,
                              color: AppTheme.textSecondary(context), size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildPercentageInput(
                                'Processing Fee %', _procFeeCtrl),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildPercentageInput(
                                'Secondary Rate %', _secRateCtrl),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Calculator Card ──────────────────────────────────────────
              FadeInItem(
                delay: const Duration(milliseconds: 60),
                child: PixelCard(
                  accentColor: primary,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.iconBg(context, primary),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.calculate_outlined,
                                color: primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text('Calculator',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Base Amount',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _baseAmountCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        style: TextStyle(
                            fontSize: 18, color: textPrimary),
                        decoration: AppTheme.inputDecoration(context,
                            hintText: 'Enter amount...', prefixText: 'Rs. '),
                      ),
                      AnimatedSection(
                        visible: showResults,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            _buildBreakdownRow(
                                'Processing Fee',
                                _procFeeAmount,
                                '3M Total',
                                _amtPlusProcFee,
                                primary),
                            const SizedBox(height: 10),
                            _buildBreakdownRow(
                                'Secondary Rate',
                                _secRateAmount,
                                '6M Total',
                                _amtPlusSecRate,
                                const Color(0xFF818CF8)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInstallmentBox(
                                      '3 MONTHS', _threeMonths, primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInstallmentBox('6 MONTHS',
                                      _sixMonths, const Color(0xFF818CF8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 50,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                child: ElevatedButton.icon(
                                  onPressed: _saveHistory,
                                  icon: Icon(_showSavedFeedback
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.bookmark_add_outlined),
                                  label: Text(_showSavedFeedback
                                      ? 'Saved!'
                                      : 'Save to History'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _showSavedFeedback
                                        ? const Color(0xFF10B981)
                                        : primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          AppTheme.radiusPill),
                                    ),
                                    textStyle: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── History Card ─────────────────────────────────────────────
              FadeInItem(
                delay: const Duration(milliseconds: 120),
                child: PixelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('History',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textPrimary)),
                          if (_history.isNotEmpty)
                            TextButton(
                              onPressed: _clearHistory,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.redAccent,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('Clear All',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No history yet. Calculate and save to see it here.',
                              style: TextStyle(
                                  color: AppTheme.textSecondary(context),
                                  fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _history[index];
                            final timestamp =
                                DateTime.parse(item['timestamp']);
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardAlt(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.border(context)),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _dateFormat.format(timestamp),
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textHint(context)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Base: ${_currencyFormat.format(item['amount'])}',
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '3M: ${_currencyFormat.format(item['threeMonths'])}',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: primary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '6M: ${_currencyFormat.format(item['sixMonths'])}',
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF818CF8)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFindShopFeeTab() {
    final bool showResults = _calculatedFeePercent != null;
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final primary = AppTheme.primary(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              FadeInItem(
                child: PixelCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shop Fee Calculator',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary)),
                      const SizedBox(height: 6),
                      Text(
                        'Find what processing fee % a merchant added to the original price.',
                        style: TextStyle(
                            fontSize: 13, color: textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      Text('Original Price (Raw Value)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _rawPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        style: TextStyle(fontSize: 16, color: textPrimary),
                        decoration: AppTheme.inputDecoration(context,
                            hintText: 'e.g. 10000', prefixText: 'Rs. '),
                      ),
                      const SizedBox(height: 14),
                      Text('Price on Site (Koko Checkout Price)',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _checkoutPriceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*'))
                        ],
                        style: TextStyle(fontSize: 16, color: textPrimary),
                        decoration: AppTheme.inputDecoration(context,
                            hintText: 'e.g. 10900', prefixText: 'Rs. '),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSection(
                visible: showResults,
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    PixelCard(
                      accentColor: primary,
                      child: Column(
                        children: [
                          Text('Calculated Shop Fee',
                              style: TextStyle(
                                  fontSize: 13, color: textSecondary)),
                          const SizedBox(height: 8),
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0,
                                end: _calculatedFeePercent ?? 0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutCubic,
                            builder: (_, val, __) => Text(
                              '${val.toStringAsFixed(2)}%',
                              style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: primary),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Divider(color: AppTheme.border(context)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Difference Amount:',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 14)),
                              () {
                                final diff = (_checkoutPrice ?? 0) -
                                    (_rawPrice ?? 0);
                                final sign = diff >= 0 ? '+' : '';
                                return Text(
                                  '$sign${_currencyFormat.format(diff)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: diff >= 0
                                        ? Colors.redAccent
                                        : const Color(0xFF10B981),
                                    fontSize: 15,
                                  ),
                                );
                              }(),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FadeInItem(
                delay: const Duration(milliseconds: 120),
                child: Column(
                  children: [
                    _buildInfoNote(
                      icon: Icons.warning_amber_rounded,
                      color: Colors.amber,
                      isDark: isDark,
                      title: 'Delivery & Other Costs',
                      body:
                          'Check if the checkout price includes delivery, handling, or other charges before calculating.',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoNote(
                      icon: Icons.info_outline_rounded,
                      color: primary,
                      isDark: isDark,
                      title: 'Koko Secondary Rate Note',
                      body:
                          'The secondary rate is charged by Koko itself, not the shop. Currently it stays at 6% but may change.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(
      String label1, double val1, String label2, double val2, Color accent) {
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardAlt(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border(context)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label1,
                  style:
                      TextStyle(fontSize: 12, color: textSecondary)),
              Text(_currencyFormat.format(val1),
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label2,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary)),
              Text(_currencyFormat.format(val2),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: accent)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentBox(String title, double value, Color accent) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Column(
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, color: accent),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text('/ month',
              style: TextStyle(
                  fontSize: 11,
                  color: accent.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildPercentageInput(
      String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary(context))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
          style: TextStyle(
              color: AppTheme.textPrimary(context), fontSize: 15),
          decoration:
              AppTheme.inputDecoration(context, suffixText: '%'),
        ),
      ],
    );
  }

  Widget _buildInfoNote({
    required IconData icon,
    required Color color,
    required bool isDark,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.08 : 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radius),
        border: Border.all(
            color: color.withValues(alpha: isDark ? 0.18 : 0.25),
            width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon,
              color: isDark ? color.withValues(alpha: 0.8) : color,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary(context))),
                const SizedBox(height: 4),
                Text(body,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary(context),
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
