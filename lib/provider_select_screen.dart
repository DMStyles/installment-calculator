import 'package:flutter/material.dart';
import 'calculator_screen.dart';
import 'payzy_screen.dart';
import 'mintpay_screen.dart';

class ProviderSelectScreen extends StatelessWidget {
  const ProviderSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Provider', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose an installment provider to calculate fees and plans.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 32),
                  _buildProviderCard(
                    context: context,
                    title: 'Koko',
                    subtitle: 'Calculate processing and secondary rates',
                    logoPath: 'assets/logos/koko.png',
                    color: const Color(0xFFFFB6C1), // Soft pink based on Koko logo
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CalculatorScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProviderCard(
                    context: context,
                    title: 'PayZy',
                    subtitle: '2, 3, or 4 month installments',
                    logoPath: 'assets/logos/payzy.png',
                    color: const Color(0xFF00AEEF), // Light blue based on PayZy logo
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PayzyScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProviderCard(
                    context: context,
                    title: 'MintPay',
                    subtitle: '3 month installments',
                    logoPath: 'assets/logos/mintpay.png',
                    color: const Color(0xFF10B981), // Mint green
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MintpayScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String logoPath,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback if logo is missing
                      return Icon(Icons.account_balance_wallet, color: color, size: 32);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
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
}
