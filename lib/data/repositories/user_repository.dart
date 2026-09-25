import 'package:flutter/foundation.dart';

import '../../domain/models/me.dart';
import '../../utils/result.dart';

/// 내 정보 (`/users/me`).
abstract class UserRepository extends ChangeNotifier {
  Future<Result<Me>> getMe();

  /// 이름 수정 (최대 8자)
  Future<Result<Me>> updateName(String name);

  /// 알림 켜기/끄기 (`PATCH /users/me { notificationsEnabled }`)
  Future<Result<Me>> setNotifications(bool enabled);

  /// 회원 탈퇴 (`DELETE /users/me`)
  Future<Result<void>> withdraw();

  /// 크레딧·서랍·통계가 다른 곳에서 바뀌었을 때 다시 불러오라고 알린다.
  void invalidate() => notifyListeners();
}
