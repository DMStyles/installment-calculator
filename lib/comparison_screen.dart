import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  
  // Custom fee controllers
  final TextEditingController _kokoFeeCtrl = TextEditingController(text: '9');
  final TextEditingController _payzyFeeCtrl = TextEditingController(text: '8');
  final TextEditingController _mintpayFeeCtrl = TextEditingController(text: '0');

  double? _baseAmount;
  bool _showFeesConfig = false;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ');

  @override
  void initState() {
    super.initState();
    _amountCtrl.addListener(() {
      setState(() {
        _baseAmount = double.tryParse(_amountCtrl.text);
      });
    });
    _kokoFeeCtrl.addListener(_updateState);
    _payzyFeeCtrl.addListener(_updateState);
    _mintpayFeeCtrl.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _kokoFeeCtrl.dispose();
    _payzyFeeCtrl.dispose();
    _mintpayFeeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showResults = _baseAmount != null && _baseAmount! > 0;

    // Calculate calculations if base amount is present
    Map<String, dynamic>? kokoData;
    Map<String, dynamic>? payzyData;
    Map<String, dynamic>? mintpayData;
    String? bestProvider;

    if (showResults) {
      final base = _baseAmount!;
      final kokoFee = double.tryParse(_kokoFeeCtrl.text) ?? 9.0;
      final payzyFee = double.tryParse(_payzyFeeCtrl.text) ?? 8.0;
      final mintpayFee = double.tryParse(_mintpayFeeCtrl.text) ?? 0.0;

      final kokoTotal = base + (base * kokoFee / 100);
      final payzyTotal = base + (base * payzyFee / 100);
      final mintpayTotal = base + (base * mintpayFee / 100);

      kokoData = {
        'total': kokoTotal,
        'installments': [
          {'months': 3, 'amount': kokoTotal / 3},
        ],
      };

      payzyData = {
        'total': payzyTotal,
        'installments': [
          {'months': 2, 'amount': payzyTotal / 2},
          {'months': 3, 'amount': payzyTotal / 3},
          {'months': 4, 'amount': payzyTotal / 4},
        ],
      };

      mintpayData = {
        'total': mintpayTotal,
        'installments': [
          {'months': 3, 'amount': mintpayTotal / 3},
        ],
      };

      // Determine cheapest total cost
      double minTotal = kokoTotal;
      bestProvider = 'Koko';

      if (payzyTotal < minTotal) {
        minTotal = payzyTotal;
        bestProvider = 'PayZy';
      }
      if (mintpayTotal < minTotal) {
        minTotal = mintpayTotal;
        bestProvider = 'MintPay';
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Compare Providers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  _buildInputCard(),
                  const SizedBox(height: 16),
                  _buildConfigToggle(),
                  if (_showFeesConfig) ...[
                    const SizedBox(height: 12),
                    _buildFeesConfigCard(),
                  ],
                  if (showResults) ...[
                    const SizedBox(height: 24),
                    _buildCompareResults(
                      bestProvider: bestProvider!,
                      koko: kokoData!,
                      payzy: payzyData!,
                      mintpay: mintpayData!,
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1F1F);
    
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E2025) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Product Price',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              style: TextStyle(fontSize: 20, color: textPrimary, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: 'Rs. ',
                prefixStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textSecondary),
                hintText: 'e.g. 25,000',
                hintStyle: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), fontSize: 18, fontWeight: FontWeight.normal),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E);

    return InkWell(
      onTap: () => setState(() => _showFeesConfig = !_showFeesConfig),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.settings_outlined, color: textSecondary, size: 18),
                const SizedBox(width: 8),
                Text(
                  _showFeesConfig ? 'Hide Custom Fee Rates' : 'Adjust Default Fee Rates',
                  style: TextStyle(fontSize: 13, color: textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Icon(
              _showFeesConfig ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeesConfigCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1F1F);
    
    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E2025) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize Platform Fees (%)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMiniFeeInput('Koko Fee', _kokoFeeCtrl, const Color(0xFFFFB6C1)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniFeeInput('PayZy Fee', _payzyFeeCtrl, const Color(0xFF00AEEF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMiniFeeInput('MintPay Fee', _mintpayFeeCtrl, const Color(0xFF10B981)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniFeeInput(String label, TextEditingController ctrl, Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1F1F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          style: TextStyle(color: textPrimary, fontSize: 14),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            suffixText: '%',
            suffixStyle: TextStyle(color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF), fontSize: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accentColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompareResults({
    required String bestProvider,
    required Map<String, dynamic> koko,
    required Map<String, dynamic> payzy,
    required Map<String, dynamic> mintpay,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1F1F);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Side-by-Side Comparison',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 16),
        
        // Koko Card
        _buildCompareCard(
          providerName: 'Koko',
          total: koko['total'],
          installments: koko['installments'],
          accentColor: const Color(0xFFFFB6C1),
          logoPath: 'assets/logos/koko.png',
          fallbackIcon: Icons.shopping_bag_outlined,
          isBestValue: bestProvider == 'Koko',
        ),
        const SizedBox(height: 12),
        
        // PayZy Card
        _buildCompareCard(
          providerName: 'PayZy',
          total: payzy['total'],
          installments: payzy['installments'],
          accentColor: const Color(0xFF00AEEF),
          logoPath: 'assets/logos/payzy.png',
          fallbackIcon: Icons.bolt,
          isBestValue: bestProvider == 'PayZy',
        ),
        const SizedBox(height: 12),
        
        // MintPay Card
        _buildCompareCard(
          providerName: 'MintPay',
          total: mintpay['total'],
          installments: mintpay['installments'],
          accentColor: const Color(0xFF10B981),
          logoPath: 'assets/logos/mintpay.png',
          fallbackIcon: Icons.eco_outlined,
          isBestValue: bestProvider == 'MintPay',
        ),
      ],
    );
  }

  Widget _buildCompareCard({
    required String providerName,
    required double total,
    required List<dynamic> installments,
    required Color accentColor,
    required String logoPath,
    required IconData fallbackIcon,
    required bool isBestValue,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final cardBg = isDark ? const Color(0xFF1E2025) : Colors.white;

    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isBestValue 
              ? accentColor.withValues(alpha: 0.7) 
              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isBestValue ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      logoPath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(fallbackIcon, color: accentColor, size: 22);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Total: ${_currencyFormat.format(total)}',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                if (isBestValue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: accentColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Best Value',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5), height: 1),
            const SizedBox(height: 16),
            Row(
              children: installments.map<Widget>((inst) {
                final int months = inst['months'];
                final double instAmount = inst['amount'];
                
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF121318) : const Color(0xFFF1F3F4),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$months MONTHS',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accentColor.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(instAmount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '/ month',
                          style: TextStyle(fontSize: 8, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
