import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MintpayScreen extends StatefulWidget {
  const MintpayScreen({super.key});

  @override
  State<MintpayScreen> createState() => _MintpayScreenState();
}

class _MintpayScreenState extends State<MintpayScreen> {
  final TextEditingController _baseAmountCtrl = TextEditingController();
  final TextEditingController _procFeeCtrl = TextEditingController(text: '0');

  double? _baseAmount;
  double _procFeeAmount = 0.0;
  double _totalAmount = 0.0;
  double _threeMonths = 0.0;

  List<Map<String, dynamic>> _history = [];
  bool _showSavedFeedback = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ');
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
      setState(() {
        _history = decoded.cast<Map<String, dynamic>>();
      });
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
      if (_history.length > 50) {
        _history.removeLast();
      }
      _showSavedFeedback = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mintpayHistory', json.encode(_history));

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showSavedFeedback = false;
        });
      }
    });
  }

  Future<void> _clearHistory() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1F2937),
          title: const Text('Clear History', style: TextStyle(color: Colors.white)),
          content: const Text('Are you sure you want to clear all history?', style: TextStyle(color: Color(0xFF9CA3AF))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.blue)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('mintpayHistory');
      setState(() {
        _history.clear();
      });
    }
  }

  void _calculate() {
    final amountText = _baseAmountCtrl.text;
    final procFeeText = _procFeeCtrl.text;

    final double? amount = double.tryParse(amountText);
    final double? procFee = double.tryParse(procFeeText);

    if (amount == null || amount <= 0 || procFee == null) {
      setState(() {
        _baseAmount = null;
      });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('MintPay Calculator', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  const SizedBox(height: 16),
                  _buildConfigCard(),
                  const SizedBox(height: 24),
                  _buildCalculatorCard(),
                  const SizedBox(height: 24),
                  _buildHistoryCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF374151)),
      ),
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Configuration',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                ),
                const Icon(Icons.settings_outlined, color: Color(0xFF9CA3AF), size: 20),
              ],
            ),
            const SizedBox(height: 16),
            _buildPercentageInput('Processing Fee %', _procFeeCtrl),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageInput(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            suffixText: '%',
            suffixStyle: const TextStyle(color: Color(0xFF6B7280)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF374151)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2), // Mint Green
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorCard() {
    final bool showResults = _baseAmount != null && _baseAmount! > 0;

    return Card(
      elevation: 0,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF374151)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF10B981).withValues(alpha: 0.1), Colors.green.withValues(alpha: 0.1)],
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomLeft: Radius.circular(100),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calculator',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Base Amount',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _baseAmountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                  decoration: InputDecoration(
                    prefixText: 'Rs. ',
                    prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                    hintText: 'Enter amount...',
                    hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                    ),
                  ),
                ),
                if (showResults) ...[
                  const SizedBox(height: 20),
                  _buildBreakdownSection(
                    'Processing Fee Amount',
                    _procFeeAmount,
                    'Total Amount',
                    _totalAmount,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 16),
                  _buildInstallmentBox('3 MONTHS', _threeMonths, Colors.green),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showSavedFeedback ? Colors.teal : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _showSavedFeedback ? 'Saved!' : 'Save to History',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownSection(String label1, double val1, String label2, double val2, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF374151)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label1, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              Text(_currencyFormat.format(val1), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              Text(_currencyFormat.format(val2), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accentColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentBox(String title, double value, MaterialColor accent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent.shade300, letterSpacing: 0.5),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: accent.shade200),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '/ month',
            style: TextStyle(fontSize: 12, color: accent.shade300),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF374151)),
      ),
      color: const Color(0xFF1F2937),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                ),
                if (_history.isNotEmpty)
                  TextButton(
                    onPressed: _clearHistory,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Clear All', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (_history.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: const Text(
                  'No history yet. Calculate and save to see it here.',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = _history[index];
                  final timestamp = DateTime.parse(item['timestamp']);
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF111827),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF374151)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _dateFormat.format(timestamp),
                              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Base: ${_currencyFormat.format(item['amount'])}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '3M: ${_currencyFormat.format(item['threeMonths'])}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.green.shade300),
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
    );
  }
}
