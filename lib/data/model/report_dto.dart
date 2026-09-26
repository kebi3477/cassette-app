import 'json.dart';

/// `POST /reports` 🔑 본문 — 계약서 §12-1.
class CreateReportRequest {
  const CreateReportRequest.tape({
    required String this.deliveryId,
    required this.reason,
    this.memo,
    this.alsoBlock = false,
  }) : userId = null;

  const CreateReportRequest.user({
    required String this.userId,
    required this.reason,
    this.memo,
    this.alsoBlock = false,
  }) : deliveryId = null;

  final String? deliveryId;
  final String? userId;

  /// `harassment` · `sexual` · `spam` · `illegal` · `impersonation` · `other`
  final String reason;

  /// 최대 300자. 비우면 보내지 않는다.
  final String? memo;
  final bool alsoBlock;

  Json toJson() {
    final m = memo?.trim();
    return {
      'target': deliveryId != null
          ? {'type': 'tape', 'deliveryId': deliveryId}
          : {'type': 'user', 'userId': userId},
      'reason': reason,
      if (m != null && m.isNotEmpty) 'memo': m,
      'alsoBlock': alsoBlock,
    };
  }
}

/// `201 { id, createdAt }` — 24시간 안 같은 대상이면 기존 신고
class ReportResultDto {
  const ReportResultDto({required this.id, required this.createdAt});

  final String id;
  final DateTime createdAt;

  factory ReportResultDto.fromJson(Json j) => ReportResultDto(
    id: j['id'] as String,
    createdAt: parseDate(j['createdAt']),
  );
}
