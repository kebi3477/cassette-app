import '../../domain/models/recipient.dart';
import '../../domain/models/sent_tape.dart';
import '../../utils/result.dart';

/// 테이프 보내기와 보낸 기록 (`/deliveries`).
abstract class DeliveryRepository {
  /// 녹음을 [to]에게 보낸다. 1분·3분은 서버가 보유 테이프를 1개 줄인다.
  ///
  /// [to]가 새 친구면 `linkName`으로 링크를 만들고 [SentTape.shareUrl]에 담아 준다.
  /// 같은 [idempotencyKey]로 다시 부르면 두 번 보내지 않는다.
  Future<Result<SentTape>> send({
    required String recordingId,
    required Recipient to,
    required String idempotencyKey,
  });

  /// 보낸 테이프 한 페이지 (최근 순, `GET /deliveries/sent?cursor=`)
  Future<Result<SentPage>> getSent({String? cursor});

  /// 보낸 테이프 하나 (`GET /deliveries/sent/{id}`) — "테이프를 받았어요" 푸시에서
  Future<Result<SentTape>> getSentOne(String id);

  /// 링크 다시 공유하기 (`POST /deliveries/sent/{id}/share`). 만료됐으면 새 링크.
  Future<Result<Uri>> reshare(String sentId);
}
