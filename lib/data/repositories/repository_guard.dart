import '../../utils/result.dart';
import '../model/api_error.dart';

/// ApiClient 호출을 [Result]로 감싼다. [ApiException]과 그 밖의 예외를 모두 오류로 돌린다.
Future<Result<T>> guard<T>(Future<T> Function() call) async {
  try {
    return Result.ok(await call());
  } on ApiException catch (e) {
    return Result.error(e);
  } on Exception catch (e) {
    return Result.error(e);
  }
}
