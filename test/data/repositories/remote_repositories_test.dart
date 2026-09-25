import 'package:cassette_app/data/model/api_error.dart';
import 'package:cassette_app/data/repositories/delivery_repository_remote.dart';
import 'package:cassette_app/data/repositories/friend_repository_remote.dart';
import 'package:cassette_app/data/repositories/recording_repository_remote.dart';
import 'package:cassette_app/data/repositories/shelf_repository_remote.dart';
import 'package:cassette_app/data/repositories/user_repository_remote.dart';
import 'package:cassette_app/data/repositories/wallet_repository_remote.dart';
import 'package:cassette_app/data/services/local/local_api_client.dart';
import 'package:cassette_app/data/services/local/local_behavior.dart';
import 'package:cassette_app/data/services/local/local_store.dart';
import 'package:cassette_app/data/services/local/local_upload_service.dart';
import 'package:cassette_app/domain/models/friend.dart';
import 'package:cassette_app/domain/models/friend_tapes.dart';
import 'package:cassette_app/domain/models/me.dart';
import 'package:cassette_app/domain/models/recipient.dart';
import 'package:cassette_app/domain/models/recording.dart';
import 'package:cassette_app/domain/models/sent_tape.dart';
import 'package:cassette_app/domain/models/shelf.dart';
import 'package:cassette_app/domain/models/tape_audio.dart';
import 'package:cassette_app/domain/models/tape_item.dart';
import 'package:cassette_app/domain/models/tape_tag.dart';
import 'package:cassette_app/domain/models/tape_type.dart';
import 'package:cassette_app/domain/models/wallet.dart';
import 'package:cassette_app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

T ok<T>(Result<T> r) => (r as Ok<T>).value;

ApiException apiError(Result<Object?> r) => (r as Error).error as ApiException;

void main() {
  late LocalStore store;
  late LocalApiClient api;

  setUp(() {
    store = LocalStore(clock: () => DateTime.utc(2026, 9, 25, 3));
    api = LocalApiClient(store, LocalBehavior.instant);
  });

  test('Me: 크레딧·보유·서랍(unopenedCount)', () async {
    final me = ok<Me>(await UserRepositoryRemote(api).getMe());
    expect(me.name, '민경');
    expect(me.credits, 120);
    expect(me.owned, {TapeType.three: 2, TapeType.five: 0});
    expect(me.drawer.stored, 10);
    expect(me.drawer.cap, 12);
    expect(me.drawer.unopenedCount, 2);
    expect(me.sentCount, 4);
    expect(me.friendCount, 6);
  });

  test('지갑 = /users/me 보유 + /wallet 광고', () async {
    final w = ok<Wallet>(await WalletRepositoryRemote(api).getWallet());
    expect(w.credits, 120);
    expect(w.ownedOf(TapeType.three), 2);
    expect(w.adsLeft, 3);
  });

  test('친구 정렬: 즐겨찾기 → lastAt 최근 순, userId가 id로', () async {
    final repo = FriendRepositoryRemote(api);
    final list = ok<List<Friend>>(await repo.getFriends());
    expect(list.map((f) => f.name), ['지현', '엄마', '하늘', '민수', '은비', '박과장님']);
    expect(list.first.id, 'u-jihyun');
    final f = ok<Friend>(await repo.setStarred('u-minsu', true));
    expect(f.starred, isTrue);
  });

  test('친구 화면: 뜯은 테이프만 + 칸 이름, 안 뜯은 수', () async {
    final repo = FriendRepositoryRemote(api);
    final mom = ok<FriendTapes>(await repo.getFriendTapes('u-mom'));
    expect(mom.items.map((x) => x.where), ['2026 생일', '엄마 목소리', '엄마 목소리']);
    expect(mom.unopenedCount, 0);
    final jihyun = ok<FriendTapes>(await repo.getFriendTapes('u-jihyun'));
    expect(jihyun.items, isEmpty);
    expect(jihyun.unopenedCount, 1);
    expect(
      apiError(await repo.getFriendTapes('u-nobody')).code,
      'FRIEND_NOT_FOUND',
    );
  });

  group('서랍', () {
    test('GET /shelf → unsorted + 칸 3개, 태그 코드 매핑', () async {
      final s = ok<Shelf>(await ShelfRepositoryRemote(api).getShelf());
      expect(s.unsorted.map((x) => x.from), ['지현', '하늘']);
      expect(s.unsorted.first.opened, isFalse);
      expect(s.unsorted.last.viaLink, isTrue);
      expect(s.unsorted.last.tag, TapeTag.thinking);
      expect(s.groups.map((g) => g.name), ['2026 생일', '승진 축하', '엄마 목소리']);
      expect(s.groups.first.items.first.groupId, 'g-1');
      expect(s.groups.first.items.first.duration, const Duration(seconds: 48));
    });

    test('옮기기 afterId: null이면 맨 앞, id면 그 뒤', () async {
      final repo = ShelfRepositoryRemote(api);
      var s = ok<Shelf>(await repo.getShelf());
      final last = s.groups[0].items.last.id;
      await repo.moveItem(last, groupId: 'g-1', afterId: null);
      s = ok<Shelf>(await repo.getShelf());
      expect(s.groups[0].items.first.id, last);

      await repo.moveItem(
        last,
        groupId: 'g-2',
        afterId: s.groups[1].items[0].id,
      );
      s = ok<Shelf>(await repo.getShelf());
      expect(s.groups[0].items, hasLength(3));
      expect(s.groups[1].items[1].id, last);
      expect(s.groups[1].items[1].groupId, 'g-2');
    });

    test('안 뜯은 소포는 칸으로 옮길 수 없다(409 TAPE_NOT_OPENED)', () async {
      final repo = ShelfRepositoryRemote(api);
      final s = ok<Shelf>(await repo.getShelf());
      final r = await repo.moveItem(
        s.unsorted.first.id,
        groupId: 'g-1',
        afterId: null,
      );
      expect(apiError(r).code, 'TAPE_NOT_OPENED');
      // 분류 안 함 안에서 순서 바꾸기는 된다
      final ok2 = await repo.moveItem(
        s.unsorted.first.id,
        groupId: null,
        afterId: s.unsorted.last.id,
      );
      expect(ok2, isA<Ok<TapeItem>>());
    });

    test('칸 지우기 → 테이프는 분류 안 함 맨 뒤, 뜯은 상태', () async {
      final repo = ShelfRepositoryRemote(api);
      await repo.deleteGroup('g-2');
      final s = ok<Shelf>(await repo.getShelf());
      expect(s.groups, hasLength(2));
      expect(s.unsorted.map((x) => x.from), ['지현', '하늘', '박과장님', '은비']);
      expect(s.unsorted.last.groupId, isNull);
    });

    test('칸 이름: 비우면 "새 칸", 12자 넘으면 오류', () async {
      final repo = ShelfRepositoryRemote(api);
      expect(ok<ShelfGroup>(await repo.createGroup('  ')).name, '새 칸');
      final r = await repo.renameGroup('g-1', '가나다라마바사아자차카타파');
      expect(apiError(r).code, 'INVALID_GROUP_NAME');
    });

    test('소포 뜯기 → 재생 주소(샘플), 안 뜯은 건 403', () async {
      final repo = ShelfRepositoryRemote(api);
      final id = ok<Shelf>(await repo.getShelf()).unsorted.first.id;
      expect(await repo.audioUrl(id), isA<Error<TapeAudio>>());
      final opened = ok<TapeItem>(await repo.open(id));
      expect(opened.opened, isTrue);
      final audio = ok<TapeAudio>(await repo.audioUrl(id));
      expect(audio.url, 'asset:///assets/audio/sample_34s.m4a');
      expect(audio.duration, const Duration(seconds: 34));
    });
  });

  group('녹음·보내기', () {
    Future<Recording> uploadReady(TapeType type) async {
      final repo = RecordingRepositoryRemote(
        api,
        LocalUploadService(store),
        pollInterval: Duration.zero,
      );
      final up = ok<Recording>(
        await repo.upload(
          filePath: '/tmp/a.m4a',
          type: type,
          duration: const Duration(seconds: 8),
        ),
      );
      expect(up.status, isNot(RecordingStatus.uploading));
      return ok<Recording>(await repo.convert(up.id));
    }

    test('업로드 → complete → 폴링 ready, 미리 듣기는 올린 파일', () async {
      final rec = await uploadReady(TapeType.one);
      expect(rec.status, RecordingStatus.ready);
      expect(rec.previewUrl, '/tmp/a.m4a');
    });

    test('변환 실패 → retry도 실패 모드면 실패', () async {
      final failing = LocalApiClient(
        store,
        const LocalBehavior(
          failMode: FailMode.convertFail,
          latency: Duration.zero,
          convertFailDelay: Duration.zero,
        ),
      );
      final repo = RecordingRepositoryRemote(
        failing,
        LocalUploadService(store),
        pollInterval: Duration.zero,
      );
      final up = ok<Recording>(
        await repo.upload(
          filePath: '/tmp/a.m4a',
          type: TapeType.one,
          duration: const Duration(seconds: 3),
        ),
      );
      expect(await repo.convert(up.id), isA<Error<Recording>>());
      expect(await repo.retry(up.id), isA<Error<Recording>>());
    });

    test('3분 보내기: 차감, lastAt 갱신, 같은 키는 한 번만, tag 없음', () async {
      final rec = await uploadReady(TapeType.three);
      final repo = DeliveryRepositoryRemote(api);
      const to = Recipient.friend(friendId: 'u-haneul', name: '하늘');
      Future<SentTape> send() async => ok<SentTape>(
        await repo.send(recordingId: rec.id, to: to, idempotencyKey: 'k1'),
      );
      final a = await send();
      final b = await send();
      expect(a.id, b.id);
      expect(a.status, SentStatus.unopened);
      expect(store.owned[3], 1);
      expect(store.sent.first.tag, isNull, reason: '앱은 tag를 보내지 않는다');
      expect(
        store.friends.firstWhere((f) => f.name == '하늘').lastAt,
        store.now(),
      );
    });

    test('5분 0개면 NO_TAPE_LEFT, 새 친구는 링크', () async {
      final repo = DeliveryRepositoryRemote(api);
      final five = await uploadReady(TapeType.five);
      final r = await repo.send(
        recordingId: five.id,
        to: const Recipient.friend(friendId: 'u-jihyun', name: '지현'),
        idempotencyKey: 'k2',
      );
      expect(apiError(r).code, 'NO_TAPE_LEFT');

      final one = await uploadReady(TapeType.one);
      final link = ok<SentTape>(
        await repo.send(
          recordingId: one.id,
          to: const Recipient.newFriend(name: '유진'),
          idempotencyKey: 'k3',
        ),
      );
      expect(link.link, isTrue);
      expect(link.status, SentStatus.linkPending);
      expect(link.to, '유진');
      expect(link.shareUrl, isNotNull);
    });
  });

  test('FailMode.parse', () {
    expect(FailMode.parse('loadFail'), FailMode.loadFail);
    expect(FailMode.parse(''), FailMode.none);
  });
}
