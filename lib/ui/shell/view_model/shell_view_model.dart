import 'package:flutter/foundation.dart';

import '../../../data/repositories/shelf_repository.dart';
import '../../../domain/models/shelf.dart';
import '../../../utils/result.dart';

/// 탭바에 필요한 값 — 서랍에 안 뜯은 테이프가 있는지 (`hasNew`).
class ShellViewModel extends ChangeNotifier {
  ShellViewModel({required ShelfRepository shelfRepository})
    : _shelf = shelfRepository {
    _shelf.addListener(load);
  }

  final ShelfRepository _shelf;
  bool _hasNew = false;

  bool get hasNew => _hasNew;

  Future<void> load() async {
    final r = await _shelf.getShelf();
    if (r is Ok<Shelf>) {
      _hasNew = r.value.hasNew;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _shelf.removeListener(load);
    super.dispose();
  }
}
