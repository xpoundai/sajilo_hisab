import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                  child: Text(
                    auth.userName.isNotEmpty ? auth.userName[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(auth.userName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                      Row(
                        children: [
                          StatusBadge(label: auth.userRole.toUpperCase(), color: AppTheme.primaryBlue),
                          if (auth.businessPlan.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            StatusBadge(label: auth.businessPlan.toUpperCase(), color: AppTheme.accentGreen),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(auth.businessName, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Business
          const Text('Business', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          _settingsItem(context, Icons.bar_chart, 'Reports & Analytics', () => context.push('/reports')),
          _settingsItem(context, Icons.account_balance, 'Banks & Wallets', () => context.push('/banks')),
          if (auth.hasPermission('manage_users'))
            _settingsItem(context, Icons.people_outline, 'Manage Users', () => context.push('/users')),
          const SizedBox(height: 20),

          // App Settings
          const Text('App Settings', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          _settingsItem(context, Icons.language, 'Language', () {}, trailing: 'English'),
          _settingsItem(context, Icons.info_outline, 'About Sajilo Hisab', () {}),
          const SizedBox(height: 20),

          // Account
          const Text('Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppTheme.errorRed),
              title: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed, fontWeight: FontWeight.w600)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Sign Out'),
                    content: const Text('Are you sure you want to sign out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sign Out', style: TextStyle(color: AppTheme.errorRed))),
                    ],
                  ),
                );
                if (confirm == true && context.mounted) {
                  await auth.logout();
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 24),
          const Center(child: Text('Sajilo Hisab v1.0.0', style: TextStyle(fontSize: 12, color: AppTheme.textLight))),
        ],
      ),
    );
  }

  Widget _settingsItem(BuildContext context, IconData icon, String label, VoidCallback onTap, {String? trailing}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryBlue, size: 22),
        title: Text(label, style: const TextStyle(fontSize: 15)),
        trailing: trailing != null
            ? Text(trailing, style: const TextStyle(color: AppTheme.textSecondary))
            : const Icon(Icons.chevron_right, color: AppTheme.textLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}

// ─── Banks & Wallets ─────────────────────────────
class BanksScreen extends StatefulWidget {
  const BanksScreen({super.key});

  @override
  State<BanksScreen> createState() => _BanksScreenState();
}

class _BanksScreenState extends State<BanksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadBanks();
      context.read<DataProvider>().loadWallets();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final auth = context.watch<AuthProvider>();
    final canManageBanks = auth.hasPermission('manage_banks');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banks & Wallets'),
        actions: [
          if (auth.hasPermission('manage_banks'))
            IconButton(
              icon: const Icon(Icons.sync_alt),
              tooltip: 'Transfer Funds',
              onPressed: () => _showTransferFundsDialog(),
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Banks'), Tab(text: 'Wallets')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // Banks
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...dp.banks.map((b) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.account_balance, color: AppTheme.primaryBlue, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(b['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        Text('A/C: ****${(b['account_number'] ?? '').toString().length > 4 ? (b['account_number']).toString().substring((b['account_number']).toString().length - 4) : b['account_number']}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ]),
                    ),
                    Text(CurrencyFormatter.format(b['balance']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.primaryBlue)),
                    if (canManageBanks)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                        onSelected: (action) {
                          if (action == 'edit') {
                            _showEditBankDialog(b);
                          } else if (action == 'delete') {
                            _showDeleteBankDialog(b);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                        ],
                      ),
                  ],
                ),
              )),
              const SizedBox(height: 10),
              if (canManageBanks)
                OutlinedButton.icon(
                  onPressed: () => _showAddBankDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Bank'),
                ),
            ],
          ),
          // Wallets
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...dp.wallets.map((w) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppTheme.accentGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.wallet, color: AppTheme.accentGreen, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(w['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                        PhoneLink(phone: w['phone'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        if (w['linked_bank_name']?.toString().isNotEmpty == true)
                          Text('🔗 ${w['linked_bank_name']}', style: const TextStyle(fontSize: 11, color: AppTheme.primaryBlue)),
                      ]),
                    ),
                    Text(CurrencyFormatter.format(w['balance']), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.accentGreen)),
                    if (canManageBanks)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                        onSelected: (action) {
                          if (action == 'edit') {
                            _showEditWalletDialog(w);
                          } else if (action == 'delete') {
                            _showDeleteWalletDialog(w);
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppTheme.errorRed))),
                        ],
                      ),
                  ],
                ),
              )),
              const SizedBox(height: 10),
              if (canManageBanks)
                OutlinedButton.icon(
                  onPressed: () => _showAddWalletDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Wallet'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDeleteBankDialog(Map<String, dynamic> bank) {
    String settleTo = 'discard';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Delete Bank'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete ${bank['name']}?'),
              if (double.parse(bank['balance'].toString()) > 0) ...[
                const SizedBox(height: 16),
                const Text('How to settle remaining balance?', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile(
                  title: const Text('Discard Balance'),
                  value: 'discard',
                  groupValue: settleTo,
                  onChanged: (v) => setState(() => settleTo = v.toString()),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile(
                  title: const Text('Transfer to Cash Book'),
                  value: 'cash',
                  groupValue: settleTo,
                  onChanged: (v) => setState(() => settleTo = v.toString()),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () async {
                await context.read<DataProvider>().deleteBank(bank['id'], settleTo);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteWalletDialog(Map<String, dynamic> wallet) {
    String settleTo = 'discard';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Delete Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete ${wallet['name']}?'),
              if (double.parse(wallet['balance'].toString()) > 0) ...[
                const SizedBox(height: 16),
                const Text('How to settle remaining balance?', style: TextStyle(fontWeight: FontWeight.bold)),
                RadioListTile(
                  title: const Text('Discard Balance'),
                  value: 'discard',
                  groupValue: settleTo,
                  onChanged: (v) => setState(() => settleTo = v.toString()),
                  contentPadding: EdgeInsets.zero,
                ),
                RadioListTile(
                  title: const Text('Transfer to Cash Book'),
                  value: 'cash',
                  groupValue: settleTo,
                  onChanged: (v) => setState(() => settleTo = v.toString()),
                  contentPadding: EdgeInsets.zero,
                ),
                if (wallet['linked_bank'] != null)
                  RadioListTile(
                    title: const Text('Transfer to Linked Bank'),
                    value: 'linked_bank',
                    groupValue: settleTo,
                    onChanged: (v) => setState(() => settleTo = v.toString()),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorRed),
              onPressed: () async {
                await context.read<DataProvider>().deleteWallet(wallet['id'], settleTo);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBankDialog() {
    final nameCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Bank Name')),
            const SizedBox(height: 10),
            TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'Account Number')),
            const SizedBox(height: 10),
            TextField(controller: balCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Balance', prefixText: 'NPR ')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<DataProvider>().createBank({
                'name': nameCtrl.text.trim(),
                'account_number': accCtrl.text.trim(),
                'balance': balCtrl.text.trim(),
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditBankDialog(Map<String, dynamic> bank) {
    final nameCtrl = TextEditingController(text: bank['name']);
    final accCtrl = TextEditingController(text: bank['account_number']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Bank'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Bank Name')),
            const SizedBox(height: 10),
            TextField(controller: accCtrl, decoration: const InputDecoration(labelText: 'Account Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await context.read<DataProvider>().updateBank(bank['id'].toString(), {
                'name': nameCtrl.text.trim(),
                'account_number': accCtrl.text.trim(),
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddWalletDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '0');
    final dp = context.read<DataProvider>();
    String? linkedBankId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Wallet Name (e.g. eSewa)')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 10),
              TextField(controller: balCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Opening Balance', prefixText: 'NPR ')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: linkedBankId,
                decoration: const InputDecoration(labelText: 'Linked Bank (Optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...dp.banks.map<DropdownMenuItem<String?>>((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name'] ?? ''))),
                ],
                onChanged: (v) => setState(() => linkedBankId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await dp.createWallet({
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'balance': balCtrl.text.trim(),
                  'linked_bank_id': linkedBankId,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditWalletDialog(Map<String, dynamic> wallet) {
    final nameCtrl = TextEditingController(text: wallet['name']);
    final phoneCtrl = TextEditingController(text: wallet['phone']);
    final dp = context.read<DataProvider>();
    String? linkedBankId = wallet['linked_bank']?.toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Wallet Name (e.g. eSewa)')),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number')),
              const SizedBox(height: 10),
              DropdownButtonFormField<String?>(
                value: linkedBankId,
                decoration: const InputDecoration(labelText: 'Linked Bank (Optional)'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  ...dp.banks.map<DropdownMenuItem<String?>>((b) => DropdownMenuItem(value: b['id'].toString(), child: Text(b['name'] ?? ''))),
                ],
                onChanged: (v) => setState(() => linkedBankId = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await dp.updateWallet(wallet['id'].toString(), {
                  'name': nameCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'linked_bank_id': linkedBankId,
                });
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransferFundsDialog() {
    final dp = context.read<DataProvider>();
    String source = 'cash';
    String dest = 'cash';
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final List<DropdownMenuItem<String>> accountOptions = [
      const DropdownMenuItem(value: 'cash', child: Text('Cash Book')),
      ...dp.banks.map((b) => DropdownMenuItem(value: 'bank_${b['id']}', child: Text('Bank: ${b['name']}'))),
      ...dp.wallets.map((w) => DropdownMenuItem(value: 'wallet_${w['id']}', child: Text('Wallet: ${w['name']}'))),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Transfer Funds'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: source,
                  decoration: const InputDecoration(labelText: 'From Account'),
                  items: accountOptions,
                  onChanged: (v) => setState(() => source = v!),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: dest,
                  decoration: const InputDecoration(labelText: 'To Account'),
                  items: accountOptions,
                  onChanged: (v) => setState(() => dest = v!),
                ),
                const SizedBox(height: 10),
                TextField(controller: amtCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount', prefixText: 'NPR ')),
                const SizedBox(height: 10),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: source == dest ? null : () async {
                final amount = amtCtrl.text.trim();
                if (amount.isEmpty || double.tryParse(amount) == null || double.parse(amount) <= 0) return;
                
                final ok = await dp.transferFunds({
                  'source': source,
                  'destination': dest,
                  'amount': amount,
                  'notes': noteCtrl.text.trim(),
                });
                
                if (ok && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Transfer successful'), backgroundColor: AppTheme.accentGreen));
                  Navigator.pop(ctx);
                } else if (!ok && ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Transfer failed. Please check balance.'), backgroundColor: AppTheme.errorRed));
                }
              },
              child: const Text('Transfer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reports ─────────────────────────────────────
class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports & Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.4,
            children: [
              _reportCard(context, Icons.trending_up, 'Sales Report', AppTheme.accentGreen, '/reports/sales'),
              _reportCard(context, Icons.trending_down, 'Purchase Report', AppTheme.primaryBlue, '/reports/purchases'),
              _reportCard(context, Icons.inventory, 'Stock Report', Colors.orange, '/reports/stock'),
              _reportCard(context, Icons.pie_chart, 'Profit & Loss', Colors.purple, '/reports/profit-loss'),
              _reportCard(context, Icons.arrow_downward, 'Receivable', AppTheme.accentGreen, '/reports/receivable'),
              _reportCard(context, Icons.arrow_upward, 'Payable', AppTheme.errorRed, '/reports/payable'),
              _reportCard(context, Icons.swap_vert, 'Cash Flow', AppTheme.primaryBlue, '/reports/cashflow'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reportCard(BuildContext context, IconData icon, String title, Color color, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Report Detail (generic) ─────────────────────
class ReportDetailScreen extends StatefulWidget {
  final String title;
  final String endpoint;
  const ReportDetailScreen({super.key, required this.title, required this.endpoint});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await context.read<DataProvider>().getReport(widget.endpoint);
    setState(() { _data = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: _loading
          ? const LoadingWidget()
          : _data == null
              ? const EmptyWidget(message: 'Failed to load report')
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Show all key-value pairs as stat cards
                    ...(_data!.entries.where((e) => e.value is! List && e.value is! Map).map((e) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatKey(e.key), style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                          _buildValueWidget(e.key, e.value),
                        ],
                      ),
                    ))),

                    // Show lists/tables
                    ...(_data!.entries.where((e) => e.value is List).map((e) {
                      final list = e.value as List;
                      if (list.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          Text(_formatKey(e.key), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          ...list.map((item) {
                            if (item is Map) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: AppTheme.cardShadow),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: item.entries.where((e) => e.key != 'id').map<Widget>((kv) => Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(_formatKey(kv.key), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                                        _buildValueWidget(kv.key, kv.value, fontSize: 12, fontWeight: FontWeight.w600),
                                      ],
                                    ),
                                  )).toList(),
                                ),
                              );
                            }
                            return Text(item.toString());
                          }),
                        ],
                      );
                    })),
                  ],
                ),
    );
  }

  String _formatKey(String key) => key.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');

  bool _isCountKey(String key) {
    final k = key.toLowerCase();
    return k.contains('count') || k.contains('qty') || k.contains('quantity') || k.contains('items');
  }

  bool _isNumeric(dynamic val) {
    if (val is num) return true;
    if (val is String) return double.tryParse(val) != null;
    return false;
  }

  bool _isPhoneKey(String key) {
    final k = key.toLowerCase();
    return k.contains('phone') || k.contains('contact') || k.contains('mobile');
  }

  Widget _buildValueWidget(String key, dynamic value, {double fontSize = 16, FontWeight fontWeight = FontWeight.w700}) {
    if (value == null) return const SizedBox.shrink();

    final isPhone = _isPhoneKey(key);
    final strValue = isPhone
        ? value.toString()
        : (_isNumeric(value)
            ? (_isCountKey(key) ? value.toString() : CurrencyFormatter.format(value))
            : value.toString());

    return Text(
      strValue,
      style: TextStyle(fontWeight: fontWeight, fontSize: fontSize),
    );
  }
}
