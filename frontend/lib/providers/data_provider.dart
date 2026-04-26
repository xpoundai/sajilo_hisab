import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../core/constants.dart';

class DataProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  // Dashboard / Day Book
  Map<String, dynamic>? _dashboardData;
  bool _dashboardLoading = false;

  // Items
  List<dynamic> _items = [];
  bool _itemsLoading = false;

  // Parties
  List<dynamic> _parties = [];
  bool _partiesLoading = false;

  // Transactions
  List<dynamic> _transactions = [];
  bool _transactionsLoading = false;

  // Banks & Wallets
  List<dynamic> _banks = [];
  List<dynamic> _wallets = [];

  // Payments
  List<dynamic> _payments = [];

  // Business Users
  List<dynamic> _users = [];
  bool _usersLoading = false;

  // Platform
  Map<String, dynamic>? _platformStats;
  List<dynamic> _platformBusinesses = [];
  List<dynamic> _platformUsers = [];
  Map<String, dynamic>? _systemInfo;

  // Getters
  Map<String, dynamic>? get dashboardData => _dashboardData;
  bool get dashboardLoading => _dashboardLoading;
  List<dynamic> get items => _items;
  bool get itemsLoading => _itemsLoading;
  List<dynamic> get parties => _parties;
  bool get partiesLoading => _partiesLoading;
  List<dynamic> get transactions => _transactions;
  bool get transactionsLoading => _transactionsLoading;
  List<dynamic> get banks => _banks;
  List<dynamic> get wallets => _wallets;
  List<dynamic> get payments => _payments;
  List<dynamic> get users => _users;
  bool get usersLoading => _usersLoading;
  Map<String, dynamic>? get platformStats => _platformStats;
  List<dynamic> get platformBusinesses => _platformBusinesses;
  List<dynamic> get platformUsers => _platformUsers;
  Map<String, dynamic>? get systemInfo => _systemInfo;

  // ─── Dashboard / DayBook ─────────────────────
  Future<void> loadDashboard({String? dateFrom, String? dateTo, String type = 'all'}) async {
    _dashboardLoading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{'type': type};
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      final res = await _api.get(ApiConstants.daybook, queryParameters: params);
      _dashboardData = res.data;
    } catch (_) {}
    _dashboardLoading = false;
    notifyListeners();
  }

  // ─── Items ────────────────────────────────────
  Future<void> loadItems({String? search}) async {
    _itemsLoading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.items, queryParameters: params);
      _items = res.data['results'] ?? res.data;
    } catch (_) {}
    _itemsLoading = false;
    notifyListeners();
  }

  Future<bool> createItem(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.items, data: data);
      await loadItems();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateItem(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('${ApiConstants.items}$id/', data: data);
      await loadItems();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _api.delete('${ApiConstants.items}$id/');
      await loadItems();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> createStockEntry(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.stockEntries, data: data);
      await loadItems();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Parties ──────────────────────────────────
  Future<void> loadParties({String? search, String? type}) async {
    _partiesLoading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{};
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (type != null && type.isNotEmpty) params['type'] = type;
      final res = await _api.get(ApiConstants.parties, queryParameters: params);
      _parties = res.data['results'] ?? res.data;
    } catch (_) {}
    _partiesLoading = false;
    notifyListeners();
  }

  Future<bool> createParty(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.parties, data: data);
      await loadParties();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getPartyLedger(String id) async {
    try {
      final res = await _api.get('${ApiConstants.parties}$id/ledger/');
      return res.data;
    } catch (_) {
      return null;
    }
  }

  // ─── Transactions ─────────────────────────────
  Future<void> loadTransactions({String? type, String? search}) async {
    _transactionsLoading = true;
    notifyListeners();
    try {
      final params = <String, dynamic>{};
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (search != null && search.isNotEmpty) params['search'] = search;
      final res = await _api.get(ApiConstants.transactions, queryParameters: params);
      _transactions = res.data['results'] ?? res.data;
    } catch (_) {}
    _transactionsLoading = false;
    notifyListeners();
  }

  Future<bool> createTransaction(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.transactionCreate, data: data);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Banks & Wallets ──────────────────────────
  Future<void> loadBanks() async {
    try {
      final res = await _api.get(ApiConstants.banks);
      _banks = res.data['results'] ?? res.data;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createBank(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.banks, data: data);
      await loadBanks();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadWallets() async {
    try {
      final res = await _api.get(ApiConstants.wallets);
      _wallets = res.data['results'] ?? res.data;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createWallet(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.wallets, data: data);
      await loadWallets();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteBank(String id, String settleTo) async {
    try {
      await _api.delete('${ApiConstants.banks}$id/', queryParameters: {'settle_to': settleTo});
      await loadBanks();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateBank(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('${ApiConstants.banks}$id/', data: data);
      await loadBanks();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteWallet(String id, String settleTo) async {
    try {
      await _api.delete('${ApiConstants.wallets}$id/', queryParameters: {'settle_to': settleTo});
      await loadWallets();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateWallet(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('${ApiConstants.wallets}$id/', data: data);
      await loadWallets();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> transferFunds(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.fundTransfer, data: data);
      await loadBanks();
      await loadWallets();
      // Cash logic isn't explicitly held here but if it is, we'd reload it.
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Payments ─────────────────────────────────
  Future<void> loadPayments({String? type}) async {
    try {
      final params = <String, dynamic>{};
      if (type != null) params['type'] = type;
      final res = await _api.get(ApiConstants.payments, queryParameters: params);
      _payments = res.data['results'] ?? res.data;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> createPayment(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.paymentCreate, data: data);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Business Users ───────────────────────────
  Future<void> loadUsers() async {
    _usersLoading = true;
    notifyListeners();
    try {
      final res = await _api.get(ApiConstants.users);
      _users = res.data['results'] ?? res.data;
    } catch (_) {}
    _usersLoading = false;
    notifyListeners();
  }

  Future<bool> createUser(Map<String, dynamic> data) async {
    try {
      await _api.post(ApiConstants.users, data: data);
      await loadUsers();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('${ApiConstants.users}$id/', data: data);
      await loadUsers();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Reports ──────────────────────────────────
  Future<Map<String, dynamic>?> getReport(String endpoint, {Map<String, dynamic>? params}) async {
    try {
      final res = await _api.get(endpoint, queryParameters: params);
      return res.data;
    } catch (_) {
      return null;
    }
  }

  // ─── Platform Admin ───────────────────────────
  Future<void> loadPlatformStats() async {
    try {
      final res = await _api.get(ApiConstants.platformStats);
      _platformStats = res.data;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPlatformBusinesses({String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null) params['search'] = search;
      final res = await _api.get(ApiConstants.platformBusinesses, queryParameters: params);
      _platformBusinesses = res.data['businesses'] ?? [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadPlatformUsers({String? search}) async {
    try {
      final params = <String, dynamic>{};
      if (search != null) params['search'] = search;
      final res = await _api.get(ApiConstants.platformUsers, queryParameters: params);
      _platformUsers = res.data['users'] ?? [];
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadSystemInfo() async {
    try {
      final res = await _api.get(ApiConstants.systemInfo);
      _systemInfo = res.data;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> updateBusinessStatus(String id, Map<String, dynamic> data) async {
    try {
      await _api.patch('${ApiConstants.platformBusinesses}$id/', data: data);
      await loadPlatformBusinesses();
      return true;
    } catch (_) {
      return false;
    }
  }
}
