import 'package:equatable/equatable.dart';
import '../../../data/models/finance/finance_monthly_model.dart';
import '../../../data/models/finance/finance_summary_model.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

class FinanceInitial extends FinanceState {}

class FinanceLoading extends FinanceState {}

class FinanceLoaded extends FinanceState {
  final FinanceSummaryModel summary;
  final List<FinanceMonthlyModel> monthlyData;

  const FinanceLoaded({
    required this.summary,
    this.monthlyData = const [],
  });

  @override
  List<Object?> get props => [summary, monthlyData];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}