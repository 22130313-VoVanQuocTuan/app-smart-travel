import 'package:equatable/equatable.dart';
import 'package:smart_travel/data/models/statistics/dashboard_stats.dart';
import 'package:smart_travel/data/models/statistics/revenue_data.dart';
import 'package:smart_travel/data/models/statistics/category_revenue_data.dart';

abstract class StatisticsState extends Equatable {
  const StatisticsState();

  @override
  List<Object?> get props => [];
}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final DashboardStats stats;

  const StatisticsLoaded(this.stats);

  @override
  List<Object?> get props => [stats];
}

class StatisticsError extends StatisticsState {
  final String message;

  const StatisticsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Thống kê doanh thu
class RevenueLoading extends StatisticsState {}

class RevenueLoaded extends StatisticsState {
  final RevenueData revenueData;

  const RevenueLoaded(this.revenueData);

  @override
  List<Object?> get props => [revenueData];
}

class RevenueError extends StatisticsState {
  final String message;

  const RevenueError(this.message);

  @override
  List<Object?> get props => [message];
}

// Thống kê doanh thu của chủ homestay theo danh mục
class CategoryRevenueLoading extends StatisticsState {}

class CategoryRevenueLoaded extends StatisticsState {
  final CategoryRevenueData categoryData;

  const CategoryRevenueLoaded(this.categoryData);

  @override
  List<Object?> get props => [categoryData];
}

class CategoryRevenueError extends StatisticsState {
  final String message;

  const CategoryRevenueError(this.message);

  @override
  List<Object?> get props => [message];
}
