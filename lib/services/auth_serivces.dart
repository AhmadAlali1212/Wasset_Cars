import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../ulits/constans.dart';
import '../screens/auth/storeg/auth_storage.dart';

class AuthService with ChangeNotifier {
  final Dio _dio;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _currentUser;

  AuthService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
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
        '/register',
        data: {
          'name': name,
          'email': email,
          'phone_number': phoneNumber,
          'password': password,
          'password_confirmation': passwordConfirmation,
          'account_type': accountType,
        },
      );
      print('STATUS = ${response.statusCode}');
      print('DATA = ${response.data}');
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
    } on DioException catch (e) {
      print('STATUS ERROR = ${e.response?.statusCode}');
      print('DATA ERROR = ${e.response?.data}');
      print('MESSAGE ERROR = ${e.message}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> resendRegisterOtp({
    required String email,
  }) async {
    final response = await _dio.post(
      '/register/otp-resend',
      data: {'email': email},
    );
    _handleResponseErrors(response, 'إعادة إرسال رمز التفعيل');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      '/register/otp-verify',
      data: {'email': email, 'otp': otp},
    );
    _handleResponseErrors(response, 'تفعيل الحساب');
    await _storeAuthResponse(response.data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {'email': email, 'password': password},
      );

      _handleResponseErrors(response, 'تسجيل الدخول');

      await _storeAuthResponse(response.data);

      return response.data;
    } catch (e) {
      debugPrint('Login Error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/user', options: await _authOptions());
    _handleResponseErrors(response, 'جلب بيانات المستخدم');
    if (response.data is Map) {
      _currentUser = Map<String, dynamic>.from(response.data as Map);
    }
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout', options: await _authOptions());
      await AuthStorage.clearToken();
      await AuthStorage.clearUser();
      _isLoggedIn = false;
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Logout Error: $e');
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

      final response = await _dio.get('/user', options: await _authOptions());
      if (response.statusCode == 200) {
        if (response.data is Map) {
          _currentUser = Map<String, dynamic>.from(response.data as Map);
          await AuthStorage.saveUser(_currentUser!);
        }
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
      default:
        throw Exception('نوع الحساب غير صالح');
    }
  }

  void _handleResponseErrors(Response response, String operation) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    final errorMessages = _extractValidationMessage(response.data);
    final message =
        response.statusCode == 422
            ? 'خطأ في $operation:\n$errorMessages'
            : 'فشل $operation: $errorMessages';

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      type: DioExceptionType.badResponse,
      message: message,
      error: message,
    );
  }

  String _extractValidationMessage(dynamic data) {
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    if (data is! Map) {
      return 'حدث خطأ غير معروف';
    }

    final map = Map<String, dynamic>.from(data);
    final errors = map['errors'];
    final lines = <String>[];

    if (errors is Map && errors.isNotEmpty) {
      errors.forEach((key, value) {
        if (value is List) {
          final values = value.map((item) => item.toString()).join(', ');
          if (values.isNotEmpty) {
            lines.add('$key: $values');
          }
        } else if (value is String && value.trim().isNotEmpty) {
          lines.add('$key: ${value.trim()}');
        } else if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty) {
            lines.add('$key: $text');
          }
        }
      });
    } else if (errors is List && errors.isNotEmpty) {
      lines.addAll(
        errors
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty),
      );
    } else if (errors is String && errors.trim().isNotEmpty) {
      lines.add(errors.trim());
    }

    if (lines.isNotEmpty) {
      return lines.join('\n');
    }

    final message = map['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message.trim();
    }

    final error = map['error'];
    if (error is String && error.trim().isNotEmpty) {
      return error.trim();
    }

    return 'حدث خطأ غير معروف';
  }

  Future<Map<String, dynamic>> requestPasswordResetOtp({
    required String email,
  }) async {
    final response = await _dio.post(
      '/forgot-password',
      data: {'email': email},
    );
    _handleResponseErrors(response, 'طلب رمز إعادة تعيين كلمة المرور');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> verifyPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _dio.post(
      '/password/otp-verify',
      data: {'email': email, 'otp': otp},
    );
    _handleResponseErrors(response, 'التحقق من رمز إعادة التعيين');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _dio.post(
      '/reset-password',
      data: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
    _handleResponseErrors(response, 'إعادة تعيين كلمة المرور');
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<void> _storeAuthResponse(dynamic data) async {
    if (data is! Map) {
      return;
    }

    final responseMap = Map<String, dynamic>.from(data);
    final accessToken = responseMap['access_token'];
    final user = responseMap['user'];

    if (accessToken is String && accessToken.isNotEmpty) {
      await AuthStorage.saveToken(accessToken);
      _isLoggedIn = true;
    }

    if (user is Map<String, dynamic>) {
      await AuthStorage.saveUser(user);
      _currentUser = user;
    } else if (user is Map) {
      final userMap = Map<String, dynamic>.from(user);
      await AuthStorage.saveUser(userMap);
      _currentUser = userMap;
    }

    if (accessToken is String && accessToken.isNotEmpty) {
      notifyListeners();
    }
  }
}
