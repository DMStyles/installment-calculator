import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'widgets/pixel_card.dart';
import 'widgets/animated_section.dart';
import 'widgets/fade_in_item.dart';

class MintpayScreen extends StatefulWidget {
  const MintpayScreen({super.key});

  @override
  State<MintpayScreen> createState() => _MintpayScreenState();
}

class _MintpayScreenState extends State<MintpayScreen> {
  static const _accent = Color(0xFF10B981);

  final TextEditingController _baseAmountCtrl = TextEditingController();
  final TextEditingController _procFeeCtrl =
      TextEditingController(text: '0');

  double? _baseAmount;
  double _procFeeAmount = 0.0;
  double _totalAmount = 0.0;
  double _threeMonths = 0.0;

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
  }

  @override
  void dispose() {
    _baseAmountCtrl.dispose();
    _procFeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('mintpayHistory');
    if (historyJson != null) {
      final List<dynamic> decoded = json.decode(historyJson);
      setState(() => _history = decoded.cast<Map<String, dynamic>>());
    }
  }

  Future<void> _saveHistory() async {
    if (_baseAmount == null || _baseAmount! <= 0) return;
    final newEntry = {
      'amount': _baseAmount,
      'totalAmount': _totalAmount,
      'threeMonths': _threeMonths,
      'timestamp': DateTime.now().toIso8601String(),
    };
    setState(() {
      _history.insert(0, newEntry);
      if (_history.length > 50) _history.removeLast();
      _showSavedFeedback = true;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mintpayHistory', json.encode(_history));
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _showSavedFeedback = false);
    });
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Are you sure you want to clear all history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mintpayHistory');
      setState(() => _history.clear());
    }
  }

  void _calculate() {
    final double? amount = double.tryParse(_baseAmountCtrl.text);
    final double? procFee = double.tryParse(_procFeeCtrl.text);
    if (amount == null || amount <= 0 || procFee == null) {
      setState(() => _baseAmount = null);
      return;
    }
    setState(() {
      _baseAmount = amount;
      _procFeeAmount = amount * (procFee / 100);
      _totalAmount = amount + _procFeeAmount;
      _threeMonths = _totalAmount / 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool showResults = _baseAmount != null && _baseAmount! > 0;
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      appBar: AppBar(
        title: Text('MintPay Calculator',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // ── Config Card ────────────────────────────────────────────
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
                                  color: textSecondary, size: 20),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Processing Fee %',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: textSecondary)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _procFeeCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d*'))
                                ],
                                style:
                                    TextStyle(color: textPrimary, fontSize: 15),
                                decoration: AppTheme.inputDecoration(context,
                                    suffixText: '%'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Calculator Card ─────────────────────────────────────────
                  FadeInItem(
                    delay: const Duration(milliseconds: 60),
                    child: PixelCard(
                      accentColor: _accent,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.eco_outlined,
                                    color: _accent, size: 20),
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
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*'))
                            ],
                            style: TextStyle(
                                fontSize: 18, color: textPrimary),
                            decoration: AppTheme.inputDecoration(context,
                                hintText: 'Enter amount...',
                                prefixText: 'Rs. '),
                          ),
                          AnimatedSection(
                            visible: showResults,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 20),
                                // Breakdown
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardAlt(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppTheme.border(context)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Processing Fee',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary)),
                                          Text(
                                              _currencyFormat
                                                  .format(_procFeeAmount),
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: textPrimary)),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Total Amount',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  color: textPrimary)),
                                          Text(
                                              _currencyFormat
                                                  .format(_totalAmount),
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: _accent)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Big installment box
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 20),
                                  decoration: BoxDecoration(
                                    color: _accent.withValues(alpha: 0.10),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: _accent.withValues(alpha: 0.25),
                                        width: 1.5),
                                  ),
                                  child: Column(
                                    children: [
                                      const Text('3 MONTHS',
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _accent,
                                              letterSpacing: 0.5)),
                                      const SizedBox(height: 8),
                                      Text(
                                        _currencyFormat.format(_threeMonths),
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: _accent),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Text('/ month',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF059669))),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 50,
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
                                          ? const Color(0xFF059669)
                                          : _accent,
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
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: Text(
                                  'No history yet. Calculate and save to see it here.',
                                  style: TextStyle(
                                      color: textSecondary, fontSize: 13),
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
                                                color:
                                                    AppTheme.textHint(context)),
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
                                      Text(
                                        '3M: ${_currencyFormat.format(item['threeMonths'])}',
                                        style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: _accent),
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
        ),
      ),
    );
  }
}
