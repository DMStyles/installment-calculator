import 'package:flutter/material.dart';
import 'calculator_screen.dart';
import 'payzy_screen.dart';
import 'mintpay_screen.dart';
import 'page_transitions.dart';

class ProviderSelectScreen extends StatelessWidget {
  const ProviderSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Select Provider', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                  Text(
                    'Choose an installment provider to calculate fees and plans.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
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
                      PixelPageRoute(builder: (_) => const CalculatorScreen()),
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
                      PixelPageRoute(builder: (_) => const PayzyScreen()),
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
                      PixelPageRoute(builder: (_) => const MintpayScreen()),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E2025) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 22.0),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    logoPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.account_balance_wallet_outlined, color: color, size: 32);
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
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
