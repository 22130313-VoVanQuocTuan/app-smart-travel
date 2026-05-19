// service/room_service.dart
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:smart_travel/core/network/dio_client.dart';

class RoomService {
  final DioClient _dioClient;

  RoomService(this._dioClient);

  // Kiểm tra số phòng còn trống theo ngày
  Future<int> getAvailableRooms({
    required int roomTypeId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    try {
      final response = await _dioClient.get(
        '/room-types/$roomTypeId/availability',
        queryParameters: {
          'checkIn': DateFormat('yyyy-MM-dd').format(checkIn),
          'checkOut': DateFormat('yyyy-MM-dd').format(checkOut),
        },
      );
      return response.data['availableRooms'] ?? 0;
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