import '../../../domain/models/friend.dart';
import '../../../domain/models/sent_tape.dart';
import '../../../domain/models/shelf.dart';
import '../../../domain/models/tape_item.dart';
import '../../../domain/models/tape_type.dart';
import '../../../domain/models/user.dart';
import '../../../domain/models/wallet.dart';

/// 서버 없이 앱을 돌리기 위한 메모리 저장소.
///
/// 초기값은 프로토타입 `state = {…}`(source/CassetteApp.logic.js)와 같다.
/// 날짜는 프로토타입의 `MM.DD`에 2026년을 붙였다.
class LocalStore {
  LocalStore({DateTime Function()? clock}) : now = clock ?? DateTime.now {
    reset();
  }

  final DateTime Function() now;

  late User me;
  late int credits;
  late Map<TapeType, int> owned;
  late int adsLeft;
  late int cap;
  late List<LedgerEntry> ledger;
  late List<Friend> friends;
  late List<TapeItem> inbox;
  late List<ShelfGroup> groups;
  late List<SentTape> sent;

  int _uid = 100;

  String nextId(String prefix) => '$prefix${_uid++}';

  /// 프로토타입 초기 상태로 되돌린다.
  void reset() {
    _uid = 100;
    me = const User(id: 'me', name: '민경');
    credits = 120;
    owned = {TapeType.three: 2, TapeType.five: 0};
    adsLeft = 3;
    cap = 12;
    ledger = [
      LedgerEntry(date: _d(9, 24), reason: '광고 보상', amount: 10),
      LedgerEntry(date: _d(9, 20), reason: '3분 테이프 구매', amount: -30),
      LedgerEntry(date: _d(9, 18), reason: '크레딧 충전 · ₩1,100', amount: 100),
      LedgerEntry(date: _d(9, 12), reason: '지현님이 선물', amount: 30),
      LedgerEntry(date: _d(9, 1), reason: '가입 선물', amount: 10),
    ];
    friends = [
      Friend(id: 'f1', name: '지현', starred: true, lastAt: _d(9, 24)),
      Friend(id: 'f2', name: '엄마', starred: true, lastAt: _d(9, 10)),
      Friend(id: 'f3', name: '민수', starred: false, lastAt: _d(8, 30)),
      Friend(id: 'f4', name: '하늘', starred: false, lastAt: _d(9, 23)),
      Friend(id: 'f5', name: '박과장님', starred: false, lastAt: _d(6, 2)),
      Friend(id: 'f6', name: '은비', starred: false, lastAt: _d(6, 3)),
    ];
    inbox = [
      _it('지현', 9, 24, TapeType.three, opened: false),
      _it('하늘', 9, 23, TapeType.one, tag: '그냥', opened: false, viaLink: true),
    ];
    groups = [
      ShelfGroup(
        id: 'g1',
        name: '2026 생일',
        items: [
          _it('엄마', 3, 14, TapeType.five),
          _it('민수', 3, 14, TapeType.one),
          _it('수아', 3, 15, TapeType.three),
          _it('할머니', 3, 14, TapeType.one),
        ],
      ),
      ShelfGroup(
        id: 'g2',
        name: '승진 축하',
        items: [
          _it('박과장님', 6, 2, TapeType.three, tag: '축하'),
          _it('은비', 6, 3, TapeType.one, tag: '축하'),
        ],
      ),
      ShelfGroup(
        id: 'g3',
        name: '엄마 목소리',
        items: [
          _it('엄마', 1, 1, TapeType.five, tag: '그냥'),
          _it('엄마', 5, 8, TapeType.three, tag: '그냥'),
        ],
      ),
    ];
    sent = [
      SentTape(
        id: 's1',
        to: '유진',
        date: _d(9, 22),
        type: TapeType.one,
        link: true,
        shareUrl: Uri.parse('https://cassette.app/t/demo-yujin'),
      ),
      SentTape(
        id: 's2',
        to: '엄마',
        date: _d(9, 10),
        type: TapeType.three,
        openedAt: _d(9, 11),
      ),
      SentTape(id: 's3', to: '민수', date: _d(8, 30), type: TapeType.one),
      SentTape(
        id: 's4',
        to: '박과장님',
        date: _d(6, 1),
        type: TapeType.one,
        openedAt: _d(6, 2),
      ),
    ];
  }

  Wallet get wallet => Wallet(
    credits: credits,
    owned: Map.unmodifiable(owned),
    adsLeft: adsLeft,
  );

  Shelf get shelf => Shelf(
    inbox: List.unmodifiable(inbox),
    groups: List.unmodifiable(groups),
    cap: cap,
  );

  static DateTime _d(int m, int d) => DateTime(2026, m, d);

  TapeItem _it(
    String from,
    int m,
    int d,
    TapeType type, {
    String tag = '생일',
    bool opened = true,
    bool viaLink = false,
  }) => TapeItem(
    id: nextId('t'),
    from: from,
    date: _d(m, d),
    type: type,
    tag: tag,
    opened: opened,
    viaLink: viaLink,
  );
}
