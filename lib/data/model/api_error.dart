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
  static const tapeNotOpened = 'TAPE_NOT_OPENED';
  static const uploadNotFound = 'UPLOAD_NOT_FOUND';
  static const recordingTooLarge = 'RECORDING_TOO_LARGE';
  static const audioNotReady = 'AUDIO_NOT_READY';
  static const groupNotFound = 'GROUP_NOT_FOUND';
  static const invalidGroupName = 'INVALID_GROUP_NAME';
  static const internalError = 'INTERNAL_ERROR';
  static const insufficientCredits = 'INSUFFICIENT_CREDITS';
  static const invalidGiftAmount = 'INVALID_GIFT_AMOUNT';
  static const productNotFound = 'PRODUCT_NOT_FOUND';
  static const adLimitReached = 'AD_LIMIT_REACHED';
  static const receiptInvalid = 'RECEIPT_INVALID';
  static const receiptPending = 'RECEIPT_PENDING';
  static const receiptAlreadyUsed = 'RECEIPT_ALREADY_USED';
  static const iapUnavailable = 'IAP_UNAVAILABLE';
  static const giftNotAllowed = 'GIFT_NOT_ALLOWED';
  static const linkTaken = 'LINK_TAKEN';
  static const blockNotFound = 'BLOCK_NOT_FOUND';
  static const cannotBlockSelf = 'CANNOT_BLOCK_SELF';
  static const userNotFound = 'USER_NOT_FOUND';
}
