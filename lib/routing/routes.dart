import '../ui/player/view_model/player_view_model.dart';

abstract final class Routes {
  static const record = '/record';
  static const shelf = '/shelf';
  static const shop = '/shop';
  static const my = '/my';

  /// 재생 오버레이 (탭바 위)
  static const play = '/play';

  /// 친구 화면 (탭바 위)
  static const friendPattern = '/friends/:userId';

  /// 상점으로 가면서 [minutes] 테이프 행을 강조한다.
  static String shopHighlight(int minutes) => '$shop?hl=$minutes';

  /// [itemId] 테이프를 [source] 재생 목록으로 연다.
  static String playItem(QueueSource source, String itemId) => Uri(
    path: play,
    queryParameters: {'src': source.key, 'id': itemId},
  ).toString();

  static String friend(String userId) => '/friends/$userId';
}
