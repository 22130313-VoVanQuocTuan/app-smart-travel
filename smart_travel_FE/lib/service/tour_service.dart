// service/tour_service.dart
import 'package:dio/dio.dart';
import 'package:smart_travel/core/network/dio_client.dart';

class TourService {
  final DioClient _dioClient;

  TourService(this._dioClient);

  // Lấy danh sách tour của homestay
  Future<List<dynamic>> getToursByHomestay(int homestayId) async {
    try {
      final response = await _dioClient.get('/host/tours/homestay/$homestayId');
      final data = response.data['data'] as List? ?? [];
      return data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  Future<Map<String, dynamic>> getTourDetail(int id) async {
    try {
      final response = await _dioClient.get('/host/tours/$id');
      return response.data['data'] as Map<String, dynamic>;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Tạo tour mới
  Future<void> createTour(FormData formData) async {
    try {
      await _dioClient.post('/host/tours', data: formData);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Cập nhật tour
  Future<void> updateTour(int id, FormData formData) async {
    try {
      await _dioClient.put('/host/tours/$id', data: formData);
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Xóa tour
  Future<void> deleteTour(int id) async {
    try {
      await _dioClient.delete('/host/tours/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleError(dynamic error) {
    if (error is DioException) {
      return error.error ?? error.message;
    }
    return error;
  }
}