import 'dart:io';

import 'package:dio/dio.dart';

import '../model/api_error.dart';
import '../model/recording_dto.dart';
import 'upload_service.dart';

/// 녹음 파일을 저장소에 직접 올린다 (presigned PUT, 계약서 §9).
///
/// `upload.headers`는 서명에 들어가 있으니 **그대로** 붙이고, 본문은 파일 바이트다.
/// 인증 헤더는 붙이지 않는다 (API 서버가 아니라 저장소 주소).
class HttpUploadService implements UploadService {
  HttpUploadService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 15),
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final Dio _dio;

  @override
  Future<void> upload(UploadTicketDto ticket, String filePath) async {
    final file = File(filePath);
    final length = await file.length();
    try {
      await _dio.request<void>(
        ticket.url,
        data: file.openRead(),
        options: Options(
          method: ticket.method,
          headers: {...ticket.headers, Headers.contentLengthHeader: length},
          // 저장소 응답은 JSON이 아닐 수 있다
          responseType: ResponseType.plain,
        ),
      );
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw ApiException.network();
      throw ApiException(
        status: res.statusCode ?? 0,
        code: ApiErrorCode.uploadFailed,
        message: '녹음을 올리지 못했어요. 다시 시도해 주세요',
      );
    }
  }
}
