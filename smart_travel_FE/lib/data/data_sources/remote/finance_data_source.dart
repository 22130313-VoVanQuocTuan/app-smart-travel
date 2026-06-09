import 'package:dio/dio.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/core/constants/api_constants.dart';
import '../../models/finance/finance_monthly_model.dart';
import '../../models/finance/finance_summary_model.dart';

abstract class FinanceDataSource {
  Future<FinanceSummaryModel> getSummary({
    int? year,
    String? startDate,
    String? endDate,
    String? groupBy,
    int? quarter,
  });
  Future<List<FinanceMonthlyModel>> getMonthlyData({
    int? year,
    String? startDate,
    String? endDate,
    String? groupBy,
    int? quarter,
  });
  Future<List<int>> exportPdf({
    String? startDate,
    String? endDate,
    String? groupBy,
    int? year,
    int? quarter,
  });
}

class FinanceDataSourceImpl implements FinanceDataSource {
  final DioClient dioClient;

  FinanceDataSourceImpl({
    required this.dioClient,
  });

  @override
  Future<FinanceSummaryModel> getSummary({
    int? year,
    String? startDate,
    String? endDate,
    String? groupBy,
    int? quarter,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (year != null) queryParameters['year'] = year;
    if (startDate != null) queryParameters['startDate'] = startDate;
    if (endDate != null) queryParameters['endDate'] = endDate;
    if (groupBy != null) queryParameters['groupBy'] = groupBy;
    if (quarter != null) queryParameters['quarter'] = quarter;

    final response = await dioClient.get(
      ApiConstants.financeSummary,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    return FinanceSummaryModel.fromJson(
      response.data['data'],
    );
  }

  @override
  Future<List<FinanceMonthlyModel>> getMonthlyData({
    int? year,
    String? startDate,
    String? endDate,
    String? groupBy,
    int? quarter,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (year != null) queryParameters['year'] = year;
    if (startDate != null) queryParameters['startDate'] = startDate;
    if (endDate != null) queryParameters['endDate'] = endDate;
    if (groupBy != null) queryParameters['groupBy'] = groupBy;
    if (quarter != null) queryParameters['quarter'] = quarter;

    final response = await dioClient.get(
      ApiConstants.financeMonthly,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final data = response.data['data'] as List<dynamic>;
    return data
        .map((item) => FinanceMonthlyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<int>> exportPdf({
    String? startDate,
    String? endDate,
    String? groupBy,
    int? year,
    int? quarter,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (startDate != null) queryParameters['startDate'] = startDate;
    if (endDate != null) queryParameters['endDate'] = endDate;
    if (groupBy != null) queryParameters['groupBy'] = groupBy;
    if (year != null) queryParameters['year'] = year;
    if (quarter != null) queryParameters['quarter'] = quarter;

    final response = await dioClient.dio.get(
      ApiConstants.financePdf,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'Accept': 'application/pdf',
        },
      ),
    );

    return response.data;
  }
}