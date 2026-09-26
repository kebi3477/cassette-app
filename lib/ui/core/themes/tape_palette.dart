import 'package:flutter/painting.dart';

import '../../../domain/models/tape_type.dart';

/// 테이프 종류별 색과 표기 — tokens.json › `tape`, logic.js › `T`.
class TapePalette {
  const TapePalette({
    required this.shell,
    required this.edge,
    required this.band,
    required this.len,
    required this.name,
    required this.packFull,
  });

  /// 케이스 색
  final Color shell;

  /// 아래 사다리꼴 색
  final Color edge;

  /// 라벨 윗띠 색
  final Color band;

  /// 띠 오른쪽 글자 (`15 SEC`)
  final String len;

  /// 화면 표기 (`15초`)
  final String name;

  /// 가득 감긴 릴 지름(px). 빈 릴은 [TapePalette.packEmpty].
  final double packFull;

  static const double packEmpty = 30;

  /// 15초 — 검정·레드 띠 (디자인의 옛 1분 자리)
  static const s15 = TapePalette(
    shell: Color(0xFF1E1E1E),
    edge: Color(0xFF161616),
    band: Color(0xFFE5402B),
    len: '15 SEC',
    name: '15초',
    packFull: 50,
  );

  /// 1분 — 베이지·블루 띠 (옛 3분 자리)
  static const m1 = TapePalette(
    shell: Color(0xFFE9E5DC),
    edge: Color(0xFFD9D4C9),
    band: Color(0xFF2E6BD6),
    len: '1 MIN',
    name: '1분',
    packFull: 58,
  );

  /// 3분 — 회색·검정 띠 (옛 5분 자리)
  static const m3 = TapePalette(
    shell: Color(0xFF76858F),
    edge: Color(0xFF66747E),
    band: Color(0xFF111111),
    len: '3 MIN',
    name: '3분',
    packFull: 66,
  );

  static TapePalette of(TapeType type) => switch (type) {
    TapeType.s15 => s15,
    TapeType.m1 => m1,
    TapeType.m3 => m3,
  };

  /// 진행률 [p](0~1)에 따른 왼쪽 릴 지름: full → 30.
  double packL(double p) => _round1(packFull - (packFull - packEmpty) * p);

  /// 진행률 [p](0~1)에 따른 오른쪽 릴 지름: 30 → full.
  double packR(double p) => _round1(packEmpty + (packFull - packEmpty) * p);

  static double _round1(double v) => (v * 10).roundToDouble() / 10;
}

/// 테이프 그래픽 내부 색 — source/Tape.template.html.
abstract final class TapeInk {
  static const labelLine = Color(0xFFE2DED5);
  static const title = Color(0xFF3A3A38);
  static const fine = Color(0xFFB3AEA3);
  static const windowTop = Color(0xFF2B2826);
  static const windowBottom = Color(0xFF171513);
  static const reel0 = Color(0xFF6B452C);
  static const reel1 = Color(0xFF4A2E1D);
  static const reel2 = Color(0xFF3A2315);
  static const reel3 = Color(0xFF2A180E);
  static const hub = Color(0xFFEDEBE6);
  static const hubCore = Color(0xFF1A1816);
  static const tooth = Color(0xFF0E0D0C);
  static const toothLight = Color(0xFF8C7F6A);
  static const toothBrown = Color(0xFF5A3A26);
  static const screwLight = Color(0xFFD8D8D6);
  static const screwDark = Color(0xFF6E6E6C);
}
