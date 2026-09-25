import 'package:flutter/foundation.dart';

import '../../../data/repositories/shelf_repository.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/me.dart';
import '../../../utils/result.dart';

/// 탭바에 필요한 값 — 서랍에 안 뜯은 테이프가 있는지 (`GET /users/me`의 `drawer.unopenedCount`).
class ShellViewModel extends ChangeNotifier {
  ShellViewModel({
    required UserRepository userRepository,
    required ShelfRepository shelfRepository,
  }) : _users = userRepository,
       _shelf = shelfRepository {
    // 소포를 뜯거나 옮기면 서랍이 바뀌므로 다시 불러온다.
    _shelf.addListener(load);
    _users.addListener(load);
  }

  final UserRepository _users;
  final ShelfRepository _shelf;
  int _unopened = 0;

  bool get hasNew => _unopened > 0;

  Future<void> load() async {
    final r = await _users.getMe();
    if (r is Ok<Me>) {
      _unopened = r.value.drawer.unopenedCount;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _shelf.removeListener(load);
    _users.removeListener(load);
    super.dispose();
  }
}
