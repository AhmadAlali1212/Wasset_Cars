import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../screens/auth/storeg/auth_storage.dart';

class AuthService with ChangeNotifier {
  final Dio _dio;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _currentUser;

  AuthService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: 'http://52.14.1.4:8001',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
          validateStatus: (status) => status! < 500,
        ),
      ) {
    _init();
  }

  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get currentUser => _currentUser;

  Future<void> _init() async {
    final token = await AuthStorage.getToken();
    _isLoggedIn = token != null;
    if (_isLoggedIn) {
      _currentUser = await AuthStorage.getUser();
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
    required int accountTypeId,
  }) async {
    try {
      final accountType = _convertAccountType(accountTypeId);

      final response = await _dio.post(
        '/api/register',
        data: {
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'account_type': accountType,
        },
      );

      _handleResponseErrors(response, 'التسجيل');

      if (response.data['access_token'] != null) {
        await AuthStorage.saveToken(response.data['access_token']);
        if (response.data['user'] != null) {
          await AuthStorage.saveUser(response.data['user']);
          _currentUser = response.data['user'];
        }
        _isLoggedIn = true;
        notifyListeners();
      }

      return response.data;
    } catch (e) {
      print('Register Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/api/login',
        data: {'email': email, 'password': password},
      );

      _handleResponseErrors(response, 'تسجيل الدخول');

      if (response.data['access_token'] != null) {
        await AuthStorage.saveToken(response.data['access_token']);
        if (response.data['user'] != null) {
          await AuthStorage.saveUser(response.data['user']);
          _currentUser = response.data['user'];
        }
        _isLoggedIn = true;
        notifyListeners();
      }

      return response.data;
    } catch (e) {
      print('Login Error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/logout');
      await AuthStorage.clearToken();
      await AuthStorage.clearUser();
      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('Logout Error: $e');
      rethrow;
    }
  }

  Future<bool> checkAuth() async {
    try {
      final token = await AuthStorage.getToken();
      if (token == null) {
        _isLoggedIn = false;
        return false;
      }

      final response = await _dio.get('/api/user');
      if (response.statusCode == 200) {
        _isLoggedIn = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _isLoggedIn = false;
      return false;
    }
  }

  String _convertAccountType(int accountTypeId) {
    switch (accountTypeId) {
      case 1:
        return 'individual';
      case 2:
        return 'company';
      case 3:
        return 'workshop';
      default:
        throw Exception('نوع الحساب غير صالح');
    }
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode == 422) {
      final errors = response.data['errors'] ?? {};
      final errorMessages = errors.entries
          .map((e) => '${e.key}: ${e.value.join(', ')}')
          .join('\n');
      throw Exception('خطأ في $operation:\n$errorMessages');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'فشل $operation: ${response.data['message'] ?? 'حدث خطأ غير معروف'}',
      );
    }
  }
}
