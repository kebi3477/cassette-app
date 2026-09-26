/// 신고 사유 — 디자인 문구 순서 (`rpReasons`), 서버 코드는 계약서 §12-1.
enum ReportReason {
  harassment('괴롭힘·혐오 표현'),
  sexual('성적인 내용'),
  spam('스팸·광고'),
  illegal('불법·권리 침해'),
  impersonation('사칭'),
  other('기타');

  const ReportReason(this.label);

  final String label;

  /// 서버 코드
  String get code => name;
}

/// 신고 대상 — 디자인 `target: 'tape' | 'person'` (서버는 `tape` · `user`)
sealed class ReportTarget {
  const ReportTarget();

  /// 차단 대상 이름 ("○○님 차단하기")
  String get name;

  /// 차단 대상 userId. 보낸 사람이 탈퇴했으면 null (차단할 수 없다)
  String? get userId;
}

/// 받은 테이프 — 보낸 사람을 차단 대상으로
class TapeReport extends ReportTarget {
  const TapeReport({
    required this.deliveryId,
    required this.name,
    required this.userId,
    required this.date,
  });

  final String deliveryId;
  @override
  final String name;
  @override
  final String? userId;

  /// 보낸 날짜 (`MM.DD`)
  final String date;
}

/// 사람
class PersonReport extends ReportTarget {
  const PersonReport({required this.userId, required this.name});

  @override
  final String userId;
  @override
  final String name;
}
