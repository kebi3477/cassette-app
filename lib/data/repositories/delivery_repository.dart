import '../../domain/models/recipient.dart';
import '../../domain/models/sent_tape.dart';
import '../../domain/models/tape_tag.dart';
import '../../utils/result.dart';

/// 테이프 보내기와 보낸 기록 (`/deliveries`).
abstract class DeliveryRepository {
  /// 녹음을 [to]에게 보낸다. 3분·5분은 서버가 보유 테이프를 1개 줄인다.
  ///
  /// [to]가 새 친구면 `linkName`으로 링크를 만들고 [SentTape.shareUrl]에 담아 준다.
  /// 같은 [idempotencyKey]로 다시 부르면 두 번 보내지 않는다.
  Future<Result<SentTape>> send({
    required String recordingId,
    required Recipient to,
    required TapeTag tag,
    required String idempotencyKey,
  });

  Future<Result<List<SentTape>>> getSent();
}
