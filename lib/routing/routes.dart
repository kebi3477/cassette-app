import '../ui/my/view_model/my_view_model.dart';
import '../ui/player/view_model/player_view_model.dart';

abstract final class Routes {
  // 관문 (앱 본문 밖)
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const name = '/name';
  static const permissions = '/permissions';
  static const permissionsMic = '/permissions/mic';
  static const permissionsNoti = '/permissions/noti';
  static const update = '/update';

  static bool isGate(String location) =>
      location == splash ||
      location == onboarding ||
      location == login ||
      location == name ||
      location == update ||
      location.startsWith(permissions);

  /// 링크 오류 (`leOn`)
  static const linkError = '/link-error';

  static const record = '/record';
  static const shelf = '/shelf';
  static const shop = '/shop';
  static const my = '/my';

  /// 재생 오버레이 (탭바 위)
  static const play = '/play';

  /// 크레딧 내역 (탭바 위)
  static const credits = '/credits';

  /// 마이 하위 화면 (탭바 위, `mpOn`) — `/my/recv` · `/my/sent` · `/my/friends` · `/my/settings`
  static const myPagePattern = '/my/:page';

  static String myPage(MyPage p) => '$my/${p.name}';

  /// 친구 화면 (탭바 위)
  static const friendPattern = '/friends/:userId';

  /// 상점으로 가면서 [minutes] 테이프 행을 강조한다.
  static String shopHighlight(int minutes) => '$shop?hl=$minutes';

  /// 서랍 배너 "넓히기 ›" → 상점 맨 위 서랍 카드가 팝 (`goShop('drawer')`)
  static String shopDrawer({int? nonce}) => Uri(
    path: shop,
    queryParameters: {
      'hl': 'drawer',
      'n': '${nonce ?? DateTime.now().millisecondsSinceEpoch}',
    },
  ).toString();

  /// 0개 테이프의 "+" → 상점에서 강조하고 1개짜리 구매 시트를 바로 연다.
  /// [nonce]는 같은 테이프를 다시 눌러도 주소가 바뀌게 한다.
  static String shopBuy(int minutes, {int? nonce}) => Uri(
    path: shop,
    queryParameters: {
      'hl': '$minutes',
      'buy': '${nonce ?? DateTime.now().millisecondsSinceEpoch}',
    },
  ).toString();

  /// [itemId] 테이프를 [source] 재생 목록으로 연다.
  /// [linkChip]이 false면 "친구가 되었어요" 칩을 숨긴다 (차단 관계라 친구가 안 됐을 때).
  static String playItem(
    QueueSource source,
    String itemId, {
    bool linkChip = true,
  }) => Uri(
    path: play,
    queryParameters: {
      'src': source.key,
      'id': itemId,
      if (!linkChip) 'chip': '0',
    },
  ).toString();

  /// 마이 탭 + 보낸 테이프 상세
  static String mySent(String sentId) =>
      Uri(path: my, queryParameters: {'sent': sentId}).toString();

  /// 아직 받지 않은 링크 테이프의 소포 화면 (뜯을 때 받는다)
  static String playLink(String token) =>
      playItem(LinkSource(token), 'link:$token');

  static String friend(String userId) => '/friends/$userId';

  /// [kind]는 `taken` · `expired` · `own`. own이면 다시 공유할 [url].
  static String linkErrorOf(String kind, {String? url}) => Uri(
    path: linkError,
    queryParameters: {'kind': kind, 'url': ?url},
  ).toString();
}
