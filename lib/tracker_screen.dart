import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_settings.dart';
import 'notification_helper.dart';

class TrackerScreen extends StatefulWidget {
  const TrackerScreen({super.key});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  final List<Map<String, dynamic>> _installments = [];
  bool _isLoading = true;

  final _nameController = TextEditingController();
  final _amountController = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'en_LK', symbol: 'Rs. ');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  final List<String> _providers = ['Koko', 'PayZy', 'MintPay'];
  final List<int> _payzyMonthsOptions = [2, 3, 4];
  final List<int> _kokoMonthsOptions = [3, 6];
  final List<int> _mintpayMonthsOptions = [3, 6, 9, 12];

  @override
  void initState() {
    super.initState();
    _loadInstallments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
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
    final int baseNotificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final String id = baseNotificationId.toString();

    // For PayZy, the first installment is paid at checkout. For Koko/MintPay all start unpaid.
    final bool firstIsPaid = provider == 'PayZy';

    // Generate individual payment dates and status
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

      // Schedule notifications (skip index 0 for PayZy since it's already paid)
      final bool shouldNotify = firstIsPaid ? i > 0 : true;
      if (shouldNotify) {
        try {
          // Read user notification preferences from AppSettings
          final settings = context.read<AppSettings>();
          await NotificationHelper.scheduleNotification(
            id: baseNotificationId + i,
            title: 'Upcoming $name Payment',
            body: 'Your installment ${i + 1} of ${_currencyFormat.format(installmentAmount)} with $provider is due in ${settings.notificationLeadDays} day${settings.notificationLeadDays > 1 ? 's' : ''}.',
            scheduledDate: paymentDate,
            notificationsEnabled: settings.notificationsEnabled,
            leadDays: settings.notificationLeadDays,
          );
        } catch (_) {
          // Notification scheduling failed (e.g. permission denied) — continue saving
        }
      }
    }

    setState(() {
      _installments.add({
        'id': id,
        'name': name,
        'provider': provider,
        'totalAmount': amount,
        'months': months,
        'startDate': _dateFormat.format(startDate),
        'payments': payments,
      });
    });

    await _saveInstallments();

    // Reset controllers
    _nameController.clear();
    _amountController.clear();

    // Close the bottom sheet using its own context
    closeSheet();
  }

  void _togglePaymentStatus(String installmentId, int index) {
    setState(() {
      final idx = _installments.indexWhere((item) => item['id'] == installmentId);
      if (idx != -1) {
        final payments = List<Map<String, dynamic>>.from(_installments[idx]['payments']);
        payments[index]['isPaid'] = !payments[index]['isPaid'];
        _installments[idx]['payments'] = payments;
      }
    });
    _saveInstallments();
  }

  void _deleteInstallment(String id) async {
    // Always remove from UI first so delete feels instant
    setState(() {
      _installments.removeWhere((item) => item['id'] == id);
    });
    await _saveInstallments();

    // Attempt to cancel notifications — failure here should not block the delete
    try {
      final int baseId = int.tryParse(id) ?? 0;
      // We don't know total months anymore since we already removed it,
      // so we cancel a wide range (max 12) to be safe
      for (int i = 0; i < 12; i++) {
        await NotificationHelper.cancelNotification(baseId + i);
      }
    } catch (_) {
      // Notification cancel failed — item is already deleted from UI and storage
    }
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
    // All sheet state is local to avoid GlobalKey re-use bugs
    final localFormKey = GlobalKey<FormState>();
    String selectedProvider = 'Koko';
    int selectedMonths = 3;
    DateTime selectedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1F2937),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Widget buildMonthsSelector(List<int> options, Color accentColor) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Installment Term (Months)',
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: options.map((months) {
                      final bool isSelected = selectedMonths == months;
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedMonths = months),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? accentColor.withValues(alpha: 0.15) : const Color(0xFF111827),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? accentColor : const Color(0xFF374151),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '$months Months',
                            style: TextStyle(
                              color: isSelected ? accentColor : Colors.white,
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
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Track New Installment',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              _nameController.clear();
                              _amountController.clear();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Item Name / Shop',
                          labelStyle: const TextStyle(color: Colors.grey),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF374151)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                        validator: (value) => (value == null || value.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _amountController,
                        style: const TextStyle(color: Colors.white),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Total Purchase Amount (LKR)',
                          labelStyle: const TextStyle(color: Colors.grey),
                          prefixText: 'Rs. ',
                          prefixStyle: const TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF374151)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Enter a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Provider Select
                      const Text(
                        'BNPL Provider',
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _providers.map((provider) {
                          final bool isSelected = selectedProvider == provider;
                          final Color color = _getProviderColor(provider);
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: InkWell(
                                onTap: () {
                                  setSheetState(() {
                                    selectedProvider = provider;
                                    // Reset to default months for new provider
                                    if (provider == 'PayZy') {
                                      selectedMonths = 3;
                                    } else if (provider == 'Koko') {
                                      selectedMonths = 3;
                                    } else if (provider == 'MintPay') {
                                      selectedMonths = 3;
                                    }
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? color.withValues(alpha: 0.15) : const Color(0xFF111827),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected ? color : const Color(0xFF374151),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      provider,
                                      style: TextStyle(
                                        color: isSelected ? color : Colors.white,
                                        fontWeight: FontWeight.bold,
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
                        buildMonthsSelector(_payzyMonthsOptions, Colors.blue)
                      else if (selectedProvider == 'Koko')
                        buildMonthsSelector(_kokoMonthsOptions, _getProviderColor('Koko'))
                      else if (selectedProvider == 'MintPay')
                        buildMonthsSelector(_mintpayMonthsOptions, _getProviderColor('MintPay')),
                      // 1st Payment Date Picker
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('1st Payment Date', style: TextStyle(color: Colors.grey, fontSize: 14)),
                        subtitle: Text(
                          _dateFormat.format(selectedDate),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2032),
                            );
                            if (picked != null) {
                              setSheetState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                          child: const Text('Select'),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _addInstallmentData(
                          formKey: localFormKey,
                          provider: selectedProvider,
                          months: selectedMonths,
                          startDate: selectedDate,
                          closeSheet: () => Navigator.pop(context),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save to Tracker', style: TextStyle(fontWeight: FontWeight.bold)),
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
    final isDark = context.watch<AppSettings>().isDarkMode;
    final bg = isDark ? const Color(0xFF111827) : const Color(0xFFF3F4F6);
    final appBarBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final appBarFg = isDark ? Colors.white : const Color(0xFF111827);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Installment Manager', style: TextStyle(color: appBarFg)),
        backgroundColor: appBarBg,
        elevation: 0,
        iconTheme: IconThemeData(color: appBarFg),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBottomSheet,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _installments.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _installments.length,
                  itemBuilder: (context, index) {
                    final item = _installments[index];
                    return _buildInstallmentCard(item);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1F2937),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Tracked Installments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button below to start tracking and managing your buy-now-pay-later purchases.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentCard(Map<String, dynamic> item) {
    final String id = item['id'];
    final String name = item['name'];
    final String provider = item['provider'];
    final double totalAmount = item['totalAmount'];
    final List<dynamic> payments = item['payments'];
    final Color providerColor = _getProviderColor(provider);

    final int paidCount = payments.where((p) => p['isPaid'] == true).length;
    final int totalCount = payments.length;
    final double progress = paidCount / totalCount;

    final isDark = context.read<AppSettings>().isDarkMode;
    final cardBg = isDark ? const Color(0xFF1F2937) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Card(
      color: cardBg,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cardBorder, width: 1),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        collapsedIconColor: Colors.grey,
        iconColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: providerColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: providerColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                provider,
                style: TextStyle(color: providerColor, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
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
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '$paidCount/$totalCount Paid',
                  style: TextStyle(color: progress == 1.0 ? Colors.green : Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFF111827),
                valueColor: AlwaysStoppedAnimation<Color>(progress == 1.0 ? Colors.green : Colors.blue),
                minHeight: 6,
              ),
            ),
          ],
        ),
        children: [
          const Divider(color: Color(0xFF374151), height: 1),
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
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isPaid,
                              activeColor: Colors.green,
                              checkColor: Colors.black,
                              onChanged: (val) => _togglePaymentStatus(id, index),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Installment ${pay['installmentIndex']}',
                                  style: TextStyle(
                                    color: isPaid ? Colors.grey : Colors.white,
                                    decoration: isPaid ? TextDecoration.lineThrough : null,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'Due: $dueDate',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Text(
                          _currencyFormat.format(payAmt),
                          style: TextStyle(
                            color: isPaid ? Colors.grey : Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: isPaid ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _deleteInstallment(id),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                    label: const Text('Delete Tracker', style: TextStyle(color: Colors.redAccent)),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
