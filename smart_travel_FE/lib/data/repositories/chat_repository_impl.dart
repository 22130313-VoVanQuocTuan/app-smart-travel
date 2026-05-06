import 'dart:io';

import 'package:dio/dio.dart';
import 'package:smart_travel/core/constants/api_constants.dart';
import 'package:smart_travel/core/network/dio_client.dart';

class ChatRepository {
  final DioClient _dio ;

  ChatRepository(this._dio);

  Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      final response = await _dio.post(
        ApiConstants.chatAsk,
        data: {"prompt": message},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data['data'] as Map<String, dynamic>? ?? data;
      }
      return {"message": "Không có phản hồi từ Server", "suggestions": []};

    } catch (e) {
      throw Exception("Lỗi kết nối Chat AI: $e");
    }
  }
}