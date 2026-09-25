import 'package:connectivity_plus/connectivity_plus.dart';

/// 기기의 네트워크 연결 (오프라인 배너)
abstract class ConnectivityService {
  Future<bool> isOnline();

  Stream<bool> get onlineChanges;
}

class PlusConnectivityService implements ConnectivityService {
  final Connectivity _c = Connectivity();

  static bool _online(List<ConnectivityResult> r) =>
      r.any((x) => x != ConnectivityResult.none);

  @override
  Future<bool> isOnline() async => _online(await _c.checkConnectivity());

  @override
  Stream<bool> get onlineChanges => _c.onConnectivityChanged.map(_online);
}
