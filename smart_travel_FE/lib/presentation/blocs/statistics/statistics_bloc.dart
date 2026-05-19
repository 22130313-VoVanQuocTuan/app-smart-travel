import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_travel/domain/repositories/statistics_repository.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_event.dart';
import 'package:smart_travel/presentation/blocs/statistics/statistics_state.dart';

class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticsRepository repository;

  StatisticsBloc({required this.repository}) : super(StatisticsInitial()) {
    on<LoadDashboardStats>(_onLoadDashboardStats);
    on<LoadHostDashboardStats>(_onLoadHostDashboardStats);
    on<LoadSystemRevenue>(_onLoadSystemRevenue);
    on<LoadHostRevenue>(_onLoadHostRevenue);
    on<LoadHostRevenueByRange>(_onLoadHostRevenueByRange);
    on<LoadHostRevenueByCategory>(_onLoadHostRevenueByCategory);
  }

  Future<void> _onLoadDashboardStats(
    LoadDashboardStats event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    final result = await repository.getDashboardStats();
    result.fold(
      (failure) => emit(StatisticsError(failure.message)),
      (stats) => emit(StatisticsLoaded(stats)),
    );
  }

  Future<void> _onLoadHostDashboardStats(
    LoadHostDashboardStats event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(StatisticsLoading());
    final result = await repository.getHostDashboardStats(event.hostId);
    result.fold(
      (failure) => emit(StatisticsError(failure.message)),
      (stats) => emit(StatisticsLoaded(stats)),
    );
  }

  Future<void> _onLoadSystemRevenue(
    LoadSystemRevenue event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(RevenueLoading());
    final result = await repository.getSystemRevenue(event.type, event.year, event.month);
    result.fold(
      (failure) => emit(RevenueError(failure.message)),
      (data) => emit(RevenueLoaded(data)),
    );
  }

  Future<void> _onLoadHostRevenue(
    LoadHostRevenue event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(RevenueLoading());
    final result = await repository.getHostRevenue(event.hostId, event.type, event.year, event.month);
    result.fold(
      (failure) => emit(RevenueError(failure.message)),
      (data) => emit(RevenueLoaded(data)),
    );
  }

  Future<void> _onLoadHostRevenueByRange(
    LoadHostRevenueByRange event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(RevenueLoading());
    final result = await repository.getHostRevenueByRange(event.hostId, event.startDate, event.endDate);
    result.fold(
      (failure) => emit(RevenueError(failure.message)),
      (data) => emit(RevenueLoaded(data)),
    );
  }

  Future<void> _onLoadHostRevenueByCategory(
    LoadHostRevenueByCategory event,
    Emitter<StatisticsState> emit,
  ) async {
    emit(CategoryRevenueLoading());
    final result = await repository.getHostRevenueByCategory(event.hostId, event.year, event.month);
    result.fold(
      (failure) => emit(CategoryRevenueError(failure.message)),
      (data) => emit(CategoryRevenueLoaded(data)),
    );
  }
}
