import '../../repositories/review_repository.dart';

class CreateReviewUseCase {
  final ReviewRepository repository;

  CreateReviewUseCase(this.repository);

  Future<Map<String, dynamic>> call({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    return await repository.createReview(
      bookingId: bookingId,
      rating: rating,
      comment: comment,
    );
  }
}

