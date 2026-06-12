import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';
import 'firebase_service.dart';
import 'widgets/bounce_tap.dart';
import 'widgets/fade_in_item.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen>
    with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _installments = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final List<String> _providers = ['Koko', 'PayZy', 'MintPay'];
  final List<int> _payzyMonthsOptions = [2, 3, 4];
  final List<int> _kokoMonthsOptions = [3, 6];
  final List<int> _mintpayMonthsOptions = [3, 6, 9, 12];

  // FAB animation
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fabScale = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.elasticOut,
    );
    _loadInstallments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _loadInstallments() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('tracker_installments');
    if (data != null) {
      final List<dynamic> decoded = json.decode(data);
      _installments.clear();
      for (var item in decoded) {
        _installments.add(Map<String, dynamic>.from(item));
      }
    }
    setState(() => _isLoading = false);

    // Sync with Firestore in the background
    _syncToFirestore();

    // Animate FAB in after load
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _fabAnimController.forward();
    });
  }

  Future<void> _syncToFirestore() async {
    for (var inst in _installments) {
      await FirebaseService.saveInstallment(inst);
    }
  }

  Future<void> _saveInstallments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracker_installments', json.encode(_installments));
  }

  Future<void> _addInstallmentData({
    required GlobalKey<FormState> formKey,
    required String provider,
    required int months,
    required DateTime startDate,
    required VoidCallback closeSheet,
  }) async {
    if (!formKey.currentState!.validate()) return;

    final double amount = double.parse(_amountController.text);
    final String name = _nameController.text.trim();
    final int baseNotificationId =
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String id = baseNotificationId.toString();

    final bool firstIsPaid = provider == 'PayZy';
    final double installmentAmount = amount / months;
    final List<Map<String, dynamic>> payments = [];

    for (int i = 0; i < months; i++) {
      final DateTime paymentDate = DateTime(
        startDate.year,
        startDate.month + i,
        startDate.day,
      );
      payments.add({
        'installmentIndex': i + 1,
        'dueDate': _dateFormat.format(paymentDate),
        'amount': installmentAmount,
        'isPaid': i == 0 ? firstIsPaid : false,
      });
    }

    final installmentData = {
      'id': id,
      'name': name,
      'provider': provider,
      'totalAmount': amount,
      'months': months,
      'startDate': _dateFormat.format(startDate),
      'payments': payments,
    };

    setState(() {
      _installments.add(installmentData);
    });

    await _saveInstallments();
    await FirebaseService.saveInstallment(installmentData);

    _nameController.clear();
    _amountController.clear();
    closeSheet();
  }

  void _togglePaymentStatus(String installmentId, int index) {
    setState(() {
      final idx =
          _installments.indexWhere((item) => item['id'] == installmentId);
      if (idx != -1) {
        final payments =
            List<Map<String, dynamic>>.from(_installments[idx]['payments']);
        payments[index]['isPaid'] = !payments[index]['isPaid'];
        _installments[idx]['payments'] = payments;

        // Update Firestore
        FirebaseService.updatePaymentStatus(
          installmentId,
          index,
          payments[index]['isPaid'],
        );
      }
    });
    _saveInstallments();
  }

  void _deleteInstallment(String id) async {
    setState(() => _installments.removeWhere((item) => item['id'] == id));
    await _saveInstallments();
    await FirebaseService.deleteInstallment(id);
  }

  Color _getProviderColor(String provider) {
    switch (provider) {
      case 'Koko':
        return const Color(0xFFFFB6C1);
      case 'PayZy':
        return const Color(0xFF00AEEF);
      case 'MintPay':
        return const Color(0xFF10B981);
      default:
        return Colors.blue;
    }
  }

  void _showAddBottomSheet() {
    final localFormKey = GlobalKey<FormState>();
    String selectedProvider = 'Koko';
    int selectedMonths = 3;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final textPrimary = AppTheme.textPrimary(context);
            final textSecondary = AppTheme.textSecondary(context);

            Widget buildMonthsSelector(List<int> options, Color accentColor) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Installment Term (Months)',
                    style: TextStyle(
                        color: textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.map((months) {
                      final bool isSelected = selectedMonths == months;
                      return GestureDetector(
                        onTap: () =>
                            setSheetState(() => selectedMonths = months),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentColor.withValues(alpha: 0.15)
                                : AppTheme.cardAlt(context),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? accentColor
                                  : AppTheme.border(context),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$months Months',
                            style: TextStyle(
                              color: isSelected ? accentColor : textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                top: 24,
                left: 24,
                right: 24,
              ),
              child: Form(
                key: localFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sheet handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: AppTheme.border(context),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Track New Installment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.close, color: textSecondary),
                            onPressed: () {
                              _nameController.clear();
                              _amountController.clear();
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name field
                      TextFormField(
                        controller: _nameController,
                        style: TextStyle(
                            color: textPrimary, fontSize: 16),
                        decoration: AppTheme.inputDecoration(context,
                            hintText: 'e.g. iPhone 16 — Samsung'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      // Amount field
                      TextFormField(
                        controller: _amountController,
                        style: TextStyle(
                            color: textPrimary, fontSize: 16),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: AppTheme.inputDecoration(context,
                            hintText: 'e.g. 45000',
                            prefixText: 'Rs. '),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (double.tryParse(v) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Provider selector
                      Text(
                        'BNPL Provider',
                        style: TextStyle(
                            color: textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: _providers.map((provider) {
                          final bool isSelected =
                              selectedProvider == provider;
                          final Color color = _getProviderColor(provider);
                          return Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => setSheetState(() {
                                  selectedProvider = provider;
                                  selectedMonths = 3;
                                }),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  curve: Curves.easeOut,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.15)
                                        : AppTheme.cardAlt(context),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? color
                                          : AppTheme.border(context),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      provider,
                                      style: TextStyle(
                                        color: isSelected
                                            ? color
                                            : textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Months selector
                      if (selectedProvider == 'PayZy')
                        buildMonthsSelector(
                            _payzyMonthsOptions, _getProviderColor('PayZy'))
                      else if (selectedProvider == 'Koko')
                        buildMonthsSelector(
                            _kokoMonthsOptions, _getProviderColor('Koko'))
                      else if (selectedProvider == 'MintPay')
                        buildMonthsSelector(_mintpayMonthsOptions,
                            _getProviderColor('MintPay')),
                      // Date picker row
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.cardAlt(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border(context)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('1st Payment Date',
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  _dateFormat.format(selectedDate),
                                  style: TextStyle(
                                      color: textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                              ],
                            ),
                            BounceTap(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: sheetContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime(2032),
                                );
                                if (picked != null) {
                                  setSheetState(
                                      () => selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary(context),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusPill),
                                ),
                                child: const Text('Pick Date',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => _addInstallmentData(
                            formKey: localFormKey,
                            provider: selectedProvider,
                            months: selectedMonths,
                            startDate: selectedDate,
                            closeSheet: () => Navigator.pop(sheetContext),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary(context),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusPill),
                            ),
                          ),
                          child: const Text('Save to Tracker',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppTheme.textPrimary(context);

    return Scaffold(
      backgroundColor: AppTheme.surface(context),
      appBar: AppBar(
        title: Text('Installment Manager',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: textPrimary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: _showAddBottomSheet,
          backgroundColor: AppTheme.primary(context),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary(context),
                strokeWidth: 2,
              ),
            )
          : _installments.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: _installments.length,
                  itemBuilder: (context, index) {
                    final item = _installments[index];
                    return FadeInItem(
                      delay: Duration(milliseconds: index * 60),
                      child: _buildInstallmentCard(context, item),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final primary = AppTheme.primary(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.iconBg(context, primary),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined,
                  size: 56, color: primary),
            ),
            const SizedBox(height: 24),
            Text(
              'No Tracked Installments',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context)),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button below to start tracking and managing your buy-now-pay-later purchases.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary(context)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentCard(
      BuildContext context, Map<String, dynamic> item) {
    final String id = item['id'];
    final String name = item['name'];
    final String provider = item['provider'];
    final double totalAmount = item['totalAmount'];
    final List<dynamic> payments = item['payments'];
    final Color providerColor = _getProviderColor(provider);

    final int paidCount =
        payments.where((p) => p['isPaid'] == true).length;
    final int totalCount = payments.length;
    final double progress = totalCount > 0 ? paidCount / totalCount : 0;
    final bool isComplete = progress == 1.0;

    final textPrimary = AppTheme.textPrimary(context);
    final textSecondary = AppTheme.textSecondary(context);
    final primary = AppTheme.primary(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.cardDecoration(context, accentBorder: providerColor),
      clipBehavior: Clip.hardEdge,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          collapsedIconColor: AppTheme.textHint(context),
          iconColor: primary,
          title: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: providerColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: providerColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  provider,
                  style: TextStyle(
                      color: providerColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                      fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _currencyFormat.format(totalAmount),
                    style: TextStyle(
                        color: textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15),
                  ),
                  Text(
                    '$paidCount/$totalCount Paid',
                    style: TextStyle(
                        color: isComplete
                            ? const Color(0xFF10B981)
                            : textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    backgroundColor: AppTheme.cardAlt(context),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isComplete
                          ? const Color(0xFF10B981)
                          : primary,
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          children: [
            Divider(height: 1, color: AppTheme.border(context)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ...List.generate(payments.length, (index) {
                    final pay = payments[index];
                    final bool isPaid = pay['isPaid'];
                    final double payAmt = pay['amount'];
                    final String dueDate = pay['dueDate'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7.0),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: isPaid,
                                  activeColor: const Color(0xFF10B981),
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                      color: AppTheme.border(context),
                                      width: 1.5),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(4)),
                                  onChanged: (_) =>
                                      _togglePaymentStatus(id, index),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Installment ${pay['installmentIndex']}',
                                    style: TextStyle(
                                      color: isPaid
                                          ? AppTheme.textHint(context)
                                          : textPrimary,
                                      decoration: isPaid
                                          ? TextDecoration.lineThrough
                                          : null,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Due: $dueDate',
                                    style: TextStyle(
                                        color:
                                            AppTheme.textSecondary(context),
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            _currencyFormat.format(payAmt),
                            style: TextStyle(
                              color: isPaid
                                  ? AppTheme.textHint(context)
                                  : textPrimary,
                              fontWeight: FontWeight.bold,
                              decoration: isPaid
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  Divider(height: 1, color: AppTheme.border(context)),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _deleteInstallment(id),
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      label: const Text('Delete',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
