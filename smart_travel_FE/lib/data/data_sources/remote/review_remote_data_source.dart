import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

abstract class ReviewRemoteDataSource {
  Future<void> submitReview({
    required int rating,
    String? comment,
    required String invoiceNumber,
  });
  
  Future<Map<String, dynamic>> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  });
  
  Future<bool> checkIfUserReviewedHotel({
    required int hotelId,
  });
}

class ReviewRemoteDataSourceImpl implements ReviewRemoteDataSource {
  final DioClient dioClient;

  ReviewRemoteDataSourceImpl(this.dioClient);

  @override
  Future<void> submitReview({
    required int rating,
    String? comment,
    required String invoiceNumber,
  }) async {
    final String endpoint = ApiConstants.invoiceReview;

    FormData formData = FormData.fromMap({
      "rating": rating,
      if (comment != null && comment.isNotEmpty) "comment": comment,
      "invoiceNumber": invoiceNumber,
    });

    final response = await dioClient.post(endpoint, data: formData);

    if (response.data['code'] != 1000) {
      throw Exception(response.data['msg'] ?? 'Gửi đánh giá thất bại');
    }
  }

  @override
  Future<Map<String, dynamic>> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final String endpoint = '/reviews/create';

    final Map<String, dynamic> body = {
      'bookingId': bookingId,
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    };

    final response = await dioClient.post(endpoint, data: body);
    
    if (response.statusCode == 201 || response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception(response.data['error'] ?? 'Tạo review thất bại');
    }
  }

  @override
  Future<bool> checkIfUserReviewedHotel({
    required int hotelId,
  }) async {
    final String endpoint = '/reviews/check/$hotelId';

    try {
      final response = await dioClient.get(endpoint);
      
      if (response.statusCode == 200) {
        return response.data['hasReviewed'] as bool? ?? false;
      }
      return false;
    } catch (e) {
      // If error, assume not reviewed (allow review)
      return false;
    }
  }
}