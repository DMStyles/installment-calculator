import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E);
    final textPrimary = isDark ? Colors.white : const Color(0xFF1F1F1F);
    final cardBg = isDark ? const Color(0xFF1E2025) : Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Shopping Guide', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  _buildSectionHeader(context, 'Understanding BNPL (Buy Now Pay Later)'),
                  const SizedBox(height: 12),
                  _buildMainGuideCard(context, cardBg, textPrimary, textSecondary),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Provider Details'),
                  const SizedBox(height: 12),
                  _buildProviderGuideCard(
                    context: context,
                    title: 'Koko (by Daraz)',
                    accentColor: const Color(0xFFFFB6C1),
                    icon: Icons.shopping_bag_outlined,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    details: [
                      '⏱️ **Installment Period:** 3 months (3 equal payments). First payment made immediately at checkout, next two over the next 2 months.',
                      '💰 **Processing Fee:** Defaults to 9% depending on the store. Some stores offer 0% promotional terms, but others may mark up prices.',
                      '⚡ **Secondary Rate:** An additional 6% interest rate applies if choosing extended 6-month repayment options.',
                      '📈 **Limits:** Starting limits vary based on credit check. Complete your profile details in the Koko app to increase limits.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProviderGuideCard(
                    context: context,
                    title: 'PayZy',
                    accentColor: const Color(0xFF00AEEF),
                    icon: Icons.bolt,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    details: [
                      '⏱️ **Installment Period:** Flexible repayment terms of 2, 3, or 4 months.',
                      '💰 **Processing Fee:** Typically 8% added directly to the checkout total, but merchants can configure their own rates.',
                      '📈 **Limits:** Instantly verified limits through the app during signup. Payments are charged automatically to your linked debit/credit card.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProviderGuideCard(
                    context: context,
                    title: 'MintPay',
                    accentColor: const Color(0xFF10B981),
                    icon: Icons.eco_outlined,
                    cardBg: cardBg,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    details: [
                      '⏱️ **Installment Period:** 3 months. Splits the bill into 3 interest-free payments (1/3 today, 1/3 in 30 days, 1/3 in 60 days).',
                      '💰 **Processing Fee:** 0% on standard MintPay partner transactions. However, some independent merchants charge a manual fee.',
                      '⚠️ **Late Fees:** MintPay does not charge interest, but strict late fees apply if card charges fail on due dates. Keep your cards funded!',
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSurchargeTipsCard(context, textPrimary, textSecondary),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF1F1F1F),
        ),
      ),
    );
  }

  Widget _buildMainGuideCard(BuildContext context, Color cardBg, Color textPrimary, Color textSecondary) {
    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'What is BNPL?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Buy Now Pay Later (BNPL) lets you split purchase payments into interest-free installments. '
              'While the platforms themselves advertise 0% interest, merchants and shops often add a custom processing '
              'fee (surcharge) at checkout to cover their platform costs. '
              'Always use this calculator to check total costs before purchasing.',
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderGuideCard({
    required BuildContext context,
    required String title,
    required Color accentColor,
    required IconData icon,
    required List<String> details,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      color: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? accentColor.withValues(alpha: 0.15) : accentColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(icon, color: accentColor, size: 24),
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 16),
          ),
          iconColor: accentColor,
          collapsedIconColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildFormattedText(detail, textPrimary, textSecondary),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSurchargeTipsCard(BuildContext context, Color textPrimary, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = isDark ? Colors.amber.shade200 : Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.amber.withValues(alpha: 0.06) : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.amber.withValues(alpha: 0.15) : Colors.amber.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: warningColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Avoiding Surcharges & Extra Fees',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTipRow('🛒 Compare Store Prices:', 'Some shops sell products cheaper but add high BNPL checkout fees. Compare the total checkout cost (Price + BNPL Fee) across different shops.', textPrimary, textSecondary),
          const SizedBox(height: 12),
          _buildTipRow('🚚 Delivery Charges:', 'Always verify if the shop has added shipping/handling to the checkout price. The "Find Shop Fee" calculator will calculate shipping as a fee if it is not subtracted first.', textPrimary, textSecondary),
          const SizedBox(height: 12),
          _buildTipRow('💳 Credit Limit Checks:', 'Always keep your primary debit or credit card funded. If a recurring monthly installment payment fails due to insufficient balance, the provider will charge you a hefty penalty fee.', textPrimary, textSecondary),
        ],
      ),
    );
  }

  Widget _buildTipRow(String title, String body, Color textPrimary, Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedText(String text, Color textPrimary, Color textSecondary) {
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 13, height: 1.4),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
