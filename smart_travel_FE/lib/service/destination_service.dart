// lib/data/services/destination_service.dart
import 'package:dio/dio.dart';
import 'package:smart_travel/core/error/exceptions.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/domain/entities/destination.dart';

class DestinationService {
  final DioClient _dioClient;

  DestinationService(this._dioClient);

  // Lấy tất cả destinations
  Future<List<Destination>> getAllDestinations() async {
    try {
      final response = await _dioClient.get('/destination/destination-all');
      final List data = response.data['data'] as List? ?? [];
      return data.map((item) => Destination.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleError(dynamic error) {
    if (error is DioException) {
      return ServerException(error.message ?? 'Lỗi kết nối');
    }
    return ServerException('Có lỗi xảy ra');
  }
}