import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../widgets/common.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _filter = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DataProvider>().loadTransactions());
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final txns = dp.transactions;

    final totalSales = txns.where((t) => t['type'] == 'sale').fold<double>(0, (s, t) => s + (double.tryParse(t['total']?.toString() ?? '0') ?? 0));
    final totalPurchases = txns.where((t) => t['type'] == 'purchase').fold<double>(0, (s, t) => s + (double.tryParse(t['total']?.toString() ?? '0') ?? 0));

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      body: RefreshIndicator(
        onRefresh: () => dp.loadTransactions(type: _filter.isEmpty ? null : _filter),
        child: dp.transactionsLoading
            ? const LoadingWidget()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(children: [
                          Text(CurrencyFormatter.compact(totalSales), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Total Sales', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        ]),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.3)),
                        Column(children: [
                          Text(CurrencyFormatter.compact(totalPurchases), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Total Purchases', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Filters
                  Row(
                    children: [
                      _chip('All', ''),
                      _chip('Sales', 'sale'),
                      _chip('Purchases', 'purchase'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (txns.isEmpty)
                    const EmptyWidget(message: 'No transactions yet')
                  else
                    ...txns.map((t) => _txnCard(t)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/transactions/create'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _chip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.primaryBlue.withOpacity(0.15),
        onSelected: (_) {
          setState(() => _filter = value);
          context.read<DataProvider>().loadTransactions(type: value.isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _txnCard(Map<String, dynamic> txn) {
    final isSale = txn['type'] == 'sale';
    final total = double.tryParse(txn['total']?.toString() ?? '0') ?? 0;
    final paid = double.tryParse(txn['paid']?.toString() ?? '0') ?? 0;
    final due = total - paid;
    final items = txn['items'] as List? ?? [];

    Color statusColor;
    switch (txn['status']) {
      case 'paid':
        statusColor = AppTheme.accentGreen;
        break;
      case 'partial':
        statusColor = AppTheme.warningYellow;
        break;
      case 'advance':
        statusColor = AppTheme.primaryBlue;
        break;
      default:
        statusColor = AppTheme.errorRed;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSale ? Icons.shopping_cart : Icons.inventory_2, color: isSale ? AppTheme.accentGreen : AppTheme.primaryBlue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (txn['party_name'] ?? '').length > 18 
                    ? '${(txn['party_name'] ?? '').substring(0, 18)}...' 
                    : (txn['party_name'] ?? ''),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                CurrencyFormatter.format(total),
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isSale ? AppTheme.accentGreen : AppTheme.errorRed),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(DateFormatter.format(txn['date']?.toString()), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 8),
              Text('${items.length} item${items.length == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const Spacer(),
              StatusBadge(label: txn['status']?.toString().toUpperCase() ?? '', color: statusColor),
              const SizedBox(width: 6),
              StatusBadge(label: (txn['payment_method'] ?? 'cash').toString().toUpperCase(), color: AppTheme.primaryBlue),
            ],
          ),
          if (due > 0) ...[
            const SizedBox(height: 4),
            Text('Due: ${CurrencyFormatter.format(due)}', style: const TextStyle(fontSize: 12, color: AppTheme.warningYellow, fontWeight: FontWeight.w600)),
          ],
        ],
      ),
    );
  }
}

// ─── Create Transaction ─────────────────────────
class CreateTransactionScreen extends StatefulWidget {
  final String? initialType;
  const CreateTransactionScreen({super.key, this.initialType});

  @override
  State<CreateTransactionScreen> createState() => _CreateTransactionScreenState();
}

class _CreateTransactionScreenState extends State<CreateTransactionScreen> {
  late String _type;
  String? _partyId;
  String _method = 'cash';
  String? _bankId;
  String? _walletId;
  final _paidCtrl = TextEditingController(text: '0');
  final _notesCtrl = TextEditingController();
  final List<Map<String, dynamic>> _txnItems = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? 'sale';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = context.read<DataProvider>();
      dp.loadParties();
      dp.loadItems();
      dp.loadBanks();
      dp.loadWallets();
    });
  }

  double get _total => _txnItems.fold(0, (s, i) => s + (i['total'] as double));

  String get _statusPreview {
    final paid = double.tryParse(_paidCtrl.text) ?? 0;
    if (paid > _total) return 'ADVANCE';
    if (paid >= _total) return 'PAID';
    if (paid > 0) return 'PARTIAL';
    return 'CREDIT';
  }

  Color get _statusColor {
    switch (_statusPreview) {
      case 'PAID': return AppTheme.accentGreen;
      case 'PARTIAL': return AppTheme.warningYellow;
      case 'ADVANCE': return AppTheme.primaryBlue;
      default: return AppTheme.errorRed;
    }
  }

  bool get _canSave {
    if (_saving || _txnItems.isEmpty) return false;
    if (_type == 'purchase' && _partyId == null) return false;
    if (_partyId == null) {
      final paid = double.tryParse(_paidCtrl.text.trim()) ?? 0;
      if (paid < _total) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final parties = dp.parties.where((p) => _type == 'sale' ? p['type'] == 'customer' : p['type'] == 'vendor').toList();

    return Scaffold(
      appBar: AppBar(title: Text('New ${_type == 'sale' ? 'Sale' : 'Purchase'}')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Type toggle
                  Row(
                    children: [
                      Expanded(child: _typeBtn('Sale', 'sale', AppTheme.accentGreen)),
                      const SizedBox(width: 10),
                      Expanded(child: _typeBtn('Purchase', 'purchase', AppTheme.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Party selector
                  DropdownButtonFormField<String?>(
                    value: _partyId,
                    decoration: const InputDecoration(labelText: 'Select Party'),
                    items: [
                      if (_type == 'sale') const DropdownMenuItem(value: null, child: Text('Walk-in (No Party)')),
                      ...parties.map<DropdownMenuItem<String?>>((p) => DropdownMenuItem(value: p['id'].toString(), child: Text(p['name'] ?? ''))),
                    ],
                    onChanged: (v) => setState(() => _partyId = v),
                  ),
                  const SizedBox(height: 14),

                  // Items header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      TextButton.icon(
                        onPressed: _showAddItemDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                      ),
                    ],
                  ),
                  
                  // Items list with constrained height
                  if (_txnItems.isNotEmpty)
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _txnItems.length,
                        itemBuilder: (context, index) {
                          final item = _txnItems[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white, 
                              border: Border.all(color: AppTheme.cardBorder), 
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryBlue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Center(child: Icon(Icons.inventory_2_outlined, color: AppTheme.primaryBlue, size: 20)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'].toString(), 
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), 
                                        maxLines: 2, 
                                        overflow: TextOverflow.ellipsis
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${item['quantity']} × ${CurrencyFormatter.format(item['rate'])}', 
                                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      CurrencyFormatter.format(item['total']), 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () => setState(() => _txnItems.removeAt(index)),
                                      child: const Text('Remove', style: TextStyle(fontSize: 12, color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  if (_txnItems.isNotEmpty) ...[
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Grand Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(CurrencyFormatter.format(_total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Payment Section - Fixed with proper container
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payment Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Amount Paid', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: _paidCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'NPR',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Quick Actions', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accentGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: _txnItems.isNotEmpty && _total > 0
                                              ? () {
                                                  setState(() => _paidCtrl.text = _total.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), ''));
                                                }
                                              : null,
                                          child: const Text('Full', style: TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                          onPressed: _txnItems.isNotEmpty && _total > 0
                                              ? () {
                                                  setState(() => _paidCtrl.text = '0');
                                                }
                                              : null,
                                          child: const Text('Clear', style: TextStyle(fontSize: 13)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Status preview
                        if (_txnItems.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: _statusColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Status: ${_statusPreview}',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _statusColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Payment method
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

                  // Dynamic sub-selection
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
                      items: dp.wallets.map<DropdownMenuItem<String>>((w) => DropdownMenuItem(value: w['id'].toString(), child: Text('${w['name']} (${w['phone']})'))).toList(),
                      onChanged: (v) => setState(() => _walletId = v),
                    ),
                  const SizedBox(height: 14),

                  TextField(controller: _notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Notes (optional)')),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Transaction', style: TextStyle(fontSize: 17)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBtn(String label, String value, Color color) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() { _type = value; _partyId = null; _txnItems.clear(); }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.cardBorder, width: selected ? 2 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? color : AppTheme.textSecondary, fontWeight: FontWeight.w600))),
      ),
    );
  }

  void _showAddItemDialog() {
    final dp = context.read<DataProvider>();
    String? selectedItemId;
    final qtyCtrl = TextEditingController(text: '1');
    final rateCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: selectedItemId,
                decoration: const InputDecoration(labelText: 'Select Item'),
                items: dp.items.map<DropdownMenuItem<String>>((i) => DropdownMenuItem(value: i['id'].toString(), child: Text(i['name'] ?? ''))).toList(),
                onChanged: (v) {
                  setModalState(() => selectedItemId = v);
                  final item = dp.items.firstWhere((i) => i['id'].toString() == v);
                  rateCtrl.text = _type == 'sale' ? (item['selling_price']?.toString() ?? '0') : (item['cost_price']?.toString() ?? '0');
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity')),
              const SizedBox(height: 12),
              TextField(controller: rateCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate (NPR)', prefixText: 'NPR ')),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectedItemId == null) return;
                        final item = dp.items.firstWhere((i) => i['id'].toString() == selectedItemId);
                        final qty = double.tryParse(qtyCtrl.text) ?? 0;
                        final rate = double.tryParse(rateCtrl.text) ?? 0;
                        if (qty > 0 && rate > 0) {
                          setState(() => _txnItems.add({
                            'item_id': selectedItemId,
                            'name': item['name'],
                            'quantity': qty,
                            'rate': rate,
                            'total': qty * rate,
                          }));
                        }
                        Navigator.pop(ctx);
                      },
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await context.read<DataProvider>().createTransaction({
      'type': _type,
      'party_id': _partyId,
      'items': _txnItems.map((i) => {'item_id': i['item_id'], 'quantity': i['quantity'], 'rate': i['rate']}).toList(),
      'paid': _paidCtrl.text.trim(),
      'payment_method': _method,
      'bank_id': _bankId,
      'wallet_id': _walletId,
      'date': DateFormatter.today(),
      'notes': _notesCtrl.text.trim(),
    });
    setState(() => _saving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction saved!'), backgroundColor: AppTheme.accentGreen));
      context.pop();
    }
  }
}