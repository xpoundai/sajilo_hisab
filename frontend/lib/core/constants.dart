class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Auth
  static const String login = '/auth/login/';
  static const String adminLogin = '/auth/login/admin/';
  static const String register = '/auth/register/';
  static const String tokenRefresh = '/auth/token/refresh/';
  static const String logout = '/auth/logout/';
  static const String profile = '/auth/profile/';
  static const String users = '/auth/users/';

  // Business
  static const String business = '/business/';

  // Inventory
  static const String items = '/items/';
  static const String stockEntries = '/stock-entries/';

  // Parties
  static const String parties = '/parties/';

  // Transactions
  static const String transactions = '/transactions/';
  static const String transactionCreate = '/transactions/create/';
  static const String daybook = '/daybook/';

  // Banks & Wallets
  static const String banks = '/banks/';
  static const String wallets = '/wallets/';

  // Payments
  static const String payments = '/payments/';
  static const String paymentCreate = '/payments/create/';

  // Cash & Transfers
  static const String cashBalance = '/cash/balance/';
  static const String cashAdjust = '/cash/adjust/';
  static const String fundTransfer = '/cash/transfer/';

  // Reports
  static const String reportSales = '/reports/sales/';
  static const String reportPurchases = '/reports/purchases/';
  static const String reportStock = '/reports/stock/';
  static const String reportProfitLoss = '/reports/profit-loss/';
  static const String reportReceivable = '/reports/receivable/';
  static const String reportPayable = '/reports/payable/';
  static const String reportCashflow = '/reports/cashflow/';

  // Platform
  static const String platformStats = '/platform/stats/';
  static const String platformBusinesses = '/platform/businesses/';
  static const String platformUsers = '/platform/users/';
  static const String systemInfo = '/platform/system-info/';
}
