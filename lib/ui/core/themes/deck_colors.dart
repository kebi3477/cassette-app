import 'package:flutter/painting.dart';

/// 데크형 녹음 버튼 (`deckBtn` · `deckConfirm`, 디자인 v4) — 은색 브러시드 금속 본체, 검은 키 홈, 한 조각 키.
/// 값은 `source/TapeletterApp.template.html`·`logic.js`의 `dk.*`, `ledBg` 등과 같다.
abstract final class DeckColors {
  // 키 윗면 (`dk.*.bg`) — 윗면 14px에서 꺾이는 선
  static const keyLit = [
    Color(0xFFFFFFFF),
    Color(0xFFEDEDEA),
    Color(0xFFD6D6D3),
    Color(0xFF8E8E8A),
    Color(0xFFB5B5B2),
    Color(0xFFDCDCD9),
    Color(0xFFE6E6E3),
    Color(0xFFCDCDCA),
  ];
  static const keyOff = [
    Color(0xFFD6D6D3),
    Color(0xFFC4C4C1),
    Color(0xFFB0B0AD),
    Color(0xFF6E6E6B),
    Color(0xFF8E8E8A),
    Color(0xFFB5B5B2),
    Color(0xFFBDBDBA),
    Color(0xFFA8A8A5),
  ];

  // 키 아래 두께 (`UP` · `DN` · `OFF`)
  static const keyEdge = Color(0xFF5E5E5B);
  static const keyEdgeOff = Color(0xFF4A4A48);
  static const keyFoot = Color(0xFF0A0A0A);
  static const keyHighlight = Color(
    0x99FFFFFF,
  ); // inset 1px 0 0 rgba(255,255,255,.6)
  static const keyHighlightDown = Color(0x66FFFFFF); // .4
  static const keyHighlightOff = Color(0x4DFFFFFF); // .3
  static const keyInnerRight = Color(
    0x2E000000,
  ); // inset -1px 0 0 rgba(0,0,0,.18)
  static const keyPressShade = Color(
    0x59000000,
  ); // inset 0 -8px 12px -8px rgba(0,0,0,.35)

  static const icon = Color(0xFF2A2A2A);
  static const label = Color(0xFF6E6E6B);
  static const dot = Color(0x47000000); // rgba(0,0,0,.28)

  // LED — REC (`ledBg`) · PLAY (`pLedBg`)
  static const recLedOn = Color(0xFFFF4A33);
  static const recLedOff = Color(0xFF7A2A20);
  static const recLedGlow = Color(0xCCFF4A33); // rgba(255,74,51,.8)
  static const playLedOn = Color(0xFF6BD66B);
  static const playLedOff = Color(0xFF2F4A2F);
  static const playLedGlow = Color(0xB36BD66B); // rgba(107,214,107,.7)

  // 본체 — 은색 브러시드 금속
  static const bodyTop = Color(0xFFE4E4E1);
  static const bodyMid = Color(0xFFC9C9C6);
  static const bodyBottom = Color(0xFFB9B9B6);
  static const bodyStripeLight = Color(0x12FFFFFF); // rgba(255,255,255,.07)
  static const bodyStripeDark = Color(0x09000000); // rgba(0,0,0,.035)
  static const bodyInnerTop = Color(0xFFF7F7F5);
  static const bodyInnerBottom = Color(0xFF8E8E8A);
  static const bodyShadow = Color(
    0x59000000,
  ); // 0 -6px 18px -10px rgba(0,0,0,.35)
  static const bodyShine = [
    Color(0xFF9A9A97),
    Color(0xFFF7F7F5),
    Color(0xFFFFFFFF),
    Color(0xFFF7F7F5),
    Color(0xFF9A9A97),
  ];

  // 키 홈
  static const slotTop = Color(0xFF0A0A0A);
  static const slotBottom = Color(0xFF1E1E1E);
  static const slotInner = Color(0xE6000000); // inset 0 4px 6px rgba(0,0,0,.9)
  static const slotLipBelow = Color(0xFFEDEDEA);
  static const slotLipAbove = Color(0xFF8E8E8A);
}
