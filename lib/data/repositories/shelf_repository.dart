import 'package:flutter/foundation.dart';

import '../../domain/models/shelf.dart';
import '../../utils/result.dart';

/// 서랍 (분류 안 함 + 칸). 새 테이프가 오면 리스너에게 알린다.
abstract class ShelfRepository extends ChangeNotifier {
  Future<Result<Shelf>> getShelf();
}
