import 'package:flutter/material.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Shopping Guide', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1F2937),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  _buildSectionHeader('Understanding BNPL (Buy Now Pay Later)'),
                  const SizedBox(height: 12),
                  _buildMainGuideCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Provider Details'),
                  const SizedBox(height: 12),
                  _buildProviderGuideCard(
                    title: 'Koko (by Daraz)',
                    accentColor: const Color(0xFFFFB6C1),
                    icon: Icons.shopping_bag,
                    details: [
                      '⏱️ **Installment Period:** 3 months (3 equal payments). First payment made immediately at checkout, next two over the next 2 months.',
                      '💰 **Processing Fee:** Defaults to 9% depending on the store. Some stores offer 0% promotional terms, but others may mark up prices.',
                      '⚡ **Secondary Rate:** An additional 6% interest rate applies if choosing extended 6-month repayment options.',
                      '📈 **Limits:** Starting limits vary based on credit check. Complete your profile details in the Koko app to increase limits.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProviderGuideCard(
                    title: 'PayZy',
                    accentColor: const Color(0xFF00AEEF),
                    icon: Icons.bolt,
                    details: [
                      '⏱️ **Installment Period:** Flexible repayment terms of 2, 3, or 4 months.',
                      '💰 **Processing Fee:** Typically 8% added directly to the checkout total, but merchants can configure their own rates.',
                      '📈 **Limits:** Instantly verified limits through the app during signup. Payments are charged automatically to your linked debit/credit card.',
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildProviderGuideCard(
                    title: 'MintPay',
                    accentColor: const Color(0xFF10B981),
                    icon: Icons.eco,
                    details: [
                      '⏱️ **Installment Period:** 3 months. Splits the bill into 3 interest-free payments (1/3 today, 1/3 in 30 days, 1/3 in 60 days).',
                      '💰 **Processing Fee:** 0% on standard MintPay partner transactions. However, some independent merchants charge a manual fee.',
                      '⚠️ **Late Fees:** MintPay does not charge interest, but strict late fees apply if card charges fail on due dates. Keep your cards funded!',
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSurchargeTipsCard(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMainGuideCard() {
    return Card(
      elevation: 0,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF374151)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(width: 12),
                Text(
                  'What is BNPL?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Buy Now Pay Later (BNPL) lets you split purchase payments into interest-free installments. '
              'While the platforms themselves advertise 0% interest, merchants and shops often add a custom processing '
              'fee (surcharge) at checkout to cover their platform costs. '
              'Always use this calculator to check total costs before purchasing.',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderGuideCard({
    required String title,
    required Color accentColor,
    required IconData icon,
    required List<String> details,
  }) {
    return Card(
      elevation: 0,
      color: const Color(0xFF1F2937),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accentColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Theme(
        data: ThemeData.dark().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(icon, color: accentColor),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          iconColor: accentColor,
          collapsedIconColor: const Color(0xFF9CA3AF),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: details.map((detail) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildFormattedText(detail),
                  );
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSurchargeTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.amber.shade300, size: 22),
              const SizedBox(width: 10),
              const Text(
                'Avoiding Surcharges & Extra Fees',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTipRow('🛒 Compare Store Prices:', 'Some shops sell products cheaper but add high BNPL checkout fees. Compare the total checkout cost (Price + BNPL Fee) across different shops.'),
          const SizedBox(height: 12),
          _buildTipRow('🚚 Delivery Charges:', 'Always verify if the shop has added shipping/handling to the checkout price. The "Find Shop Fee" calculator will calculate shipping as a fee if it is not subtracted first.'),
          const SizedBox(height: 12),
          _buildTipRow('💳 Credit Limit Checks:', 'Always keep your primary debit or credit card funded. If a recurring monthly installment payment fails due to insufficient balance, the provider will charge you a hefty penalty fee.'),
        ],
      ),
    );
  }

  Widget _buildTipRow(String title, String body) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedText(String text) {
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13, height: 1.4),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, height: 1.4),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
