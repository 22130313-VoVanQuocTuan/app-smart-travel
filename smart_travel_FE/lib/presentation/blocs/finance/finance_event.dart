import 'package:equatable/equatable.dart';

abstract class FinanceEvent extends Equatable {
  const FinanceEvent();

  @override
  List<Object?> get props => [];
}

class GetFinanceSummaryEvent extends FinanceEvent {
  final String? startDate;
  final String? endDate;
  final String? groupBy;
  final int? year;
  final int? quarter;

  const GetFinanceSummaryEvent({
    this.startDate,
    this.endDate,
    this.groupBy,
    this.year,
    this.quarter,
  });

  @override
  List<Object?> get props => [startDate, endDate, groupBy, year, quarter];
}
