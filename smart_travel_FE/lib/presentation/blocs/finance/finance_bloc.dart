import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/data_sources/remote/finance_data_source.dart';
import '../../../data/models/finance/finance_monthly_model.dart';
import 'finance_event.dart';
import 'finance_state.dart';

class FinanceBloc extends Bloc<FinanceEvent, FinanceState> {

  final FinanceDataSource financeDataSource;

  FinanceBloc({
    required this.financeDataSource,
  }) : super(FinanceInitial()) {

    on<GetFinanceSummaryEvent>(_onGetSummary);
  }

  Future<void> _onGetSummary(
      GetFinanceSummaryEvent event,
      Emitter<FinanceState> emit,
      ) async {

    try {

      emit(FinanceLoading());

      final summary = await financeDataSource.getSummary(
        year: event.year,
        startDate: event.startDate,
        endDate: event.endDate,
        groupBy: event.groupBy,
        quarter: event.quarter,
      );

      final currentYear = DateTime.now().year;
      List<FinanceMonthlyModel> monthlyData = [];

      try {
        monthlyData = await financeDataSource.getMonthlyData(
          year: event.year ?? currentYear,
          startDate: event.startDate,
          endDate: event.endDate,
          groupBy: event.groupBy,
        );
      } catch (_) {
        monthlyData = [];
      }

      emit(FinanceLoaded(
        summary: summary,
        monthlyData: monthlyData,
      ));

    } catch (e) {

      emit(FinanceError(e.toString()));
    }
  }
}