import '../../domain/models/user.dart';
import '../../utils/result.dart';

/// 내 정보.
abstract class UserRepository {
  Future<Result<User>> getMe();

  /// 이름 수정 (최대 8자)
  Future<Result<User>> updateName(String name);
}
