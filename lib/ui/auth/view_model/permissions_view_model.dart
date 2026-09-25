import 'package:flutter/foundation.dart';

import '../../../data/repositories/user_repository.dart';
import '../../../data/services/push_service.dart';
import '../../../data/services/recorder_service.dart';
import '../../../routing/app_flow.dart';

enum PermissionStep { mic, noti }

/// 마이크 안내(`auMic`) → 알림 안내(`auNoti`). 디자인의 시스템 알림 목업 대신 OS 대화상자를 띄운다.
class PermissionsViewModel extends ChangeNotifier {
  PermissionsViewModel({
    required this._recorder,
    required this._push,
    required this._users,
    required this._flow,
  });

  final RecorderService _recorder;
  final PushService _push;
  final UserRepository _users;
  final AppFlow _flow;
  bool _busy = false;

  /// 계속 (`micAsk`) — 허용하든 거부하든 알림 안내로 간다. 거부하면 녹음 탭이 `micDeniedOn`.
  Future<bool> askMic() async {
    if (_busy) return false;
    _busy = true;
    try {
      await _recorder.hasPermission(request: true);
    } catch (_) {
    } finally {
      _busy = false;
    }
    return true;
  }

  /// 알림 받기 (`notiAsk`) — OS 대화상자. 결과를 `notificationsEnabled`에 남긴다.
  Future<void> askNotifications() async {
    if (_busy) return;
    _busy = true;
    bool granted;
    try {
      granted = await _push.requestPermission();
    } catch (_) {
      granted = false;
    }
    await _users.setNotifications(granted);
    _busy = false;
    await _flow.finishPermissions();
  }

  /// 나중에 할게요 (`notiLater`) — 알림을 끈다.
  Future<void> later() async {
    await _users.setNotifications(false);
    await _flow.finishPermissions();
  }
}
