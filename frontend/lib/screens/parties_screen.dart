import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../widgets/common.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  String _filter = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<DataProvider>().loadParties());
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final parties = dp.parties;

    final totalReceivable = parties.fold<double>(0, (s, p) {
      final b = double.tryParse(p['balance']?.toString() ?? '0') ?? 0;
      return s + (b > 0 ? b : 0);
    });
    final totalPayable = parties.fold<double>(0, (s, p) {
      final b = double.tryParse(p['balance']?.toString() ?? '0') ?? 0;
      return s + (b < 0 ? b.abs() : 0);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Parties')),
      body: RefreshIndicator(
        onRefresh: () => dp.loadParties(type: _filter.isEmpty ? null : _filter, search: _searchCtrl.text),
        child: dp.partiesLoading
            ? const LoadingWidget()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Stats
                  Row(
                    children: [
                      Expanded(child: StatCard(title: 'Receivable', value: CurrencyFormatter.compact(totalReceivable), icon: Icons.arrow_downward, color: AppTheme.accentGreen)),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(title: 'Payable', value: CurrencyFormatter.compact(totalPayable), icon: Icons.arrow_upward, color: AppTheme.errorRed)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search parties...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => dp.loadParties(search: v, type: _filter.isEmpty ? null : _filter),
                  ),
                  const SizedBox(height: 10),

                  // Filter
                  Row(
                    children: [
                      _chip('All', ''),
                      _chip('Customers', 'customer'),
                      _chip('Vendors', 'vendor'),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (parties.isEmpty)
                    const EmptyWidget(message: 'No parties yet')
                  else
                    ...parties.map((p) => _partyCard(p)),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/parties/add'),
        child: const Icon(Icons.person_add),
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
          context.read<DataProvider>().loadParties(type: value.isEmpty ? null : value);
        },
      ),
    );
  }

  Widget _partyCard(Map<String, dynamic> party) {
    final balance = double.tryParse(party['balance']?.toString() ?? '0') ?? 0;
    final isReceivable = balance > 0;
    final advance = double.tryParse(party['advance_balance']?.toString() ?? '0') ?? 0;

    return GestureDetector(
      onTap: () => context.push('/parties/${party['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: party['type'] == 'customer' ? AppTheme.accentGreen.withOpacity(0.15) : AppTheme.primaryBlue.withOpacity(0.15),
              radius: 22,
              child: Icon(
                party['type'] == 'customer' ? Icons.person : Icons.store,
                color: party['type'] == 'customer' ? AppTheme.accentGreen : AppTheme.primaryBlue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (party['name'] ?? '').length > 18 
                            ? '${(party['name'] ?? '').substring(0, 18)}...' 
                            : (party['name'] ?? ''),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: party['type'] == 'customer' ? 'Customer' : 'Vendor',
                        color: party['type'] == 'customer' ? AppTheme.accentGreen : AppTheme.primaryBlue,
                      ),
                    ],
                  ),
                  if (party['phone']?.toString().isNotEmpty == true)
                    PhoneLink(phone: party['phone'], style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  if (advance > 0)
                    Text('Advance: ${CurrencyFormatter.format(advance)}', style: const TextStyle(fontSize: 12, color: AppTheme.warningYellow)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(balance.abs()),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isReceivable ? AppTheme.accentGreen : AppTheme.errorRed,
                  ),
                ),
                Text(
                  isReceivable ? 'Receivable' : (balance < 0 ? 'Payable' : 'Settled'),
                  style: TextStyle(fontSize: 11, color: isReceivable ? AppTheme.accentGreen : AppTheme.errorRed),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Add Party ─────────────────────────────────
class AddPartyScreen extends StatefulWidget {
  const AddPartyScreen({super.key});

  @override
  State<AddPartyScreen> createState() => _AddPartyScreenState();
}

class _AddPartyScreenState extends State<AddPartyScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _creditLimitCtrl = TextEditingController(text: '0');
  final _openingBalanceCtrl = TextEditingController(text: '0');
  String _type = 'customer';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Party')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            Row(
              children: [
                Expanded(child: _typeBtn('Customer', 'customer', AppTheme.accentGreen)),
                const SizedBox(width: 10),
                Expanded(child: _typeBtn('Vendor', 'vendor', AppTheme.primaryBlue)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.person_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email (optional)', prefixIcon: Icon(Icons.email_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.location_on_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _gstinCtrl, decoration: const InputDecoration(labelText: 'PAN/VAT Number', prefixIcon: Icon(Icons.badge_outlined))),
            const SizedBox(height: 14),
            TextField(controller: _creditLimitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Limit (NPR)', prefixText: 'NPR ')),
            const SizedBox(height: 14),
            TextField(controller: _openingBalanceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Balance', prefixText: 'NPR ')),
            const SizedBox(height: 28),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Party', style: TextStyle(fontSize: 17)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn(String label, String value, Color color) {
    final selected = _type == value;
    return GestureDetector(
      onTap: () => setState(() => _type = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : AppTheme.cardBorder, width: selected ? 2 : 1),
        ),
        child: Center(child: Text(label, style: TextStyle(color: selected ? color : AppTheme.textSecondary, fontWeight: FontWeight.w600, fontSize: 15))),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final success = await context.read<DataProvider>().createParty({
      'name': _nameCtrl.text.trim(),
      'type': _type,
      'phone': _phoneCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'gstin': _gstinCtrl.text.trim(),
      'credit_limit': _creditLimitCtrl.text.trim(),
      'opening_balance': _openingBalanceCtrl.text.trim(),
    });
    setState(() => _saving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Party saved!'), backgroundColor: AppTheme.accentGreen));
      context.pop();
    }
  }
}

// ─── Party Detail ─────────────────────────────────
class PartyDetailScreen extends StatefulWidget {
  final String partyId;
  const PartyDetailScreen({super.key, required this.partyId});

  @override
  State<PartyDetailScreen> createState() => _PartyDetailScreenState();
}

class _PartyDetailScreenState extends State<PartyDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<DataProvider>().getPartyLedger(widget.partyId);
    setState(() {
      _data = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final party = _data?['party'] as Map<String, dynamic>? ?? {};
    final ledger = _data?['ledger'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(party['name'] ?? 'Party Details')),
      body: _loading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(party['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            StatusBadge(label: party['type'] ?? '', color: party['type'] == 'customer' ? AppTheme.accentGreen : AppTheme.primaryBlue),
                          ],
                        ),
                        if (party['phone']?.toString().isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          PhoneLink(phone: party['phone'].toString(), style: const TextStyle(color: AppTheme.textSecondary)),
                        ],
                        if (party['address']?.toString().isNotEmpty == true) ...[
                          const SizedBox(height: 2),
                          Text('📍 ${party['address']}', style: const TextStyle(color: AppTheme.textSecondary)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Balance cards
                  Row(
                    children: [
                      Expanded(child: StatCard(title: 'Balance', value: CurrencyFormatter.format(party['balance']), icon: Icons.account_balance_wallet, color: (double.tryParse(party['balance']?.toString() ?? '0') ?? 0) >= 0 ? AppTheme.accentGreen : AppTheme.errorRed)),
                      const SizedBox(width: 10),
                      Expanded(child: StatCard(title: 'Total Business', value: CurrencyFormatter.compact(party['total_business']), icon: Icons.trending_up, color: AppTheme.primaryBlue)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Ledger
                  const Text('Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Debit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text('Credit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),

                  if (ledger.isEmpty)
                    const Padding(padding: EdgeInsets.all(24), child: Center(child: Text('No ledger entries')))
                  else
                    ...ledger.map((entry) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.divider))),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(DateFormatter.formatShort(entry['date']?.toString()), style: const TextStyle(fontSize: 11))),
                          Expanded(flex: 2, child: Text(entry['type'] ?? '', style: const TextStyle(fontSize: 11))),
                          Expanded(flex: 2, child: Text(entry['debit']?.toString() == '0.00' ? '-' : CurrencyFormatter.compact(entry['debit']), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text(entry['credit']?.toString() == '0.00' ? '-' : CurrencyFormatter.compact(entry['credit']), style: const TextStyle(fontSize: 11), textAlign: TextAlign.right)),
                          Expanded(flex: 2, child: Text(CurrencyFormatter.compact(entry['balance']), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: (double.tryParse(entry['balance']?.toString() ?? '0') ?? 0) >= 0 ? AppTheme.accentGreen : AppTheme.errorRed), textAlign: TextAlign.right)),
                        ],
                      ),
                    )),
                ],
              ),
            ),
    );
  }
}
