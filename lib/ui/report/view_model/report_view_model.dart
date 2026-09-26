import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../../data/model/api_error.dart';
import '../../../data/repositories/friend_repository.dart';
import '../../../data/repositories/report_repository.dart';
import '../../../domain/models/blocked_user.dart';
import '../../../domain/models/report.dart';
import '../../../utils/idempotency.dart';
import '../../../utils/result.dart';
import '../../core/ui/toast.dart';

/// 신고 시트 (`shReport` · `shReportFail`) — logic.js `report()` · `submitReport()`.
class ReportViewModel extends ChangeNotifier {
  ReportViewModel({
    required this.target,
    required this._reports,
    required this._friends,
    required this._toast,
    bool alreadyBlocked = false,
  }) : _alreadyBlocked = alreadyBlocked {
    if (!alreadyBlocked && target.userId != null) _checkBlocked();
  }

  /// 자세히 적기 최대 글자 수
  static const memoMax = 300;

  final ReportTarget target;
  final ReportRepository _reports;
  final FriendRepository _friends;
  final ToastController _toast;

  ReportReason? _reason;
  String _memo = '';
  bool _block = true;
  bool _busy = false;
  bool _failed = false;
  bool _done = false;
  bool _alreadyBlocked;

  /// 다시 시도해도 한 번만 접수되게 시트마다 키 하나
  final String _key = newIdempotencyKey();

  ReportReason? get reason => _reason;
  String get memo => _memo;
  int get memoLength => _memo.characters.length;
  bool get block => _block;
  bool get busy => _busy;

  /// 네트워크 실패 (`shReportFail`)
  bool get failed => _failed;

  /// 끝났다 — 시트를 닫는다
  bool get done => _done;

  /// `rpSub`: 테이프면 "○○님이 보낸 MM.DD 테이프", 사람이면 "○○님"
  String get subtitle => switch (target) {
    TapeReport(:final name, :final date) => '$name님이 보낸 $date 테이프',
    PersonReport(:final name) => '$name님',
  };

  /// "○○님 차단하기" — 이미 차단한 사람이면(또는 탈퇴해 차단할 수 없으면) 숨긴다.
  bool get canBlock => !_alreadyBlocked && target.userId != null;
  String get blockLabel => '${target.name}님 차단하기';

  /// 사유를 골라야 누를 수 있다 (`rpBg`)
  bool get canSubmit => _reason != null && !_busy;
  String get cta => _busy ? '보내는 중…' : '신고하기';

  Future<void> _checkBlocked() async {
    final r = await _friends.getBlocked();
    if (r case Ok<List<BlockedUser>>(:final value)) {
      if (value.any((b) => b.id == target.userId)) {
        _alreadyBlocked = true;
        notifyListeners();
      }
    }
  }

  void selectReason(ReportReason r) {
    _reason = r;
    notifyListeners();
  }

  void setMemo(String v) {
    _memo = v.characters.take(memoMax).toString();
    notifyListeners();
  }

  void toggleBlock() {
    _block = !_block;
    notifyListeners();
  }

  /// 신고하기 (`submitReport`)
  Future<void> submit() async {
    final reason = _reason;
    if (reason == null || _busy) return;
    _busy = true;
    _failed = false;
    notifyListeners();
    final alsoBlock = canBlock && _block;
    final r = await _reports.report(
      target,
      reason: reason,
      memo: _memo,
      alsoBlock: alsoBlock,
      idempotencyKey: _key,
    );
    _busy = false;
    switch (r) {
      case Ok():
        _finish(alsoBlock ? '신고하고 차단했어요' : '신고가 접수됐어요. 확인 후 조치할게요');
      case Error(:final error):
        _fail(error);
    }
  }

  void _fail(Exception e) {
    if (e is ApiException) {
      if (e.isNetwork || e.isServerError) {
        // 입력한 내용은 그대로 두고 실패 화면 (`shReportFail`)
        _failed = true;
        notifyListeners();
        return;
      }
      switch (e.code) {
        case ApiErrorCode.rateLimited:
          return _finish('오늘은 더 신고할 수 없어요');
        case ApiErrorCode.reportTargetNotFound:
          return _finish(
            target is TapeReport ? '이미 사라진 테이프예요' : '이미 탈퇴한 사람이에요',
          );
      }
      return _finish(e.message);
    }
    _failed = true;
    notifyListeners();
  }

  void _finish(String toast) {
    _done = true;
    notifyListeners();
    _toast.show(toast);
  }

  /// 돌아가기 (`rpBack`) — 적은 내용 그대로 신고 화면
  void back() {
    _failed = false;
    notifyListeners();
  }

  /// 다시 시도 (`rpRetry`)
  Future<void> retry() => submit();
}
