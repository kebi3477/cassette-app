import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

import '../../../data/model/api_error.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/models/user.dart';
import '../../../utils/result.dart';
import '../../core/ui/toast.dart';

/// 이름 정하기 (`auName`) — 최대 8자, 카운터, 테이프 라벨 미리보기.
class NameViewModel extends ChangeNotifier {
  NameViewModel({required AuthRepository auth, required this._toast})
    : _auth = auth,
      _name = _clip(auth.suggestedName ?? '');

  final AuthRepository _auth;
  final ToastController _toast;
  String _name;
  bool _busy = false;

  String get name => _name;
  int get length => _name.characters.length;

  /// 8자면 카운터가 레드 (`nameInk`)
  bool get atMax => length >= User.maxNameLength;
  bool get canSubmit => _name.trim().isNotEmpty;

  /// 테이프 라벨에 비칠 이름 (`auPreview`)
  String get preview => _name.trim().isEmpty ? ' ' : _name.trim();

  static String _clip(String v) =>
      v.characters.take(User.maxNameLength).toString();

  void setName(String v) {
    _name = _clip(v);
    notifyListeners();
  }

  /// 시작하기 (`auDone`)
  Future<void> submit() async {
    if (!canSubmit) {
      _toast.show('이름을 적어주세요');
      return;
    }
    if (_busy) return;
    _busy = true;
    final r = await _auth.setName(_name.trim());
    _busy = false;
    if (r case Error(:final error)) {
      _toast.show(
        error is ApiException ? error.message : '잠시 문제가 생겼어요. 다시 시도해 주세요',
      );
    }
  }

  /// ‹ 뒤로 → 로그인 화면 (`auBack`)
  Future<void> back() => _auth.logout();
}
