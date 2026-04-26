import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/data_provider.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../widgets/common.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dp = context.read<DataProvider>();
      dp.loadPlatformStats();
      dp.loadPlatformBusinesses();
      dp.loadPlatformUsers();
      dp.loadSystemInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DataProvider>();
    final stats = dp.platformStats ?? {};

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: AppTheme.superAdminGradient)),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sajilo Hisab Platform', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Super Admin Dashboard', style: TextStyle(fontSize: 13, color: Colors.white70)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Businesses'),
            Tab(text: 'Users'),
            Tab(text: 'System'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _dashboardTab(stats),
          _businessesTab(dp),
          _usersTab(dp),
          _systemTab(dp),
        ],
      ),
    );
  }

  Widget _dashboardTab(Map<String, dynamic> stats) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // System health
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accentGreen.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 28),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('System Health', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Text('All systems operational', style: TextStyle(color: AppTheme.accentGreen, fontSize: 13)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            StatCard(title: 'Total Businesses', value: '${stats['total_businesses'] ?? 0}', icon: Icons.business, color: AppTheme.superAdminOrange),
            StatCard(title: 'Total Users', value: '${stats['total_users'] ?? 0}', icon: Icons.people, color: AppTheme.primaryBlue),
            StatCard(title: 'Active', value: '${stats['active_businesses'] ?? 0}', icon: Icons.check_circle, color: AppTheme.accentGreen),
            StatCard(title: 'Transactions', value: '${stats['total_transactions'] ?? 0}', icon: Icons.receipt_long, color: Colors.purple),
          ],
        ),
        const SizedBox(height: 16),

        // Plan distribution
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Plan Distribution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 14),
              _planBar('Basic', stats['plan_distribution']?['basic'] ?? 0, Colors.grey, stats['total_businesses'] ?? 1),
              _planBar('Pro', stats['plan_distribution']?['pro'] ?? 0, AppTheme.primaryBlue, stats['total_businesses'] ?? 1),
              _planBar('Premium', stats['plan_distribution']?['premium'] ?? 0, AppTheme.accentGreen, stats['total_businesses'] ?? 1),
            ],
          ),
        ),
      ],
    );
  }

  Widget _planBar(String label, int count, Color color, int total) {
    final fraction = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text('$count', style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: fraction, backgroundColor: color.withOpacity(0.1), color: color, minHeight: 8),
          ),
        ],
      ),
    );
  }

  Widget _businessesTab(DataProvider dp) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: InputDecoration(hintText: 'Search businesses...', prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          onChanged: (v) => dp.loadPlatformBusinesses(search: v),
        ),
        const SizedBox(height: 12),
        ...dp.platformBusinesses.map((b) {
          Color statusColor = b['status'] == 'active' ? AppTheme.accentGreen : b['status'] == 'suspended' ? AppTheme.errorRed : AppTheme.warningYellow;
          Color planColor = b['plan'] == 'pro' ? AppTheme.primaryBlue : b['plan'] == 'premium' ? AppTheme.accentGreen : Colors.grey;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(b['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                    StatusBadge(label: (b['plan'] ?? '').toString().toUpperCase(), color: planColor),
                    const SizedBox(width: 6),
                    StatusBadge(label: (b['status'] ?? '').toString().toUpperCase(), color: statusColor),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('👤 ${b['owner_name']}  📞 ', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    PhoneLink(phone: b['phone']?.toString() ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                  ],
                ),
                Text('📍 ${b['address']}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('Users: ${b['user_count']}', style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 14),
                    Text('Txns: ${b['transaction_count']}', style: const TextStyle(fontSize: 12)),
                    const Spacer(),
                    if (b['status'] == 'active')
                      TextButton(
                        onPressed: () => dp.updateBusinessStatus(b['id'], {'status': 'suspended'}),
                        child: const Text('Suspend', style: TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                      )
                    else
                      TextButton(
                        onPressed: () => dp.updateBusinessStatus(b['id'], {'status': 'active'}),
                        child: const Text('Activate', style: TextStyle(color: AppTheme.accentGreen, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _usersTab(DataProvider dp) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          decoration: InputDecoration(hintText: 'Search users...', prefixIcon: const Icon(Icons.search, size: 20), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          onChanged: (v) => dp.loadPlatformUsers(search: v),
        ),
        const SizedBox(height: 12),
        ...dp.platformUsers.map((u) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppTheme.cardShadow),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                child: Text((u['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryBlue)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(u['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 6),
                    StatusBadge(label: (u['role'] ?? '').toString().toUpperCase(), color: AppTheme.primaryBlue),
                  ]),
                  Text(u['business_name'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  PhoneLink(phone: u['phone'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ]),
              ),
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  color: u['is_active'] == true ? AppTheme.accentGreen : Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _systemTab(DataProvider dp) {
    final info = dp.systemInfo ?? {};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.cardShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Platform Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _infoRow('Version', info['version'] ?? '-'),
              _infoRow('Environment', info['environment'] ?? '-'),
              _infoRow('Database', info['database'] ?? '-'),
              _infoRow('Region', info['region'] ?? '-'),
              _infoRow('System Health', info['system_health'] ?? '-'),
              _infoRow('Active Users', '${info['active_users_24h'] ?? '-'}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
