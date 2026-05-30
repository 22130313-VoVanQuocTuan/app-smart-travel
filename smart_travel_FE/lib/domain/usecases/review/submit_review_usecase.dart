import 'package:image_picker/image_picker.dart';

import '../../repositories/review_repository.dart';


class SubmitReviewUseCase {
  final ReviewRepository repository;

  SubmitReviewUseCase(this.repository);

  Future<void> call({
    required int rating,
    String? comment,
    required String invoiceNumber,
  }) async {
    return await repository.submitReview(
      rating: rating,
      comment: comment,
      invoiceNumber: invoiceNumber,
    );
  }
}