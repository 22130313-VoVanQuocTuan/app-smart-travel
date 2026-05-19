// lib/core/services/booking_service.dart
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/data/models/booking/booking_model.dart';

class BookingService {
  final DioClient _dioClient;

  BookingService(this._dioClient);

  /// Lấy danh sách booking của host
  Future<List<HostBooking>> getHostBookings() async {
    try {
      final response = await _dioClient.get('/bookings/host/list');

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => HostBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy danh sách booking theo khoảng thời gian
  Future<List<HostBooking>> getHostBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    String? status,
  }) async {
    try {
      final response = await _dioClient.get(
        '/bookings/host/calendar',
        queryParameters: {
          'startDate': DateFormat('yyyy-MM-dd').format(startDate),
          'endDate': DateFormat('yyyy-MM-dd').format(endDate),
          if (status != null) 'status': status,
        },
      );

      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => HostBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy chi tiết booking
  Future<BookingDetail> getBookingDetail(int bookingId) async {
    try {
      final response = await _dioClient.get('/bookings/$bookingId/detail');

      if (response.data != null && response.data['data'] != null) {
        return BookingDetail.fromJson(response.data['data']);
      }
      throw Exception('Không tìm thấy chi tiết booking');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cập nhật trạng thái booking
  Future<void> updateBookingStatus({
    required int bookingId,
    required String status,
    String? cancellationReason,
  }) async {
    try {
      await _dioClient.put(
        '/bookings/$bookingId/status',
        data: {
          'status': status,
          if (cancellationReason != null) 'cancellationReason': cancellationReason,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response?.data != null) {
        return error.response?.data['msg'] ?? error.message;
      }
      return error.message;
    }
    return error.toString();
  }
}