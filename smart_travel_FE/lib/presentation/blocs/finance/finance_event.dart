import 'package:equatable/equatable.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class GetFinanceSummaryEvent extends FinanceEvent {
  final int? year;
  final int? month;

  const GetFinanceSummaryEvent({
    this.year,
    this.month,
  });

  @override
  List<Object?> get props => [year, month];
}
