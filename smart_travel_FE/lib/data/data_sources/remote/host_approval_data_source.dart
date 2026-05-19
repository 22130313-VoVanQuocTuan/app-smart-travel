import 'package:dio/dio.dart';
import 'package:smart_travel/core/error/exceptions.dart';
import 'package:smart_travel/core/network/dio_client.dart';
import 'package:smart_travel/data/models/admin/host_approval_response_model.dart';

abstract class HostApprovalDataSource {
  Future<List<HostApprovalResponseModel>> getPendingHosts({int page, int size});
  Future<void> approveHost(int userId);
  Future<void> rejectHost(int userId, String reason);
}

class HostApprovalDataSourceImpl implements HostApprovalDataSource {
  final DioClient dioClient;

  HostApprovalDataSourceImpl({required this.dioClient});

  @override
  Future<List<HostApprovalResponseModel>> getPendingHosts({int page = 0, int size = 10}) async {
    try {
      final response = await dioClient.get('/admin/host-approval/pending?page=$page&size=$size');

      final data = response.data;
      final payload = data is Map<String, dynamic> && data['data'] != null ? data['data'] : data;

      final content = (payload as Map<String, dynamic>)['content'] as List<dynamic>? ?? const [];
      return content
          .map((e) => HostApprovalResponseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.error is ServerException) throw e.error as ServerException;
      throw ServerException(e.message ?? 'Lỗi khi tải danh sách HOST chờ duyệt');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> approveHost(int userId) async {
    try {
      await dioClient.post('/admin/host-approval/approve?userId=$userId');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Lỗi khi duyệt HOST');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> rejectHost(int userId, String reason) async {
    try {
      await dioClient.post('/admin/host-approval/reject?userId=$userId&reason=${Uri.encodeComponent(reason)}');
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Lỗi khi từ chối HOST');
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}


