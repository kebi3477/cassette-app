abstract final class Routes {
  static const record = '/record';
  static const shelf = '/shelf';
  static const shop = '/shop';
  static const my = '/my';

  /// 상점으로 가면서 [minutes] 테이프 행을 강조한다.
  static String shopHighlight(int minutes) => '$shop?hl=$minutes';
}
