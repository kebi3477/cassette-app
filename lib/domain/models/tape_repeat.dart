/// 재생 반복 — logic.js `rep`. just_audio의 `LoopMode.off / all / one`에 대응한다.
enum TapeRepeat {
  off('순서대로 재생'),
  all('전체 반복'),
  one('한 개 반복');

  const TapeRepeat(this.label);

  /// 토스트·목록 제목 옆 문구 (`MODE`)
  final String label;

  /// 누를 때마다 off → all → one → off
  TapeRepeat get next => switch (this) {
    TapeRepeat.off => TapeRepeat.all,
    TapeRepeat.all => TapeRepeat.one,
    TapeRepeat.one => TapeRepeat.off,
  };
}
