import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';
import '../core/constants.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  bool _isPlatformAdmin = false;
  Map<String, dynamic>? _user;
  String? _error;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isPlatformAdmin => _isPlatformAdmin;
  Map<String, dynamic>? get user => _user;
  String? get error => _error;

  String get userName => _user?['name'] ?? _user?['username'] ?? '';
  String get userRole => _user?['role'] ?? (_isPlatformAdmin ? 'Super Admin' : '');
  String get businessName => _user?['business']?['name'] ?? 'Sajilo Hisab Platform';
  String get businessPlan => _user?['business']?['plan'] ?? '';

  bool hasPermission(String perm) {
    if (_isPlatformAdmin) return false;
    final perms = _user?['permissions'] as List? ?? [];
    if (perms.contains('all')) return true;
    return perms.contains(perm);
  }

  Future<void> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    try {
      final response = await _api.get(ApiConstants.profile);
      _isLoggedIn = true;
      _isPlatformAdmin = response.data['is_platform_admin'] ?? false;
      _user = _isPlatformAdmin ? response.data['user'] : response.data['user'];
      notifyListeners();
    } catch (_) {
      _isLoggedIn = false;
      await prefs.clear();
      notifyListeners();
    }
  }

  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.login, data: {
        'identifier': identifier,
        'password': password,
      });

      final data = response.data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['tokens']['access']);
      await prefs.setString('refresh_token', data['tokens']['refresh']);

      _isLoggedIn = true;
      _isPlatformAdmin = data['is_platform_admin'] ?? false;
      _user = data['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.post(ApiConstants.register, data: data);

      final resData = response.data;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', resData['tokens']['access']);
      await prefs.setString('refresh_token', resData['tokens']['refresh']);

      _isLoggedIn = true;
      _isPlatformAdmin = false;
      _user = resData['user'];
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _extractError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final refresh = prefs.getString('refresh_token');
      await _api.post(ApiConstants.logout, data: {'refresh': refresh});
    } catch (_) {}
    await prefs.clear();
    _isLoggedIn = false;
    _isPlatformAdmin = false;
    _user = null;
    notifyListeners();
  }

  String _extractError(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      final data = e.response?.data;
      if (data is Map) {
        if (data.containsKey('error')) return data['error'];
        if (data.containsKey('detail')) return data['detail'];
        return data.values.first.toString();
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
