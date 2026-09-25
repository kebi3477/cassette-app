import 'package:flutter/foundation.dart';

/// 요청 결과로 본 연결 상태 — 오프라인 배너(`offlineOn`)와 서버 오류 화면(`serverOn`).
class ApiStatus extends ChangeNotifier {
  bool _networkFailed = false;
  bool _serverError = false;

  /// 마지막 요청이 서버에 닿지 않았다 (다음 성공 요청까지)
  bool get networkFailed => _networkFailed;

  /// 5xx를 받았다 (다시 시도로 풀 때까지)
  bool get serverError => _serverError;

  void reportOk() {
    if (!_networkFailed) return;
    _networkFailed = false;
    notifyListeners();
  }

  void reportNetworkFailure() {
    if (_networkFailed) return;
    _networkFailed = true;
    notifyListeners();
  }

  void reportServerError() {
    if (_serverError) return;
    _serverError = true;
    notifyListeners();
  }

  void clearServerError() {
    if (!_serverError) return;
    _serverError = false;
    notifyListeners();
  }
}
