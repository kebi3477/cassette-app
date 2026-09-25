import 'json.dart';

/// 계약서 §1 오류 형식 `{ code, message, …추가 필드 }`. 앱은 `code`로 분기한다.
class ApiException implements Exception {
  const ApiException({
    required this.status,
    required this.code,
    required this.message,
    this.extra = const {},
  });

  factory ApiException.fromJson(int status, Json j) => ApiException(
    status: status,
    code: j['code'] as String,
    message: j['message'] as String,
    extra: {
      for (final e in j.entries)
        if (e.key != 'code' && e.key != 'message') e.key: e.value,
    },
  );

  final int status;
  final String code;
  final String message;

  /// 예: `need`, `tapeType`, `status`, `deliveryId`, `url`
  final Json extra;

  @override
  String toString() => 'ApiException($status $code: $message)';
}

/// 계약서 §3 오류 코드 중 앱이 분기하는 것.
abstract final class ApiErrorCode {
  static const notFound = 'NOT_FOUND';
  static const validationFailed = 'VALIDATION_FAILED';
  static const friendNotFound = 'FRIEND_NOT_FOUND';
  static const noTapeLeft = 'NO_TAPE_LEFT';
  static const recordingNotFound = 'RECORDING_NOT_FOUND';
  static const recordingNotReady = 'RECORDING_NOT_READY';
  static const recordingTooLong = 'RECORDING_TOO_LONG';
  static const recordingAlreadySent = 'RECORDING_ALREADY_SENT';
  static const notFriend = 'NOT_FRIEND';
  static const tapeNotFound = 'TAPE_NOT_FOUND';
  static const audioNotReady = 'AUDIO_NOT_READY';
  static const groupNotFound = 'GROUP_NOT_FOUND';
  static const invalidGroupName = 'INVALID_GROUP_NAME';
  static const internalError = 'INTERNAL_ERROR';
}
