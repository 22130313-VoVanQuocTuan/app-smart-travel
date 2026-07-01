import 'package:dio/dio.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/core/constants/api_constants.dart';
import '../../models/finance/finance_host_settlement_model.dart';
import '../../models/finance/finance_monthly_model.dart';
import '../../models/finance/finance_summary_model.dart';

abstract class FinanceDataSource {
  Future<FinanceSummaryModel> getSummary({int? year, int? month});
  Future<List<FinanceMonthlyModel>> getMonthlyData(int year);
  Future<List<FinanceHostSettlementModel>> getHostSettlements({
    required int year,
    required int month,
  });
  Future<List<int>> exportPdf({int? year, int? month});
}

class FinanceDataSourceImpl implements FinanceDataSource {
  final DioClient dioClient;

  FinanceDataSourceImpl({
    required this.dioClient,
  });

  @override
  Future<FinanceSummaryModel> getSummary({int? year, int? month}) async {
    final response = await dioClient.get(
      ApiConstants.financeSummary,
      queryParameters: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
    );

    return FinanceSummaryModel.fromJson(
      response.data['data'],
    );
  }

  @override
  Future<List<FinanceMonthlyModel>> getMonthlyData(int year) async {
    final response = await dioClient.get(
      '${ApiConstants.financeMonthly}?year=$year',
    );

    final data = response.data['data'] as List<dynamic>;
    return data
        .map((item) => FinanceMonthlyModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<FinanceHostSettlementModel>> getHostSettlements({
    required int year,
    required int month,
  }) async {
    final response = await dioClient.get(
      ApiConstants.financeHostSettlements,
      queryParameters: {
        'year': year,
        'month': month,
      },
    );

    final data = response.data['data'] as List<dynamic>;
    return data
        .map((item) => FinanceHostSettlementModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<int>> exportPdf({int? year, int? month}) async {
    final response = await dioClient.dio.get(
      ApiConstants.financePdf,
      queryParameters: {
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
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
