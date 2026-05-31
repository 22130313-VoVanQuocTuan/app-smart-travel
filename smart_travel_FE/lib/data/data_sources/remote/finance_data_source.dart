import 'package:dio/dio.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/core/constants/api_constants.dart';
import '../../models/finance/finance_monthly_model.dart';
import '../../models/finance/finance_summary_model.dart';

abstract class FinanceDataSource {
  Future<FinanceSummaryModel> getSummary();
  Future<List<FinanceMonthlyModel>> getMonthlyData(int year);
  Future<List<int>> exportPdf();
}

class FinanceDataSourceImpl implements FinanceDataSource {
  final DioClient dioClient;

  FinanceDataSourceImpl({
    required this.dioClient,
  });

  @override
  Future<FinanceSummaryModel> getSummary() async {
    final response = await dioClient.get(
      ApiConstants.financeSummary,
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
  Future<List<int>> exportPdf() async {
    final response = await dioClient.dio.get(
      ApiConstants.financePdf,
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