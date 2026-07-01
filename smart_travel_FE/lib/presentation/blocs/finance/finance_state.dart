import 'package:equatable/equatable.dart';
import '../../../data/models/finance/finance_host_settlement_model.dart';
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
  final List<FinanceHostSettlementModel> hostSettlements;
  final int selectedYear;
  final int selectedMonth;

  const FinanceLoaded({
    required this.summary,
    this.monthlyData = const [],
    this.hostSettlements = const [],
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  List<Object?> get props => [
    summary,
    monthlyData,
    hostSettlements,
    selectedYear,
    selectedMonth,
  ];
}

class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}
