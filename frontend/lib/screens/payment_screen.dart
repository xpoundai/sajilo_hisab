import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../widgets/common.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _payType = 'received';
  String? _partyId;
  String _method = 'cash';
  String _category = 'normal';
  String? _bankId;
  String? _walletId;
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = context.read<DataProvider>();
      dp.loadParties();
      dp.loadBanks();
      dp.loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type
            Row(
              children: [
                Expanded(child: _typeBtn('Receive Payment', 'received', AppTheme.accentGreen, Icons.arrow_downward)),
                const SizedBox(width: 10),
                Expanded(child: _typeBtn('Make Payment', 'paid', AppTheme.errorRed, Icons.arrow_upward)),
              ],
            ),
            const SizedBox(height: 16),

            // Party
            DropdownButtonFormField<String>(
              value: _partyId,
              decoration: const InputDecoration(labelText: 'Select Party'),
              items: dp.parties.map<DropdownMenuItem<String>>((p) => DropdownMenuItem(value: p['id'].toString(), child: Text('${p['name']} (${p['type']})'))).toList(),
              onChanged: (v) => setState(() => _partyId = v),
            ),
            const SizedBox(height: 14),

            // Amount
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'Amount', prefixText: 'NPR ', labelStyle: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 14),

            // Category
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'normal', child: Text('Normal')),
                DropdownMenuItem(value: 'advance', child: Text('Advance')),
                DropdownMenuItem(value: 'credit_settlement', child: Text('Credit Settlement')),
              ],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),

            // Method
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Payment Method'),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Cash')),
                DropdownMenuItem(value: 'bank', child: Text('Bank')),
                DropdownMenuItem(value: 'cheque', child: Text('Cheque')),
                DropdownMenuItem(value: 'wallet', child: Text('Wallet')),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 10),

            if (_method == 'bank' || _method == 'cheque')
              DropdownButtonFormField<String>(
                value: _bankId,
                decoration: const InputDecoration(labelText: 'Select Bank'),
                items: dp.banks.map<DropdownMenuItem<String>>((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name'] ?? ''))).toList(),
                onChanged: (v) => setState(() => _bankId = v),
              ),
            if (_method == 'wallet')
              DropdownButtonFormField<String>(
                value: _walletId,
                decoration: const InputDecoration(labelText: 'Select Wallet'),
                items: dp.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem(value: w['id'].toString(), child: Text('${w['name']}'))).toList(),
                onChanged: (v) => setState(() => _walletId = v),
              ),
            const SizedBox(height: 14),

            TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 28),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving || _partyId == null ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: _payType == 'received' ? AppTheme.accentGreen : AppTheme.errorRed),
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Record Payment', style: const TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String label, String value, Color color, IconData icon) {
    final selected = _payType == value;
    return GestureDetector(
      onTap: () => setState(() => _payType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.cardBorder, width: selected ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppTheme.textLight, size: 22),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: selected ? color : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await context.read<DataProvider>().createPayment({
      'party_id': _partyId,
      'amount': _amountCtrl.text.trim(),
      'type': _payType,
      'method': _method,
      'bank_id': _bankId,
      'wallet_id': _walletId,
      'category': _category,
      'date': DateFormatter.today(),
      'notes': _notesCtrl.text.trim(),
    });
    setState(() => _saving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded!'), backgroundColor: AppTheme.accentGreen));
      context.pop();
    }
  }
}
