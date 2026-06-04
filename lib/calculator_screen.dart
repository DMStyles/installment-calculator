import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  // Calculator Controllers
  final TextEditingController _baseAmountCtrl = TextEditingController();
  final TextEditingController _procFeeCtrl = TextEditingController(text: '9');
  final TextEditingController _secRateCtrl = TextEditingController(text: '6');

  // Shop Fee Finder Controllers
  final TextEditingController _rawPriceCtrl = TextEditingController();
  final TextEditingController _checkoutPriceCtrl = TextEditingController();

  double? _baseAmount;
  double _procFeeAmount = 0.0;
  double _amtPlusProcFee = 0.0;
  double _secRateAmount = 0.0;
  double _amtPlusSecRate = 0.0;
  double _threeMonths = 0.0;
  double _sixMonths = 0.0;

  // Shop Fee Finder values
  double? _rawPrice;
  double? _checkoutPrice;
  double? _calculatedFeePercent;

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
      setState(() {
        _history = decoded.cast<Map<String, dynamic>>();
      });
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
      if (_history.length > 50) {
        _history.removeLast();
      }
      _showSavedFeedback = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kokoHistory', json.encode(_history));

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
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('kokoHistory');
      setState(() {
        _history.clear();
      });
    }
  }

  void _calculate() {
    final amountText = _baseAmountCtrl.text;
    final procFeeText = _procFeeCtrl.text;
    final secRateText = _secRateCtrl.text;

    final double? amount = double.tryParse(amountText);
    final double? procFee = double.tryParse(procFeeText);
    final double? secRate = double.tryParse(secRateText);

    if (amount == null || amount <= 0 || procFee == null || secRate == null) {
      setState(() {
        _baseAmount = null;
      });
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
    final rawText = _rawPriceCtrl.text;
    final checkoutText = _checkoutPriceCtrl.text;

    final double? raw = double.tryParse(rawText);
    final double? checkout = double.tryParse(checkoutText);

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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Koko Calculator', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF1F2937),
          elevation: 1,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Installments', icon: Icon(Icons.calculate)),
              Tab(text: 'Find Shop Fee', icon: Icon(Icons.percent)),
            ],
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
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
    return SingleChildScrollView(
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
    );
  }

  Widget _buildFindShopFeeTab() {
    final bool showResults = _calculatedFeePercent != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildShopFeeInputsCard(),
              if (showResults) ...[
                const SizedBox(height: 24),
                _buildShopFeeResultsCard(),
              ],
              const SizedBox(height: 24),
              _buildDisclaimersCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShopFeeInputsCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF374151)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shop Fee Calculator',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find out what percentage processing fee a merchant has added to the original price.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Original Price (Raw Value)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _rawPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                hintText: 'e.g. 10000',
                hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF374151)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Price on Site (Koko Checkout Price)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _checkoutPriceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                prefixStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                hintText: 'e.g. 10900',
                hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 16),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF374151)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopFeeResultsCard() {
    final double diff = (_checkoutPrice ?? 0.0) - (_rawPrice ?? 0.0);
    final String sign = diff >= 0 ? '+' : '';
    
    return Card(
      elevation: 0,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF374151)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Calculated Shop Fee',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 8),
            Text(
              '${_calculatedFeePercent!.toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Difference Amount:', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
                Text(
                  '$sign${_currencyFormat.format(diff)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: diff >= 0 ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisclaimersCard() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade300, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery & Other Costs',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Please check if this value includes delivery cost, handling fees, or other charges. Check carefully so you get the accurate processing fee percentage.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD1D5DB),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade300, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Koko Secondary Rate Note',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The secondary rate is charged by the Koko app itself, not the shop. For now, it stays at 6% (it might change later, but for now it remains the same).',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFD1D5DB),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
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
            Row(
              children: [
                Expanded(
                  child: _buildPercentageInput('Processing Fee %', _procFeeCtrl),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPercentageInput('Secondary Rate %', _secRateCtrl),
                ),
              ],
            ),
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
              borderSide: const BorderSide(color: Colors.blue, width: 2),
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
                  colors: [Colors.blue.withValues(alpha: 0.1), Colors.indigo.withValues(alpha: 0.1)],
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
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                  ),
                ),
                if (showResults) ...[
                  const SizedBox(height: 20),
                  _buildBreakdownSection(
                    'Processing Fee Amount',
                    _procFeeAmount,
                    'Total Amount for 3 Months',
                    _amtPlusProcFee,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildBreakdownSection(
                    'Secondary Rate Amount',
                    _secRateAmount,
                    'Total Amount for 6 Months',
                    _amtPlusSecRate,
                    Colors.indigo,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInstallmentBox('3 MONTHS', _threeMonths, Colors.blue),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInstallmentBox('6 MONTHS', _sixMonths, Colors.indigo),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _showSavedFeedback ? Colors.green : Colors.blue,
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

  Widget _buildBreakdownSection(String label1, double val1, String label2, double val2, MaterialColor accent) {
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
              Text(_currencyFormat.format(val2), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: accent.shade400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentBox(String title, double value, MaterialColor accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accent.shade300, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            _currencyFormat.format(value),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent.shade200),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '/ month',
            style: TextStyle(fontSize: 11, color: accent.shade300),
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
        side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade300),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '6M: ${_currencyFormat.format(item['sixMonths'])}',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo.shade300),
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
