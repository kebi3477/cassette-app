import 'package:cassette_app/data/repositories/delivery_repository.dart';
import 'package:cassette_app/data/services/local/local_store.dart';
import 'package:cassette_app/domain/models/recipient.dart';
import 'package:cassette_app/domain/models/sent_tape.dart';
import 'package:cassette_app/domain/models/tape_type.dart';
import 'package:cassette_app/utils/result.dart';

/// 보내기 결과와 시간을 시험마다 정하는 가짜.
/// 성공하면 [store]의 보유 테이프를 [type]만큼 1개 쓴다(서버 규칙 흉내).
class FakeDeliveryRepository implements DeliveryRepository {
  FakeDeliveryRepository({
    this.store,
    this.delay = const Duration(milliseconds: 500),
    this.fail = false,
  });

  final LocalStore? store;
  Duration delay;
  bool fail;

  /// 보낸 녹음의 테이프 종류 (가짜 녹음은 종류를 모르므로 시험이 정한다)
  TapeType type = TapeType.one;
  final List<String> keys = [];
  final List<SentTape> sent = [];

  @override
  Future<Result<SentTape>> send({
    required String recordingId,
    required Recipient to,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    await Future<void>.delayed(delay);
    if (fail) return Result.error(Exception('offline'));
    final s = store;
    if (s != null && !type.isUnlimited) {
      s.owned = {...s.owned, type.minutes: (s.owned[type.minutes] ?? 0) - 1};
    }
    final t = SentTape(
      id: 's${sent.length + 1}',
      status: to.isNew ? SentStatus.linkPending : SentStatus.unopened,
      to: to.name,
      date: DateTime(2026, 9, 25),
      type: type,
      link: to.isNew,
      shareUrl: to.isNew ? Uri.parse('https://cassette.app/t/test') : null,
    );
    sent.add(t);
    return Result.ok(t);
  }

  @override
  Future<Result<List<SentTape>>> getSent() async => Result.ok(sent);
}
