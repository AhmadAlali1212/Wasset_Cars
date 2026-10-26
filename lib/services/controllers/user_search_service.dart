import 'package:mators_car/data/dataSource/remote/user_search_data.dart';

/// بحث عن مستخدم بالاسم/البريد/الهاتف — يفتح الباب لميزات مثل اختيار
/// المشتري الفعلي عند تعليم إعلان كـ "مباع" (لتفعيل نظام التقييم لاحقاً).
class UserSearchService {
  final UserSearchData _data = UserSearchData();

  Future<List<Map<String, dynamic>>> search(String query) async {
    if (query.trim().length < 2) return [];
    final response = await _data.search(query);
    if (response.statusCode == null || response.statusCode! >= 300) {
      return [];
    }
    final data = response.data;
    List list = [];
    if (data is Map && data['users'] is Map && data['users']['data'] is List) {
      list = data['users']['data'] as List;
    } else if (data is Map && data['users'] is List) {
      list = data['users'] as List;
    }
    return List<Map<String, dynamic>>.from(
      list.map((item) => Map<String, dynamic>.from(item)),
    );
  }
}
