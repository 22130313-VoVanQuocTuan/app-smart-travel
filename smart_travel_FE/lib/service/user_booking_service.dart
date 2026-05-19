// lib/core/services/user_booking_service.dart
import 'package:dio/dio.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/data/models/booking/cancellation_policy_response.dart';
import 'package:smart_travel/data/models/user/user_booking_model.dart';

class UserBookingService {
  final DioClient _dioClient;

  UserBookingService(this._dioClient);

  // Lấy tất cả booking của user
  Future<List<UserBooking>> getUserBookings() async {
    try {
      final response = await _dioClient.get('/bookings/user/list');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => UserBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy booking hiện tại (chưa kết thúc)
  Future<List<UserBooking>> getCurrentBookings() async {
    try {
      final response = await _dioClient.get('/bookings/user/current');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => UserBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy lịch sử booking (đã kết thúc)
  Future<List<UserBooking>> getBookingHistory() async {
    try {
      final response = await _dioClient.get('/bookings/user/history');
      if (response.data != null && response.data['data'] != null) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => UserBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Tìm booking theo ID hoặc mã QR
  Future<UserBooking?> findBookingByQR(String qrData) async {
    try {
      final response = await _dioClient.get('/bookings/find-by-qr?qr=$qrData');
      if (response.data != null && response.data['data'] != null) {
        return UserBooking.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Hủy booking
  Future<void> cancelBooking(int bookingId, String reason) async {
    try {
      await _dioClient.put(
        '/bookings/user/cancel/$bookingId',
        data: {'reason': reason},
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy chi tiết booking
  Future<UserBooking> getBookingDetail(int bookingId) async {
    try {
      final response = await _dioClient.get('/bookings/user/detail/$bookingId');
      if (response.data != null && response.data['data'] != null) {
        return UserBooking.fromJson(response.data['data']);
      }
      throw Exception('Không tìm thấy booking');
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleError(dynamic error) {
    if (error is DioException) {
      return error.response?.data['msg'] ?? error.message;
    }
    return error.toString();
  }

  /// Lấy thông tin chính sách hủy cho booking
  Future<CancellationPolicyResponse> getCancellationPolicy(int bookingId) async {
    try {
      final response = await _dioClient.get(
        '/bookings/user/cancellation-policy/$bookingId',
      );

      if (response.data != null && response.data['data'] != null) {
        return CancellationPolicyResponse.fromJson(response.data['data']);
      }
      throw Exception('Không thể lấy thông tin chính sách hủy');
    } catch (e) {
      throw _handleError(e);
    }
  }
}