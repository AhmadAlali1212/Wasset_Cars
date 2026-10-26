import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/storeg/auth_storage.dart';
import 'package:mators_car/services/api/dio_client.dart';

/// طلبات الباك الخام لـ MessageService: كل دالة ترسل طلباً واحداً وتعيد الـ Response كما هو.
/// لا معالجة أخطاء ولا تحويل بيانات هنا — كل ذلك في MessageService (services/controllers).
class MessageData {
  final Dio _dio = DioClient.instance.dio;

  // GET /messages/conversations
  Future<Response> getConversations() async {
    return _dio.get(
      '/messages/conversations',
      options: await _authOptions(),
    );
  }

  // GET /messages/with/$partnerId
  Future<Response> getThread(
    int partnerId, {
    int page = 1,
  }) async {
    return _dio.get(
      '/messages/with/$partnerId',
      queryParameters: {'page': page},
      options: await _authOptions(),
    );
  }

  // POST /messages
  Future<Response> sendMessage({
    required int receiverId,
    required String content,
  }) async {
    return _dio.post(
      '/messages',
      data: {'receiver_id': receiverId, 'content': content},
      options: await _authOptions(),
    );
  }

  // GET /messages/unread-count
  Future<Response> getUnreadCount() async {
    return _dio.get(
      '/messages/unread-count',
      options: await _authOptions(),
    );
  }

  Future<Options> _authOptions() async {
    final token = await AuthStorage.getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
  }
}
