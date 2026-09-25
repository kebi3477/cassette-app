/// 설정 > 정보의 외부 링크. 페이지는 cassette-api가 서비스한다 (GET /privacy, /terms).
abstract final class AppLinks {
  static final terms = Uri.parse('https://cassette.lab241.com/terms');
  static final privacy = Uri.parse('https://cassette.lab241.com/privacy');

  /// 문의 이메일이 정해지면 mailto:로 바꾼다. 그때까지는 처리방침의 보호책임자·연락처 절로 보낸다.
  static final contact = Uri.parse('https://cassette.lab241.com/privacy#officer');
}
