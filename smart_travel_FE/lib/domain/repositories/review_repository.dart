import 'package:image_picker/image_picker.dart';

abstract class ReviewRepository {
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