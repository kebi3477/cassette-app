import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/app_repository.dart';
import '../../../data/services/api/api_status.dart';
import '../../../data/services/connectivity_service.dart';
import '../../core/ui/toast.dart';

/// 오프라인 배너(`offlineOn`)와 서버 오류 화면(`serverOn`).
class StatusViewModel extends ChangeNotifier {
  StatusViewModel({
    required this._connectivity,
    required ApiStatus apiStatus,
    required this._app,
    required this._toast,
    this.onRecovered,
  }) : _api = apiStatus {
    _api.addListener(notifyListeners);
  }

  /// 다시 시도 `later('srv', 900)`
  static const retryTime = Duration(milliseconds: 900);

  final ConnectivityService _connectivity;
  final ApiStatus _api;
  final AppRepository _app;
  final ToastController _toast;

  /// 서버가 돌아왔을 때 — 화면 데이터를 다시 불러오게 한다.
  final VoidCallback? onRecovered;

  StreamSubscription<bool>? _sub;
  bool _deviceOnline = true;
  bool _retrying = false;

  /// 기기가 오프라인이거나, 마지막 요청이 서버에 닿지 않았다.
  bool get offline => !_deviceOnline || _api.networkFailed;
  bool get serverError => _api.serverError;
  bool get retrying => _retrying;

  Future<void> start() async {
    _deviceOnline = await _connectivity.isOnline();
    notifyListeners();
    _sub = _connectivity.onlineChanges.listen((online) {
      _deviceOnline = online;
      // 다시 연결되면 요청 실패 표시도 지운다.
      if (online) _api.reportOk();
      notifyListeners();
    });
  }

  /// 서버 오류 화면의 "다시 시도" — 0.9초 동안 "다시 시도하는 중…"
  Future<void> retry() async {
    if (_retrying) return;
    _retrying = true;
    notifyListeners();
    final results = await Future.wait([
      _app.healthy(),
      Future<void>.delayed(retryTime).then((_) => true),
    ]);
    _retrying = false;
    if (results.first) {
      _api.clearServerError();
      onRecovered?.call();
    } else {
      _toast.show('아직 문제가 있어요. 잠시 후 다시 해주세요');
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _api.removeListener(notifyListeners);
    super.dispose();
  }
}
