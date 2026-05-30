import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_travel/presentation/blocs/review/submit_review_event.dart';
import 'package:smart_travel/presentation/blocs/review/submit_review_state.dart';
import '../../../domain/usecases/review/submit_review_usecase.dart';
import '../../../domain/usecases/review/create_review_usecase.dart';

class SubmitReviewBloc extends Bloc<SubmitReviewEvent, SubmitReviewState> {
  final SubmitReviewUseCase submitUseCase;
  final CreateReviewUseCase createReviewUseCase;

  SubmitReviewBloc(this.submitUseCase, this.createReviewUseCase) : super(SubmitReviewInitial()) {
    on<SubmitReview>((event, emit) async {
      emit(SubmitReviewLoading());
      try {
        await submitUseCase(
          rating: event.rating,
          comment: event.comment,
          invoiceNumber: event.invoiceNumber,
        );
        emit(SubmitReviewSuccess());
      } catch (e) {
        emit(SubmitReviewError(e.toString()));
      }
    });

    on<CreateReviewEvent>((event, emit) async {
      emit(SubmitReviewLoading());
      try {
        await createReviewUseCase(
          bookingId: event.bookingId,
          rating: event.rating,
          comment: event.comment,
        );
        emit(SubmitReviewSuccess());
      } catch (e) {
        emit(SubmitReviewError(e.toString()));
      }
    });
  }
}

