import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات المصادقة الخام مع الباك: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا حفظ توكن ولا تحويل بيانات هنا — كل ذلك في AuthService
/// (services/controllers).
class AuthData {
  final Dio _dio = DioClient.instance.dio;

  // POST /register
  Future<Response> register({
    required String name,
    required String email,
    required String phoneNumber,
    required String password,
    required String passwordConfirmation,
    required String accountType,
  }) async {
    return _dio.post(
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
  }

  // POST /register/otp-resend
  Future<Response> resendRegisterOtp({required String email}) async {
    return _dio.post('/register/otp-resend', data: {'email': email});
  }

  // POST /register/otp-verify
  Future<Response> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    return _dio.post('/register/otp-verify', data: {'email': email, 'otp': otp});
  }

  // POST /login
  Future<Response> login({
    required String email,
    required String password,
  }) async {
    return _dio.post('/login', data: {'email': email, 'password': password});
  }

  // GET /user
  Future<Response> getCurrentUser() async {
    return _dio.get('/user', options: await _authOptions());
  }

  // POST /logout
  Future<Response> logout() async {
    return _dio.post('/logout', options: await _authOptions());
  }

  // POST /password/otp-request
  Future<Response> requestPasswordResetOtp({required String email}) async {
    return _dio.post('/password/otp-request', data: {'email': email});
  }

  // POST /password/otp-verify
  Future<Response> verifyPasswordOtp({
    required String email,
    required String otp,
  }) async {
    return _dio.post('/password/otp-verify', data: {'email': email, 'otp': otp});
  }

  // POST /password/otp-reset
  Future<Response> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    return _dio.post(
      '/password/otp-reset',
      data: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
