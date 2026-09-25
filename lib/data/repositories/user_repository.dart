import 'package:flutter/foundation.dart';

import '../../domain/models/me.dart';
import '../../utils/result.dart';

/// 내 정보 (`/users/me`).
abstract class UserRepository extends ChangeNotifier {
  Future<Result<Me>> getMe();

  /// 이름 수정 (최대 8자)
  Future<Result<Me>> updateName(String name);
}
