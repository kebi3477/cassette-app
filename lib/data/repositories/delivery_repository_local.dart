import '../../domain/models/recipient.dart';
import '../../domain/models/sent_tape.dart';
import '../../domain/models/tape_type.dart';
import '../../utils/result.dart';
import '../services/local/local_behavior.dart';
import '../services/local/local_store.dart';
import 'delivery_repository.dart';
import 'friend_repository_local.dart';
import 'wallet_repository_local.dart';

class DeliveryRepositoryLocal implements DeliveryRepository {
  DeliveryRepositoryLocal(
    this._store,
    this._behavior,
    this._friends,
    this._wallet,
  );

  final LocalStore _store;
  final LocalBehavior _behavior;
  final FriendRepositoryLocal _friends;
  final WalletRepositoryLocal _wallet;
  final Map<String, SentTape> _byKey = {};

  @override
  Future<Result<SentTape>> send({
    required String recordingId,
    required TapeType type,
    required Recipient to,
    required String idempotencyKey,
  }) async {
    final done = _byKey[idempotencyKey];
    if (done != null) return Result.ok(done);
    if (_behavior.failsSend) {
      await Future<void>.delayed(_behavior.sendFailDelay);
      return Result.error(Exception('보내지 못했어요'));
    }
    await Future<void>.delayed(_behavior.sendDelay);
    if (!_wallet.consume(type)) {
      return Result.error(Exception('${type.minutes}분 테이프가 없어요'));
    }
    final id = _store.nextId('s');
    final sent = SentTape(
      id: id,
      to: to.name,
      date: _store.now(),
      type: type,
      link: to.isNew,
      shareUrl: to.isNew ? Uri.parse('https://cassette.app/t/$id') : null,
    );
    _store.sent = [sent, ..._store.sent];
    _friends.touch(to.name, sent.date);
    _byKey[idempotencyKey] = sent;
    return Result.ok(sent);
  }

  @override
  Future<Result<List<SentTape>>> getSent() async =>
      Result.ok(List.unmodifiable(_store.sent));
}
