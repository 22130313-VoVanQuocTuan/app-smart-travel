// lib/data/services/homestay_service.dart
import 'package:dio/dio.dart';
import 'package:smart_travel/core/error/exceptions.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/domain/entities/homestay.dart';

class HomestayService {
  final DioClient _dioClient;

  HomestayService(this._dioClient);

  Future<Map<String, dynamic>> getHomestays({
    String? keyword,
    int? destinationId,
    int? minStars,
    int? maxStars,
    double? minPrice,
    double? maxPrice,    String? city,
    int page = 0,
    int size = 10,
    String sortBy = 'pricePerNight',
    String sortDir = 'asc',
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (destinationId != null) queryParams['destinationId'] = destinationId;
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
      if (minStars != null) queryParams['minStars'] = minStars;
      if (maxStars != null) queryParams['maxStars'] = maxStars;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (city != null && city.isNotEmpty) queryParams['city'] = city;
      queryParams['page'] = page;
      queryParams['size'] = size;
      queryParams['sortBy'] = sortBy;
      queryParams['sortDir'] = sortDir;

      final response = await _dioClient.get(
        '/homestays',
          queryParameters: queryParams,
      );

      return {
        'content': (response.data['content'] as List)
            .map((item) => Homestay.fromJson(item))
            .toList(),
        'totalPages': response.data['totalPages'] ?? 0,
        'totalElements': response.data['totalElements'] ?? 0,
        'currentPage': response.data['number'] ?? 0,
      };
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy danh sách homestay (có filter)
  Future<Map<String, dynamic>> getMyHomestays({
    String? keyword,
    int page = 0,
    int size = 10,
    String sortBy = 'id',
    String sortDir = 'asc',
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (keyword != null && keyword.isNotEmpty) queryParams['keyword'] = keyword;
      queryParams['page'] = page;
      queryParams['size'] = size;
      queryParams['sortBy'] = sortBy;
      queryParams['sortDir'] = sortDir;

      final response = await _dioClient.get(
        '/homestays/owner/my-homestays',
        options: Options(extra: {'queryParams': queryParams}),
      );

      // API trả về List<Homestay> trực tiếp
      final List data = response.data['data'] as List? ?? [];
      return {
        'content': data.map((item) => Homestay.fromJson(item)).toList(),
        'totalPages': 1, // Vì API trả về list, không phân trang
        'totalElements': data.length,
        'currentPage': 0,
      };
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy chi tiết homestay
  Future<Homestay> getHomestayDetail(
      int homestayId, {
        required DateTime checkIn,
        required DateTime checkOut,
      }) async {
    try {
      final response = await _dioClient.get(
        '/homestays/$homestayId/detail',
        options: Options(
          extra: {
            'queryParams': {
              'checkIn': checkIn.toIso8601String().split('T').first,
              'checkOut': checkOut.toIso8601String().split('T').first,
            },
          },
        ),
      );

      final Map<String, dynamic> data;
      if (response.data['data'] is Map<String, dynamic>) {
        data = response.data['data'] as Map<String, dynamic>;
      } else {
        data = response.data as Map<String, dynamic>;
      }

      return Homestay.fromJson(data);
    } catch (e) {
      throw _handleError(e);
    }
  }



  // Tạo homestay mới
  Future<void> createHomestayWithFiles(FormData formData) async {
    try {
      await _dioClient.post(
        '/homestays',
        data: formData,

      );
    } catch (e) {
      throw _handleError(e);
    }
  }


  // Cập nhật homestay
  Future<void> updateHomestayWithFiles(int id, FormData formData) async {
    try {
      await _dioClient.put(
        '/homestays/$id',
        data: formData,

      );
    }  on DioException catch (e) {
      if (e.error is ServerException) {
        throw e.error as ServerException;
      }
      throw ServerException(e.message ?? 'Lỗi khi cập nhật homestay');
    }
  }

  // Xóa homestay
  Future<void> deleteHomestay(int id) async {
    try {
      await _dioClient.delete('/homestays/$id');
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy danh sách tour kèm theo
  Future<List<dynamic>> getAvailableTours(int homestayId, DateTime checkIn, DateTime checkOut) async {
    try {
      final response = await _dioClient.get(
        '/homestays/$homestayId/available-tours',
        options: Options(
            extra: {
              'queryParams': {
                'checkIn': checkIn.toIso8601String().split('T').first,
                'checkOut': checkOut.toIso8601String().split('T').first,
              }
            }
        ),
      );
      return response.data['data'] as List? ?? [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Kiểm tra phòng trống
  Future<bool> checkAvailability(
      int homestayId,
      int roomTypeId,
      DateTime checkIn,
      DateTime checkOut,
      int numberOfRooms,
      ) async {
    try {
      final response = await _dioClient.get(
        '/homestays/$homestayId/check-availability',
        options: Options(
            extra: {
              'queryParams': {
                'checkIn': checkIn.toIso8601String().split('T').first,
                'checkOut': checkOut.toIso8601String().split('T').first,
                'numberOfRooms': numberOfRooms,
                'roomTypeId': roomTypeId,
              }
            }
        ),
      );
      return response.data['data'] ?? false;
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy homestay nổi bật
  Future<List<Homestay>> getFeaturedHomestays({int limit = 5}) async {
    try {
      final response = await _dioClient.get('/homestays/featured', options: Options(
          extra: {'queryParams': {'limit': limit}}
      ));
      final data = response.data['data'] as List? ?? [];
      return data.map((item) => Homestay.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy homestay có doanh thu cao nhất (top revenue)
  Future<List<Homestay>> getTopRevenueHomestays({int limit = 5}) async {
    try {
      final response = await _dioClient.get('/homestays/top-revenue', options: Options(
          extra: {'queryParams': {'limit': limit}}
      ));
      final data = response.data['data'] as List? ?? [];
      return data.map((item) => Homestay.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Lấy homestay theo destination
  Future<List<Homestay>> getHomestaysByDestination(int destinationId) async {
    try {
      final response = await _dioClient.get('/homestays/destination/$destinationId');
      final data = response.data['data'] as List? ?? [];
      return data.map((item) => Homestay.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  // Tìm kiếm theo khoảng giá
  Future<List<Homestay>> getHomestaysByPriceRange(double minPrice, double maxPrice) async {
    try {
      final response = await _dioClient.get('/homestays/search/price-range', options: Options(
          extra: {'queryParams': {'minPrice': minPrice, 'maxPrice': maxPrice}}
      ));
      final data = response.data['data'] as List? ?? [];
      return data.map((item) => Homestay.fromJson(item)).toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  dynamic _handleError(dynamic error) {
    if (error is DioException) {
      if (error.error is ServerException) {
        return error.error;
      }
      return ServerException(error.message ?? 'Lỗi kết nối');
    }
    return ServerException('Có lỗi xảy ra');
  }
}