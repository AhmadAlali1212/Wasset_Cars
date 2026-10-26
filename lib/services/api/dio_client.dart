import 'package:dio/dio.dart';
import 'package:mators_car/ulits/constant.dart';

class DioClient {
  DioClient._()
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          responseType: ResponseType.json,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

  static final DioClient instance = DioClient._();

  final Dio dio;
}
