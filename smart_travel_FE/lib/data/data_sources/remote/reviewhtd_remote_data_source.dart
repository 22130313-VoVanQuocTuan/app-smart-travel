// lib/data/datasources/reviewhtd_remote_data_source.dart
import 'package:smart_travel/core/network/dio_client.dart';
import '../../models/review/reviewhtd_model.dart';

abstract class ReviewHtdRemoteDataSource {
  Future<List<ReviewHtdModel>> getReviewHtd({
    required String type,
    required int serviceId,
    int? rating,
  });
}
class ReviewHtdRemoteDataSourceImpl implements ReviewHtdRemoteDataSource {
  final DioClient dioClient;

  ReviewHtdRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<ReviewHtdModel>> getReviewHtd({
    required String type,
    required int serviceId,
    int? rating,
  }) async {
    try {

      final String url = '/reviews/hotel/$serviceId';

      final response = await dioClient.get(url);


      if (response.statusCode == 200) {
        final List<dynamic> list = response.data is List ? response.data : [];

        // Chuyển đổi sang model
        List<ReviewHtdModel> reviews = list
            .map((json) => ReviewHtdModel.fromJson(json as Map<String, dynamic>))
            .toList();

        // Lọc theo rating (nếu có)
        if (rating != null) {
          reviews = reviews.where((r) => r.rating == rating).toList();
        }

        return reviews;
      } else {
        throw Exception('Lỗi tải review: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi getReviewHtd: $e');
      return [];
    }
  }
}