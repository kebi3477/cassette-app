import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../data/services/sound_service.dart';

/// 공용 위젯(‹ 뒤로, ✕ 닫기)이 쓰는 효과음. 앱 시작 때 [service]를 정한다.
/// 녹음·재생처럼 순서가 중요한 곳은 ViewModel이 [SoundService]를 직접 받아 쓴다.
abstract final class UiSounds {
  static SoundService service = const NoSoundService();

  /// 울리고 기다리지 않는다.
  static void play(UiSound sound) =>
      unawaited(service.play(sound).catchError((_) {}));

  /// ‹ 뒤로 · ✕ 닫기
  static void back() => play(UiSound.off);
}

/// 시스템 뒤로 가기 효과음 (off.wav)
/// - iOS 가장자리 밀어서 뒤로: 내비게이터의 사용자 제스처 중에 pop되면
/// - Android 뒤로 버튼: [didPopRoute] (소리만 내고 처리는 라우터에 넘긴다)
class BackSoundObserver extends NavigatorObserver with WidgetsBindingObserver {
  bool _gesture = false;

  @override
  void didStartUserGesture(
    Route<dynamic> route,
    Route<dynamic>? previousRoute,
  ) => _gesture = true;

  @override
  void didStopUserGesture() => _gesture = false;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_gesture) UiSounds.back();
  }

  @override
  Future<bool> didPopRoute() async {
    UiSounds.back();
    return false;
  }
}
