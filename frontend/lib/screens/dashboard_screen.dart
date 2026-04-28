import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';
import '../providers/notification_provider.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DataProvider>().loadDashboard();
      context.read<NotificationProvider>().refreshUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final data = context.watch<DataProvider>();
    final summary = data.dashboardData?['summary'] as Map<String, dynamic>? ?? {};
    final entries = data.dashboardData?['entries'] as List? ?? [];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Image.asset('assets/logo.png', width: 32, height: 32, fit: BoxFit.contain),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(auth.businessName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                Text(
                  'Welcome back, ${auth.userRole} 👋',
                  style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, _) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/notifications'),
                  ),
                  if (notifProvider.unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          notifProvider.unreadCount > 99
                              ? '99+'
                              : '${notifProvider.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => data.loadDashboard(type: _filter),
        child: data.dashboardLoading
            ? const LoadingWidget()
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Today's Sales Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Sales", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyFormatter.format(summary['today_sales']),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _miniStat('Cash', CurrencyFormatter.compact(summary['cash_balance'])),
                            const SizedBox(width: 20),
                            _miniStat('Bank', CurrencyFormatter.compact(summary['bank_balance'])),
                            const SizedBox(width: 20),
                            _miniStat('Wallet', CurrencyFormatter.compact(summary['wallet_balance'])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Summary Cards 2x2
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        title: 'Receivable',
                        value: CurrencyFormatter.compact(summary['total_receivable']),
                        icon: Icons.arrow_downward,
                        color: AppTheme.accentGreen,
                      ),
                      StatCard(
                        title: 'Payable',
                        value: CurrencyFormatter.compact(summary['total_payable']),
                        icon: Icons.arrow_upward,
                        color: AppTheme.errorRed,
                      ),
                      StatCard(
                        title: 'Total Balance',
                        value: CurrencyFormatter.compact(summary['total_balance']),
                        icon: Icons.account_balance_wallet,
                        color: AppTheme.primaryBlue,
                      ),
                      StatCard(
                        title: 'Advance',
                        value: CurrencyFormatter.compact(summary['total_advance']),
                        icon: Icons.trending_up,
                        color: AppTheme.warningYellow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions
                  if (auth.userRole != 'viewer') ...[
                    const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        QuickActionButton(
                          label: '+Sale',
                          icon: Icons.shopping_cart_outlined,
                          color: AppTheme.accentGreen,
                          onTap: () => context.push('/transactions/create?type=sale'),
                        ),
                        QuickActionButton(
                          label: '+Purchase',
                          icon: Icons.inventory_2_outlined,
                          color: AppTheme.primaryBlue,
                          onTap: () => context.push('/transactions/create?type=purchase'),
                        ),
                        if (auth.userRole != 'staff')
                          QuickActionButton(
                            label: 'Payment',
                            icon: Icons.payments_outlined,
                            color: AppTheme.warningYellow,
                            onTap: () => context.push('/payments/create'),
                          ),
                        QuickActionButton(
                          label: '+Item',
                          icon: Icons.add_box_outlined,
                          color: Colors.purple,
                          onTap: () => context.push('/inventory/add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Financial Overview
                  Row(
                    children: [
                      _overviewCard('Banks', '${summary['bank_count'] ?? 0}', Icons.account_balance, () => context.push('/banks')),
                      const SizedBox(width: 10),
                      _overviewCard('Wallets', '${summary['wallet_count'] ?? 0}', Icons.wallet, () => context.push('/banks')),
                      const SizedBox(width: 10),
                      _overviewCard('Parties', '${summary['party_count'] ?? 0}', Icons.people, () => context.push('/parties')),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Day Book
                  const Text('Day Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All', 'all'),
                        _filterChip('Sales', 'sale'),
                        _filterChip('Purchase', 'purchase'),
                        _filterChip('Received', 'payment_in'),
                        _filterChip('Paid', 'payment_out'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (entries.isEmpty)
                    const EmptyWidget(message: 'No transactions today', icon: Icons.receipt_long_outlined)
                  else
                    ...entries.map((e) => _dayBookEntry(e)),
                ],
              ),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
      ],
    );
  }

  Widget _overviewCard(String title, String count, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppTheme.primaryBlue, size: 22),
              const SizedBox(height: 6),
              Text(count, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        selectedColor: AppTheme.primaryBlue.withOpacity(0.15),
        checkmarkColor: AppTheme.primaryBlue,
        onSelected: (_) {
          setState(() => _filter = value);
          context.read<DataProvider>().loadDashboard(type: value);
        },
      ),
    );
  }

  Widget _dayBookEntry(Map<String, dynamic> entry) {
    final type = entry['type'] as String;
    final isIncome = type == 'sale' || type == 'payment_in';

    IconData icon;
    String emoji;
    switch (type) {
      case 'sale':
        icon = Icons.shopping_cart;
        emoji = '🛒';
        break;
      case 'purchase':
        icon = Icons.inventory_2;
        emoji = '📦';
        break;
      case 'payment_in':
        icon = Icons.arrow_downward;
        emoji = '💰';
        break;
      default:
        icon = Icons.arrow_upward;
        emoji = '💸';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['description'] ?? '',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      DateFormatter.formatShort(entry['date']?.toString()),
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: (entry['method'] ?? 'cash').toString().toUpperCase(),
                      color: AppTheme.primaryBlue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${CurrencyFormatter.format(entry['amount'])}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isIncome ? AppTheme.accentGreen : AppTheme.errorRed,
            ),
          ),
        ],
      ),
    );
  }
}
