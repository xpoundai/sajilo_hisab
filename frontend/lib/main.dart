import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'providers/data_provider.dart';
import 'core/theme.dart';
import 'core/constants.dart';
import 'screens/splash_screen.dart';
import 'screens/auth_screens.dart';
import 'screens/dashboard_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/parties_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/users_screen.dart';
import 'screens/super_admin_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DataProvider()),
      ],
      child: const SajiloHisabApp(),
    ),
  );
}

class SajiloHisabApp extends StatelessWidget {
  const SajiloHisabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Sajilo Hisab',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
    );
  }
}

// ─── Shell with Bottom Nav ──────────────────────
class _ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;
  const _ScaffoldWithNavBar({required this.child});

  static const _tabs = [
    '/dashboard',
    '/parties',
    '/inventory',
    '/transactions',
    '/settings',
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // No bottom nav for super admin
    if (auth.isPlatformAdmin) return child;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(context, 0, Icons.home_rounded, 'Home'),
                _navItem(context, 1, Icons.people_rounded, 'Parties'),
                _navItem(context, 2, Icons.inventory_2_rounded, 'Inventory'),
                _navItem(context, 3, Icons.swap_horiz_rounded, 'Txns'),
                _navItem(context, 4, Icons.settings_rounded, 'Settings'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(BuildContext context, int index, IconData icon, String label) {
    final current = _currentIndex(context);
    final selected = current == index;

    return GestureDetector(
      onTap: () => context.go(_tabs[index]),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: selected ? 16 : 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppTheme.primaryBlue : AppTheme.textLight, size: 22),
            if (selected) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Router Config ──────────────────────────────
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    // Screens WITH bottom nav bar
    ShellRoute(
      builder: (_, __, child) => _ScaffoldWithNavBar(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, _) {
            final auth = context.read<AuthProvider>();
            return auth.isPlatformAdmin ? const SuperAdminDashboard() : const DashboardScreen();
          },
        ),
        GoRoute(path: '/parties', builder: (_, __) => const PartiesScreen()),
        GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
        GoRoute(path: '/transactions', builder: (_, __) => const TransactionsScreen()),
        GoRoute(path: '/users', builder: (_, __) => const UsersScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),

    // Screens WITHOUT bottom nav bar (form screens)
    GoRoute(path: '/inventory/add', builder: (_, __) => const AddItemScreen()),
    GoRoute(path: '/inventory/edit/:id', builder: (_, state) => AddItemScreen(itemId: state.pathParameters['id'])),
    GoRoute(path: '/inventory/stock-entry', builder: (_, __) => const StockEntryScreen()),
    GoRoute(path: '/inventory/sales-list', builder: (_, __) => const SalesListScreen()),
    GoRoute(path: '/parties/add', builder: (_, __) => const AddPartyScreen()),
    GoRoute(path: '/parties/:id', builder: (_, state) => PartyDetailScreen(partyId: state.pathParameters['id']!)),
    GoRoute(
      path: '/transactions/create',
      builder: (_, state) => CreateTransactionScreen(initialType: state.uri.queryParameters['type']),
    ),
    GoRoute(path: '/payments/create', builder: (_, __) => const PaymentScreen()),
    GoRoute(path: '/banks', builder: (_, __) => const BanksScreen()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(path: '/reports/sales', builder: (_, __) => const ReportDetailScreen(title: 'Sales Report', endpoint: ApiConstants.reportSales)),
    GoRoute(path: '/reports/purchases', builder: (_, __) => const ReportDetailScreen(title: 'Purchase Report', endpoint: ApiConstants.reportPurchases)),
    GoRoute(path: '/reports/stock', builder: (_, __) => const ReportDetailScreen(title: 'Stock Report', endpoint: ApiConstants.reportStock)),
    GoRoute(path: '/reports/profit-loss', builder: (_, __) => const ReportDetailScreen(title: 'Profit & Loss', endpoint: ApiConstants.reportProfitLoss)),
    GoRoute(path: '/reports/receivable', builder: (_, __) => const ReportDetailScreen(title: 'Receivable', endpoint: ApiConstants.reportReceivable)),
    GoRoute(path: '/reports/payable', builder: (_, __) => const ReportDetailScreen(title: 'Payable', endpoint: ApiConstants.reportPayable)),
    GoRoute(path: '/reports/cashflow', builder: (_, __) => const ReportDetailScreen(title: 'Cash Flow', endpoint: ApiConstants.reportCashflow)),
  ],
);
