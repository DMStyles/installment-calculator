import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets/pixel_card.dart';

class GuideScreen extends StatelessWidget {
  final int initialTab;
  const GuideScreen({super.key, this.initialTab = 0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final primary = Theme.of(context).colorScheme.primary;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppTheme.surface(context),
        appBar: AppBar(
          title: Text(
            'Guides & Help',
            style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textPrimary),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.cardAlt(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border(context)),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: textSecondary,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.touch_app_outlined, size: 18),
                    text: 'How to Use App',
                  ),
                  Tab(
                    icon: Icon(Icons.storefront_outlined, size: 18),
                    text: 'BNPL Guide',
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              _buildAppUserGuideTab(context, isDark, textPrimary, textSecondary, primary),
              _buildBnplShoppingGuideTab(context, isDark, textPrimary, textSecondary, primary),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 1: HOW TO USE THE APP (USER WALKTHROUGH)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildAppUserGuideTab(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color primary,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // Welcome banner card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: primary.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.auto_awesome, color: primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to Installment Hub!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your smart shopping companion for Sri Lankan BNPL services (Koko, PayZy & MintPay). Here is how to make the most of every feature:',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),
              _buildSectionHeader(context, 'Core App Features'),
              const SizedBox(height: 12),

              // Step 1: Calculators & Koko 10%
              _buildGuideStepCard(
                context: context,
                stepNumber: '1',
                title: 'BNPL Fee Calculators',
                icon: Icons.calculate_outlined,
                accentColor: const Color(0xFF0B57D0),
                content: [
                  '**Instant Breakdown:** Open any provider (Koko, PayZy, or MintPay) from the home screen, enter the item\'s base cash price, and instantly see monthly installment amounts.',
                  '**Adjust Processing Fees:** Shops often charge different processing fees (defaults: 9% for Koko, 8% for PayZy). You can tweak the fee percentage at any time.',
                  '**⚡ Koko 6-Month Fee (Now 10%):** Koko recently updated their extended 6-month secondary fee from 6% to **10%**. The Koko calculator displays both the 3-Month and 6-Month options side-by-side with updated math.',
                  '**Save to History:** Tap "Save to History" to keep track of past calculations right on the calculator screen.',
                ],
              ),

              const SizedBox(height: 14),

              // Step 2: Reverse Calculator
              _buildGuideStepCard(
                context: context,
                stepNumber: '2',
                title: 'Detect Hidden Shop Markups',
                icon: Icons.search_rounded,
                accentColor: const Color(0xFF818CF8),
                content: [
                  '**Uncover Extra Fees:** Many online stores quietly increase prices when paying via Koko or PayZy compared to paying cash.',
                  '**"Find Shop Fee" Tool:** Inside each calculator, scroll down to the "Find Shop Fee" section.',
                  '**How It Works:** Enter the Cash Price and the Checkout Price. The app automatically calculates the exact hidden markup percentage the store is charging you.',
                ],
              ),

              const SizedBox(height: 14),

              // Step 3: Installment Manager & 30-Day Math
              _buildGuideStepCard(
                context: context,
                stepNumber: '3',
                title: 'Installment Manager (Tracker)',
                icon: Icons.receipt_long_outlined,
                accentColor: const Color(0xFF10B981),
                content: [
                  '**Add Your Purchases:** Tap "Installment Manager" on the home screen, then tap the **+** button at the bottom right. Enter the purchase name, total amount, provider, and purchase date.',
                  '**⏱️ 30-Day Payment Interval:** Sri Lankan BNPL providers (like Koko) charge every **30 days** rather than on the same calendar day of each month. The app automatically schedules each installment exactly 30 days apart.',
                  '**Auto-Fill for Past Months:** If you add an installment plan that you started months ago, the app automatically marks all previous past due dates as Paid for you.',
                  '**Mark as Paid:** Tap any individual payment installment card to quickly toggle its status between Paid and Unpaid.',
                ],
              ),

              const SizedBox(height: 14),

              // Step 4: Reminders
              _buildGuideStepCard(
                context: context,
                stepNumber: '4',
                title: 'Automated Due-Date Reminders',
                icon: Icons.notifications_active_outlined,
                accentColor: const Color(0xFFF59E0B),
                content: [
                  '**Never Miss a Payment:** Go to Settings (⚙️ icon on the top right of the Home screen) and make sure "Enable Reminders" is turned on.',
                  '**Lead Days (1, 2, or 3 Days):** Choose how many days in advance you want notifications.',
                  '**Daily Multi-Day Alerts:** If set to 2 or 3 days, you will receive reminders every day leading up to the due date, giving you enough time to top up your bank card before auto-debit triggers.',
                ],
              ),

              const SizedBox(height: 14),

              // Step 5: Comparison Tool
              _buildGuideStepCard(
                context: context,
                stepNumber: '5',
                title: 'Side-by-Side Comparison',
                icon: Icons.compare_arrows_rounded,
                accentColor: const Color(0xFFEC4899),
                content: [
                  '**Find the Cheapest Option:** Tap "Compare" on the home dashboard.',
                  '**Simultaneous Evaluation:** Enter any purchase price to compare Koko (3M & 6M), PayZy (2M, 3M, 4M), and MintPay (3M) in one screen.',
                  '**Best Value Badge:** The app automatically highlights which BNPL provider gives you the lowest total checkout cost.',
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 2: BNPL SHOPPING GUIDE (PROVIDERS & SURCHARGES)
  // ═════════════════════════════════════════════════════════════════════════════
  Widget _buildBnplShoppingGuideTab(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color primary,
  ) {
    final cardBg = AppTheme.card(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              _buildSectionHeader(context, 'Understanding BNPL in Sri Lanka'),
              const SizedBox(height: 12),
              _buildMainGuideCard(context, cardBg, textPrimary, textSecondary),
              const SizedBox(height: 24),
              _buildSectionHeader(context, 'Provider Policies & Details'),
              const SizedBox(height: 12),

              // Koko Guide Card
              _buildProviderGuideCard(
                context: context,
                title: 'Koko (by Daraz)',
                accentColor: const Color(0xFFFFB6C1),
                icon: Icons.shopping_bag_outlined,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                details: [
                  '⏱️ **Installment Period:** 3 months (standard) or 6 months (extended). First payment made immediately at checkout, subsequent payments every 30 days.',
                  '💰 **Processing Fee:** Defaults to 9% depending on the store. Some stores offer 0% promotional terms, but others pass their platform costs to buyers.',
                  '⚡ **Secondary Rate (10%):** Koko recently updated their 6-month secondary fee from 6% to **10%**. This rate is charged directly by Koko when spreading payments across 6 installments.',
                  '📈 **Limits:** Starting limits vary based on initial credit checks. Link your national ID and bank card in the Koko app to increase spending limits.',
                ],
              ),
              const SizedBox(height: 12),

              // PayZy Guide Card
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

              // MintPay Guide Card
              _buildProviderGuideCard(
                context: context,
                title: 'MintPay',
                accentColor: const Color(0xFF10B981),
                icon: Icons.eco_outlined,
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                details: [
                  '⏱️ **Installment Period:** 3 equal installments (1/3 today at checkout, 1/3 in 30 days, 1/3 in 60 days).',
                  '💰 **Processing Fee:** 0% on standard MintPay partner transactions. However, some independent merchants charge a manual fee.',
                  '⚠️ **Late Fees:** MintPay does not charge interest, but strict late penalty fees apply if card charges fail on scheduled due dates. Keep your cards funded!',
                ],
              ),
              const SizedBox(height: 24),
              _buildSurchargeTipsCard(context, textPrimary, textSecondary),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // UI WIDGET HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(BuildContext context, String title) {
    final textPrimary = AppTheme.textPrimary(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
      ),
    );
  }

  Widget _buildGuideStepCard({
    required BuildContext context,
    required String stepNumber,
    required String title,
    required IconData icon,
    required Color accentColor,
    required List<String> content,
  }) {
    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);

    return PixelCard(
      accentColor: accentColor,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    stepNumber,
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...content.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: _buildFormattedText(item, textPrimary, textSecondary),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMainGuideCard(
    BuildContext context,
    Color cardBg,
    Color textPrimary,
    Color textSecondary,
  ) {
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
                Icon(Icons.info_outline_rounded,
                    color: Theme.of(context).colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  'What is BNPL?',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Buy Now Pay Later (BNPL) lets you split purchase payments into installments. '
              'While the platforms advertise 0% interest, merchants and shops often add a processing '
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
          color: isDark
              ? accentColor.withValues(alpha: 0.15)
              : accentColor.withValues(alpha: 0.3),
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
          initiallyExpanded: true,
          leading: Icon(icon, color: accentColor, size: 24),
          title: Text(
            title,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textPrimary, fontSize: 16),
          ),
          iconColor: accentColor,
          collapsedIconColor:
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5E5E5E),
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

  Widget _buildSurchargeTipsCard(
      BuildContext context, Color textPrimary, Color textSecondary) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor =
        isDark ? Colors.amber.shade200 : Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.withValues(alpha: 0.06)
            : Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.amber.withValues(alpha: 0.15)
              : Colors.amber.withValues(alpha: 0.35),
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
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildTipRow(
              '🛒 Compare Store Prices:',
              'Some shops sell products cheaper but add high BNPL checkout fees. Compare the total checkout cost (Price + BNPL Fee) across different shops.',
              textPrimary,
              textSecondary),
          const SizedBox(height: 12),
          _buildTipRow(
              '🚚 Delivery Charges:',
              'Always verify if the shop has added shipping/handling to the checkout price. The "Find Shop Fee" calculator will calculate shipping as a fee if it is not subtracted first.',
              textPrimary,
              textSecondary),
          const SizedBox(height: 12),
          _buildTipRow(
              '💳 Credit Limit Checks:',
              'Always keep your primary debit or credit card funded. If a recurring monthly installment payment fails due to insufficient balance, the provider will charge you a hefty penalty fee.',
              textPrimary,
              textSecondary),
        ],
      ),
    );
  }

  Widget _buildTipRow(String title, String body, Color textPrimary,
      Color textSecondary) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                    fontSize: 13, color: textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedText(
      String text, Color textPrimary, Color textSecondary) {
    final RegExp regExp = RegExp(r'\*\*(.*?)\*\*');
    final List<TextSpan> spans = [];
    int start = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: TextStyle(color: textSecondary, fontSize: 13, height: 1.45),
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
            fontSize: 13,
            height: 1.45),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: TextStyle(color: textSecondary, fontSize: 13, height: 1.45),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}
