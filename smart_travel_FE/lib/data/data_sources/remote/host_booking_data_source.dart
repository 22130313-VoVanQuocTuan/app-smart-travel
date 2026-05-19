import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/core/constants/api_constants.dart';
import 'package:smart_travel/data/models/booking/host_booking_list_model.dart';
import 'package:smart_travel/data/models/booking/booking_response_model.dart';

abstract class HostBookingDataSource {
  Future<List<HostBookingListModel>> getHostBookings();
  Future<HostBookingListModel> getHostBookingDetail(int bookingId);
  Future<List<HostBookingListModel>> getHostBookingsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  });
  Future<void> updateBookingStatus(
    int bookingId,
    String newStatus, {
    String? cancellationReason,
  });
}

class HostBookingDataSourceImpl implements HostBookingDataSource {
  final DioClient client;

  HostBookingDataSourceImpl({required this.client});

  @override
  Future<List<HostBookingListModel>> getHostBookings() async {
    try {
      final response = await client.get(
        '/bookings/host/list',
      );
      
      final data = response.data['data'] as List<dynamic>? ?? response.data as List<dynamic>;
      return (data).map((item) => HostBookingListModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<HostBookingListModel> getHostBookingDetail(int bookingId) async {
    try {
      final response = await client.get('/bookings/$bookingId/detail');
      
      final bookingData = response.data['data'] ?? response.data;
      return HostBookingListModel.fromJson(bookingData as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<HostBookingListModel>> getHostBookingsByDateRange(
    DateTime startDate,
    DateTime endDate, {
    String? status,
  }) async {
    try {
      final queryParams = {
        'startDate': startDate.toIso8601String().split('T')[0],
        'endDate': endDate.toIso8601String().split('T')[0],
        if (status != null && status.isNotEmpty) 'status': status,
      };

      final response = await client.get(
        '/bookings/host/calendar',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as List<dynamic>? ?? response.data as List<dynamic>;
      return (data).map((item) => HostBookingListModel.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> updateBookingStatus(
    int bookingId,
    String newStatus, {
    String? cancellationReason,
  }) async {
    try {
      await client.put(
        '/bookings/$bookingId/status',
        data: {
          'status': newStatus,
          if (cancellationReason != null && cancellationReason.isNotEmpty)
            'cancellationReason': cancellationReason,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}

