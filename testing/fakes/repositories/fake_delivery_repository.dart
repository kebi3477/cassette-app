import 'package:cassette_app/data/repositories/delivery_repository.dart';
import 'package:cassette_app/data/repositories/wallet_repository_local.dart';
import 'package:cassette_app/domain/models/recipient.dart';
import 'package:cassette_app/domain/models/sent_tape.dart';
import 'package:cassette_app/domain/models/tape_type.dart';
import 'package:cassette_app/utils/result.dart';

/// 보내기 결과와 시간을 시험마다 정하는 가짜. 성공하면 보유 테이프를 1개 쓴다.
class FakeDeliveryRepository implements DeliveryRepository {
  FakeDeliveryRepository({
    this.wallet,
    this.delay = const Duration(milliseconds: 500),
    this.fail = false,
  });

  final WalletRepositoryLocal? wallet;
  Duration delay;
  bool fail;
  final List<String> keys = [];
  final List<SentTape> sent = [];

  @override
  Future<Result<SentTape>> send({
    required String recordingId,
    required TapeType type,
    required Recipient to,
    required String idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    await Future<void>.delayed(delay);
    if (fail) return Result.error(Exception('offline'));
    wallet?.consume(type);
    final s = SentTape(
      id: 's${sent.length + 1}',
      to: to.name,
      date: DateTime(2026, 9, 25),
      type: type,
      link: to.isNew,
      shareUrl: to.isNew ? Uri.parse('https://cassette.app/t/test') : null,
    );
    sent.add(s);
    return Result.ok(s);
  }

  @override
  Future<Result<List<SentTape>>> getSent() async => Result.ok(sent);
}
