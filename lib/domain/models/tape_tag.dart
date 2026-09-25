/// 테이프 라벨 태그 — 계약서 §2 Tag. 서버는 코드만, 문구는 앱이 가진다 (logic.js `TAGS`).
enum TapeTag {
  birthday('birthday', '생일 축하해'),
  congrats('congrats', '축하해요'),
  thinking('thinking', '그냥, 생각나서');

  const TapeTag(this.code, this.label);

  final String code;
  final String label;

  static TapeTag? fromCode(String? code) =>
      values.where((t) => t.code == code).firstOrNull;
}
