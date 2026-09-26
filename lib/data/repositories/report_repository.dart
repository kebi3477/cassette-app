import '../../domain/models/report.dart';
import '../../utils/result.dart';
import '../model/report_dto.dart';
import '../services/api/api_client.dart';
import 'friend_repository.dart';
import 'repository_guard.dart';

/// 신고 (`POST /reports` 🔑).
///
/// 오류는 [ApiException]의 `code`로 준다 — `RATE_LIMITED`(하루 한도), `REPORT_TARGET_NOT_FOUND`.
class ReportRepository {
  ReportRepository(this._api, this._friends);

  final ApiClient _api;

  /// 같이 차단하면 친구 목록·차단 목록이 바뀐다
  final FriendRepository _friends;

  Future<Result<void>> report(
    ReportTarget target, {
    required ReportReason reason,
    String? memo,
    required bool alsoBlock,
    required String idempotencyKey,
  }) async {
    final body = switch (target) {
      TapeReport(:final deliveryId) => CreateReportRequest.tape(
        deliveryId: deliveryId,
        reason: reason.code,
        memo: memo,
        alsoBlock: alsoBlock,
      ),
      PersonReport(:final userId) => CreateReportRequest.user(
        userId: userId,
        reason: reason.code,
        memo: memo,
        alsoBlock: alsoBlock,
      ),
    };
    final r = await guard(
      () => _api.createReport(body, idempotencyKey: idempotencyKey),
    );
    if (r is Ok && alsoBlock) _friends.invalidate();
    return r is Ok ? const Result.ok(null) : Result.error((r as Error).error);
  }
}
