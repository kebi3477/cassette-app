import '../../model/api_error.dart';
import '../../model/json.dart';
import '../../model/delivery_dto.dart';
import '../../model/friend_dto.dart';
import '../../model/me_dto.dart';
import '../../model/page_dto.dart';
import '../../model/recording_dto.dart';
import '../../model/shelf_dto.dart';
import '../../model/wallet_dto.dart';
import '../api/api_client.dart';
import 'local_behavior.dart';
import 'local_store.dart';

/// 계약서(`cassette-api/docs/api.md`) 모양 그대로 응답하는 메모리 서버.
///
/// 다음 단계에서 HTTP 구현으로 바꿔 끼운다. 서버 규칙(보유 차감, 정렬, 오류 코드)도 흉내 낸다.
class LocalApiClient implements ApiClient {
  LocalApiClient(this._s, [this._b = const LocalBehavior()]);

  final LocalStore _s;
  final LocalBehavior _b;

  /// 번들 샘플 (tapeType별 길이 = 프로토타입 `DUR`)
  static String sampleAudio(int tapeType) =>
      'asset:///assets/audio/sample_${LocalStore.durationMs[tapeType]! ~/ 1000}s.m4a';

  Future<void> _wait([Duration? d]) async {
    final wait = d ?? _b.latency;
    // 지연이 없으면 타이머를 만들지 않는다 (fake_async 시험에서 마이크로태스크로 끝나게).
    if (wait > Duration.zero) await Future<void>.delayed(wait);
  }

  Never _fail(
    int status,
    String code,
    String message, [
    Json extra = const {},
  ]) => throw ApiException(
    status: status,
    code: code,
    message: message,
    extra: extra,
  );

  // ── users ─────────────────────────────────────────
  MeDto _me() {
    final stored =
        _s.unsorted.length +
        _s.groups.fold<int>(0, (a, g) => a + g.items.length);
    return MeDto(
      id: LocalStore.meId,
      name: _s.name,
      credits: _s.credits,
      drawer: DrawerDto(
        stored: stored,
        cap: _s.cap,
        full: stored >= _s.cap,
        unopenedCount: _s.unsorted.where((x) => !x.opened).length,
      ),
      tapes: [
        const TapeStockDto(tapeType: 1, qty: null),
        TapeStockDto(tapeType: 3, qty: _s.owned[3]),
        TapeStockDto(tapeType: 5, qty: _s.owned[5]),
      ],
      stats: StatsDto(
        receivedCount: stored,
        sentCount: _s.sent.length,
        friendCount: _s.friends.length,
      ),
      providers: const ['kakao'],
      notificationsEnabled: _s.notificationsEnabled,
      createdAt: LocalStore.d(9, 1),
    );
  }

  @override
  Future<MeDto> getMe() async {
    await _wait();
    return _me();
  }

  @override
  Future<MeDto> patchMe(PatchMeRequest body) async {
    await _wait();
    final name = body.name?.trim();
    if (name != null) {
      if (name.isEmpty || name.runes.length > 8) {
        _fail(400, 'INVALID_NAME', '이름은 1~8자로 적어주세요');
      }
      _s.name = name;
    }
    if (body.notificationsEnabled != null) {
      _s.notificationsEnabled = body.notificationsEnabled!;
    }
    return _me();
  }

  // ── friends ───────────────────────────────────────
  /// 정렬: 즐겨찾기 먼저 → lastAt 최근 순(없으면 뒤)
  @override
  Future<PageDto<FriendDto>> getFriends() async {
    await _wait();
    final list = [..._s.friends]
      ..sort((a, b) {
        if (a.starred != b.starred) return a.starred ? -1 : 1;
        final la = a.lastAt, lb = b.lastAt;
        if (la == null && lb == null) return 0;
        if (la == null) return 1;
        if (lb == null) return -1;
        return lb.compareTo(la);
      });
    return PageDto(items: list);
  }

  FriendDto _friend(String userId) =>
      _s.friends.where((f) => f.userId == userId).firstOrNull ??
      _fail(404, ApiErrorCode.friendNotFound, '친구 목록에 없는 사람이에요');

  @override
  Future<FriendDto> patchFriend(String userId, {required bool starred}) async {
    await _wait();
    final f = _friend(userId).copyWith(starred: starred);
    _s.friends = [for (final x in _s.friends) x.userId == userId ? f : x];
    return f;
  }

  @override
  Future<FriendTapesDto> getFriendTapes(String userId) async {
    await _wait();
    final f = _friend(userId);
    final items = <ShelfItemDto>[];
    for (final g in _s.groups) {
      for (final x in g.items) {
        if (x.sender.userId == userId) {
          items.add(x.copyWith(groupName: () => g.name));
        }
      }
    }
    for (final x in _s.unsorted) {
      if (x.sender.userId == userId && x.opened) items.add(x);
    }
    return FriendTapesDto(
      friend: f,
      items: items,
      unopenedCount: _s.unsorted
          .where((x) => x.sender.userId == userId && !x.opened)
          .length,
    );
  }

  // ── recordings ────────────────────────────────────
  @override
  Future<RecordingUploadDto> createRecording(
    CreateRecordingRequest body,
  ) async {
    await _wait();
    if (body.durationMs > body.tapeType * 60000 + 1000) {
      _fail(400, ApiErrorCode.recordingTooLong, '테이프 길이를 넘었어요');
    }
    final id = _s.nextId('r');
    final url = 'local://uploads/$id.m4a';
    _s.recordings[id] = LocalRecording(
      id: id,
      tapeType: body.tapeType,
      durationMs: body.durationMs,
      uploadUrl: url,
    );
    return RecordingUploadDto(
      recording: RecordingDto(
        id: id,
        tapeType: body.tapeType,
        durationMs: body.durationMs,
        status: 'uploading',
      ),
      upload: UploadTicketDto(
        url: url,
        method: 'PUT',
        headers: {'Content-Type': body.contentType},
        expiresAt: _s.now().add(const Duration(minutes: 15)),
      ),
    );
  }

  LocalRecording _rec(String id) =>
      _s.recordings[id] ??
      _fail(404, ApiErrorCode.recordingNotFound, '녹음을 찾을 수 없어요');

  void _startProcessing(LocalRecording r) {
    r.status = 'processing';
    r.willFail = _b.failsConvert;
    r.readyAt = _s.now().add(
      _b.failsConvert
          ? _b.convertFailDelay
          : _b.slowConvert
          ? _b.convertSlowDelay
          : _b.convertDelay,
    );
  }

  RecordingDto _recDto(LocalRecording r) {
    if (r.status == 'processing' && !_s.now().isBefore(r.readyAt!)) {
      r.status = r.willFail ? 'failed' : 'ready';
    }
    final path = _s.uploads[r.uploadUrl];
    return RecordingDto(
      id: r.id,
      tapeType: r.tapeType,
      durationMs: r.durationMs,
      status: r.status,
      preview: r.status == 'ready' && !r.sent && path != null
          ? PreviewDto(
              url: path,
              expiresAt: _s.now().add(const Duration(minutes: 10)),
            )
          : null,
    );
  }

  @override
  Future<RecordingDto> completeRecording(String id) async {
    await _wait();
    final r = _rec(id);
    if (!_s.uploads.containsKey(r.uploadUrl)) {
      _fail(409, ApiErrorCode.uploadNotFound, '녹음 파일을 올리지 못했어요. 다시 시도해 주세요');
    }
    _startProcessing(r);
    return _recDto(r);
  }

  @override
  Future<RecordingDto> getRecording(String id) async {
    await _wait();
    return _recDto(_rec(id));
  }

  @override
  Future<RecordingDto> retryRecording(String id) async {
    await _wait();
    final r = _rec(id);
    _startProcessing(r);
    return _recDto(r);
  }

  // ── deliveries ────────────────────────────────────
  @override
  Future<SentTapeDto> createDelivery(
    CreateDeliveryRequest body, {
    required String idempotencyKey,
  }) async {
    final replay = _s.idempotency[idempotencyKey];
    if (replay is SentTapeDto) {
      await _wait();
      return replay;
    }
    if (_b.failsSend) {
      await _wait(_b.sendFailDelay);
      _fail(500, ApiErrorCode.internalError, '잠시 문제가 생겼어요. 다시 시도해 주세요');
    }
    await _wait(_b.sendDelay);
    final r = _rec(body.recordingId);
    final dto = _recDto(r);
    if (r.sent) {
      _fail(409, ApiErrorCode.recordingAlreadySent, '이미 보낸 녹음이에요');
    }
    if (dto.status != 'ready') {
      _fail(409, ApiErrorCode.recordingNotReady, '테이프 소리로 바꾸는 중이에요', {
        'status': dto.status,
      });
    }
    FriendDto? friend;
    if (body.recipientId != null) {
      friend = _s.friends
          .where((f) => f.userId == body.recipientId)
          .firstOrNull;
      if (friend == null) {
        _fail(403, ApiErrorCode.notFriend, '친구에게만 보낼 수 있어요');
      }
    }
    if (r.tapeType != 1) {
      final n = _s.owned[r.tapeType] ?? 0;
      if (n <= 0) {
        _fail(409, ApiErrorCode.noTapeLeft, '테이프가 없어요. 상점에서 채워 주세요', {
          'tapeType': r.tapeType,
        });
      }
      _s.owned = {..._s.owned, r.tapeType: n - 1};
    }
    r.sent = true;
    final now = _s.now();
    final id = _s.nextId('s');
    final sent = SentTapeDto(
      id: id,
      recipient: friend == null
          ? null
          : UserRefDto(userId: friend.userId, name: friend.name),
      linkName: body.linkName,
      tapeType: r.tapeType,
      durationMs: r.durationMs,
      tag: body.tag,
      sentAt: now,
      status: friend == null ? 'link_pending' : 'unopened',
      claimedAt: friend == null ? null : now,
      share: friend == null
          ? ShareLinkDto(
              url: 'https://cassette.app/t/$id',
              expiresAt: now.add(const Duration(days: 7)),
            )
          : null,
    );
    _s.sent = [sent, ..._s.sent];
    if (friend != null) {
      _s.friends = [
        for (final f in _s.friends)
          f.userId == friend.userId ? f.copyWith(lastAt: now) : f,
      ];
    }
    _s.idempotency[idempotencyKey] = sent;
    return sent;
  }

  @override
  Future<PageDto<SentTapeDto>> getSent({String? cursor, int? limit}) async {
    await _wait();
    return PageDto(items: List.of(_s.sent));
  }

  ({ShelfItemDto item, int index, LocalGroup? group}) _find(String id) {
    final i = _s.unsorted.indexWhere((x) => x.id == id);
    if (i >= 0) return (item: _s.unsorted[i], index: i, group: null);
    for (final g in _s.groups) {
      final j = g.items.indexWhere((x) => x.id == id);
      if (j >= 0) return (item: g.items[j], index: j, group: g);
    }
    _fail(404, ApiErrorCode.tapeNotFound, '테이프를 찾을 수 없어요');
  }

  void _replace(String id, ShelfItemDto next) {
    final f = _find(id);
    if (f.group == null) {
      _s.unsorted = [..._s.unsorted]..[f.index] = next;
    } else {
      f.group!.items = [...f.group!.items]..[f.index] = next;
    }
  }

  @override
  Future<ShelfItemDto> getDelivery(String id) async {
    await _wait();
    return _find(id).item;
  }

  @override
  Future<ShelfItemDto> openDelivery(String id) async {
    await _wait();
    final item = _find(id).item;
    if (item.opened) return item;
    final next = item.copyWith(opened: true, openedAt: _s.now());
    _replace(id, next);
    return next;
  }

  @override
  Future<AudioUrlDto> getDeliveryAudio(String id) async {
    await _wait();
    final item = _find(id).item;
    if (!item.opened) {
      _fail(409, ApiErrorCode.tapeNotOpened, '소포를 먼저 뜯어 주세요');
    }
    if (_b.failsAudio) {
      _fail(409, ApiErrorCode.audioNotReady, '테이프를 불러오지 못했어요');
    }
    return AudioUrlDto(
      url: sampleAudio(item.tapeType),
      expiresAt: _s.now().add(const Duration(minutes: 10)),
      durationMs: item.durationMs,
    );
  }

  // ── shelf ─────────────────────────────────────────
  @override
  Future<ShelfDto> getShelf() async {
    await _wait();
    final me = _me();
    return ShelfDto(
      stored: me.drawer.stored,
      cap: me.drawer.cap,
      full: me.drawer.full,
      unopenedCount: me.drawer.unopenedCount,
      unsorted: List.of(_s.unsorted),
      groups: [
        for (final g in _s.groups)
          ShelfGroupDto(id: g.id, name: g.name, items: List.of(g.items)),
      ],
    );
  }

  String _groupName(String name) {
    final n = name.trim().isEmpty ? '새 칸' : name.trim();
    if (n.runes.length > 12) {
      _fail(400, ApiErrorCode.invalidGroupName, '칸 이름은 1~12자로 적어주세요');
    }
    return n;
  }

  LocalGroup _group(String id) =>
      _s.groups.where((g) => g.id == id).firstOrNull ??
      _fail(404, ApiErrorCode.groupNotFound, '칸을 찾을 수 없어요');

  @override
  Future<ShelfGroupDto> createGroup(String name) async {
    await _wait();
    final g = LocalGroup(_s.nextId('g'), _groupName(name), []);
    _s.groups = [..._s.groups, g];
    return ShelfGroupDto(id: g.id, name: g.name, items: const []);
  }

  @override
  Future<ShelfGroupDto> renameGroup(String id, String name) async {
    await _wait();
    final g = _group(id)..name = _groupName(name);
    return ShelfGroupDto(id: g.id, name: g.name, items: List.of(g.items));
  }

  /// 칸을 지우면 안의 테이프는 분류 안 함(맨 뒤)으로 가고 뜯은 상태가 된다.
  @override
  Future<void> deleteGroup(String id) async {
    await _wait();
    final g = _group(id);
    _s.groups = _s.groups.where((x) => x.id != id).toList();
    _s.unsorted = [
      ..._s.unsorted,
      for (final x in g.items) x.copyWith(opened: true, groupId: () => null),
    ];
  }

  @override
  Future<ShelfItemDto> moveShelfItem(
    String id,
    MoveShelfItemRequest body,
  ) async {
    await _wait();
    final from = _find(id);
    // 안 뜯은 소포는 칸으로 못 옮긴다. 분류 안 함 안에서 순서 바꾸기는 된다.
    if (!from.item.opened && body.groupId != null) {
      _fail(409, ApiErrorCode.tapeNotOpened, '소포를 먼저 뜯어 주세요');
    }
    final target = body.groupId == null ? null : _group(body.groupId!);
    // 빼기
    if (from.group == null) {
      _s.unsorted = [..._s.unsorted]..removeAt(from.index);
    } else {
      from.group!.items = [...from.group!.items]..removeAt(from.index);
    }
    final moved = from.item.copyWith(groupId: () => body.groupId);
    final list = target == null ? [..._s.unsorted] : [...target.items];
    var at = 0;
    if (body.afterId != null) {
      final k = list.indexWhere((x) => x.id == body.afterId);
      at = k < 0 ? list.length : k + 1;
    }
    list.insert(at, moved);
    if (target == null) {
      _s.unsorted = list;
    } else {
      target.items = list;
    }
    return moved;
  }

  @override
  Future<void> deleteShelfItem(String id) async {
    await _wait();
    final f = _find(id);
    if (f.group == null) {
      _s.unsorted = [..._s.unsorted]..removeAt(f.index);
    } else {
      f.group!.items = [...f.group!.items]..removeAt(f.index);
    }
  }

  // ── wallet ────────────────────────────────────────
  @override
  Future<WalletDto> getWallet() async {
    await _wait();
    return WalletDto(
      credits: _s.credits,
      ads: AdsDto(
        rewardPerView: 10,
        dailyLimit: 3,
        remainingToday: _s.adsRemaining,
      ),
    );
  }

  @override
  Future<PageDto<LedgerEntryDto>> getLedger({
    String? cursor,
    int? limit,
  }) async {
    await _wait();
    return PageDto(items: List.of(_s.ledger));
  }
}
