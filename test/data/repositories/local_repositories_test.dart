import 'package:cassette_app/data/repositories/delivery_repository_local.dart';
import 'package:cassette_app/data/repositories/friend_repository_local.dart';
import 'package:cassette_app/data/repositories/recording_repository_local.dart';
import 'package:cassette_app/data/repositories/shelf_repository_local.dart';
import 'package:cassette_app/data/repositories/wallet_repository_local.dart';
import 'package:cassette_app/data/services/local/local_behavior.dart';
import 'package:cassette_app/data/services/local/local_store.dart';
import 'package:cassette_app/domain/models/recipient.dart';
import 'package:cassette_app/domain/models/recording.dart';
import 'package:cassette_app/domain/models/sent_tape.dart';
import 'package:cassette_app/domain/models/shelf.dart';
import 'package:cassette_app/domain/models/tape_type.dart';
import 'package:cassette_app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fast = LocalBehavior(
    uploadDelay: Duration.zero,
    convertDelay: Duration.zero,
    convertFailDelay: Duration.zero,
    sendDelay: Duration.zero,
    sendFailDelay: Duration.zero,
  );

  late LocalStore store;
  late FriendRepositoryLocal friends;
  late WalletRepositoryLocal wallet;

  setUp(() {
    store = LocalStore(clock: () => DateTime(2026, 9, 25));
    friends = FriendRepositoryLocal(store);
    wallet = WalletRepositoryLocal(store);
  });

  test('프로토타입 초기 state: 서랍 10/12, 새 테이프 2, 칸 3개, 보낸 4개', () async {
    final shelf = (await ShelfRepositoryLocal(store).getShelf()) as Ok<Shelf>;
    expect(shelf.value.stored, 10);
    expect(shelf.value.cap, 12);
    expect(shelf.value.unopenedCount, 2);
    expect(shelf.value.groups.map((g) => g.name), [
      '2026 생일',
      '승진 축하',
      '엄마 목소리',
    ]);
    expect(store.sent, hasLength(4));
    expect(store.ledger.first.reason, '광고 보상');
    expect(store.friends, hasLength(6));
  });

  test('보내기: 3분 차감, 받는 사람을 맨 앞으로, 같은 키는 한 번만', () async {
    final repo = DeliveryRepositoryLocal(store, fast, friends, wallet);
    const to = Recipient.friend(friendId: 'f4', name: '하늘');
    final a = await repo.send(
      recordingId: 'r1',
      type: TapeType.three,
      to: to,
      idempotencyKey: 'k1',
    );
    final b = await repo.send(
      recordingId: 'r1',
      type: TapeType.three,
      to: to,
      idempotencyKey: 'k1',
    );
    expect((a as Ok<SentTape>).value.id, (b as Ok<SentTape>).value.id);
    expect(store.owned[TapeType.three], 1);
    expect(store.friends.first.name, '하늘');
    expect(store.friends.first.lastAt, DateTime(2026, 9, 25));
    expect(store.sent.first.to, '하늘');
  });

  test('5분 테이프가 0개면 보낼 수 없다', () async {
    final repo = DeliveryRepositoryLocal(store, fast, friends, wallet);
    final r = await repo.send(
      recordingId: 'r1',
      type: TapeType.five,
      to: const Recipient.friend(friendId: 'f1', name: '지현'),
      idempotencyKey: 'k2',
    );
    expect(r, isA<Error<SentTape>>());
  });

  test('새 친구에게는 링크를 만들고 1분은 차감하지 않는다', () async {
    final repo = DeliveryRepositoryLocal(store, fast, friends, wallet);
    final r = await repo.send(
      recordingId: 'r1',
      type: TapeType.one,
      to: const Recipient.newFriend(name: '유진'),
      idempotencyKey: 'k3',
    );
    final sent = (r as Ok<SentTape>).value;
    expect(sent.link, isTrue);
    expect(sent.shareUrl, isNotNull);
    expect(store.owned, {TapeType.three: 2, TapeType.five: 0});
  });

  test('failMode: convertFail이면 변환이 실패한다', () async {
    final repo = RecordingRepositoryLocal(
      store,
      const LocalBehavior(
        failMode: FailMode.convertFail,
        uploadDelay: Duration.zero,
        convertFailDelay: Duration.zero,
      ),
    );
    final up = await repo.upload(
      filePath: '/tmp/a.m4a',
      type: TapeType.one,
      duration: const Duration(seconds: 3),
    );
    final id = (up as Ok<Recording>).value.id;
    expect(await repo.convert(id), isA<Error<Recording>>());
  });

  test('FailMode.parse', () {
    expect(FailMode.parse('sendFail'), FailMode.sendFail);
    expect(FailMode.parse(''), FailMode.none);
  });
}
