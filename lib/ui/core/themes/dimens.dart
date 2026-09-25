import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

/// tokens.json › radius
abstract final class AppRadius {
  static const double sheet = 26;
  static const double card = 24;
  static const double button = 16;
  static const double row = 14;
  static const double queueRow = 12;
  static const double pill = 999;
  static const double phone = 48;

  static const sheetTop = BorderRadius.vertical(top: Radius.circular(sheet));
}

/// tokens.json › size
abstract final class AppSizes {
  static const double primaryButton = 56;
  static const double row = 60;
  static const double inboxRowOld = 68;
  static const double chip = 40;
  static const double pill = 28;
  static const double pricePill = 34;
  static const double tabBar = 84;
  static const double statusBar = 50;
  static const double header = 60;
  static const double backBar = 56;
  static const double recordButton = 84;
  static const double playButton = 60;
  static const double minTap = 44;

  /// 원본 Tape 컴포넌트 고정 크기
  static const tape = Size(320, 204);

  /// 미니 테이프 / 미니 소포
  static const miniTape = Size(48, 32);

  /// 녹음 대기 화면에서 Tape 축소 비율
  static const double carouselScale = .825;
}

/// tokens.json › spacing
abstract final class AppSpacing {
  static const double screen = 24;
  static const double listInset = 12;
  static const double rowPadding = 12;
  static const double bottomSafe = 30;
}

/// tokens.json › shadow
abstract final class AppShadows {
  static const tape = [
    BoxShadow(color: Color(0x40000000), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(
      color: Color(0x47000000),
      offset: Offset(0, 16),
      blurRadius: 32,
      spreadRadius: -8,
    ),
  ];
  static const miniTape = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const dragGhost = [
    BoxShadow(color: Color(0x33000000), offset: Offset(0, 14), blurRadius: 30),
    BoxShadow(color: Color(0x0A000000), spreadRadius: 1),
  ];
  static const segmentOn = [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 1), blurRadius: 3),
  ];
  static const label = [
    BoxShadow(color: Color(0x0F000000), spreadRadius: 1),
    BoxShadow(
      color: Color(0x47000000),
      offset: Offset(0, 10),
      blurRadius: 20,
      spreadRadius: -8,
    ),
  ];

  /// 소포 박스 앞면 `0 14px 30px -10px rgba(0,0,0,.3)`
  static const parcel = [
    BoxShadow(
      color: Color(0x4D000000),
      offset: Offset(0, 14),
      blurRadius: 30,
      spreadRadius: -10,
    ),
  ];

  /// 소포 뚜껑 `0 2px 3px rgba(0,0,0,.12)`
  static const flap = [
    BoxShadow(color: Color(0x1F000000), offset: Offset(0, 2), blurRadius: 3),
  ];

  /// 받는 사람 메모 `0 1px 2px rgba(0,0,0,.15)`
  static const memo = [
    BoxShadow(color: Color(0x26000000), offset: Offset(0, 1), blurRadius: 2),
  ];
}

/// 원본 keyframes·transition의 시간과 곡선.
abstract final class AppMotion {
  /// `cubic-bezier(.2,.8,.2,1)` — 캐러셀 붙기, 시트 올라오기
  static const snap = Cubic(.2, .8, .2, 1);

  /// `cubic-bezier(.3,.7,.3,1)` — clack, insert
  static const settle = Cubic(.3, .7, .3, 1);

  /// `cubic-bezier(.3,.6,.3,1)` — tapeIn
  static const tapeIn = Cubic(.3, .6, .3, 1);

  /// `cubic-bezier(.5,0,.8,.4)` — fly
  static const fly = Cubic(.5, 0, .8, .4);

  static const carousel = Duration(milliseconds: 350);
  static const slideUp = Duration(milliseconds: 300);
  static const fadeUp = Duration(milliseconds: 250);
  static const toast = Duration(milliseconds: 1800);
}
