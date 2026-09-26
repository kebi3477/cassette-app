import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/model/api_error.dart';
import '../../../data/repositories/share_repository.dart';
import '../../../data/services/app_prefs.dart';
import '../../../data/services/deep_link_service.dart';
import '../../../domain/models/share_link.dart';
import '../../../routing/app_flow.dart';
import '../../../utils/result.dart';
import '../../core/ui/toast.dart';

/// 링크 처리 결과 — 화면 이동은 라우터를 가진 위젯이 한다.
sealed class LinkEvent {
  const LinkEvent();
}

/// 아직 받지 않은 링크의 소포 화면 — 뜯을 때 받는다(`POST /share/{token}/claim`).
class OpenLinkParcel extends LinkEvent {
  const OpenLinkParcel(this.token);

  final String token;
}

/// 받은 소포 열기 (`vParcel` + `viaLink` 칩)
class OpenClaimedParcel extends LinkEvent {
  const OpenClaimedParcel(this.itemId, {required this.friendMade});

  final String itemId;

  /// 서로 친구가 됐는지 ("○○님과 친구가 되었어요" 칩)
  final bool friendMade;
}

/// 링크 오류 화면 (`leOn`)
class ShowLinkError extends LinkEvent {
  const ShowLinkError(this.kind, {this.url});

  final LinkErrorKind kind;

  /// own일 때 다시 공유할 주소
  final String? url;
}

/// `https://<도메인>/t/{token}`(유니버설 링크·앱 링크)과 `tapeletter://t/{token}`(웹 페이지의 "앱에서 열기")을
/// 받아 `GET /share/{token}`으로 연다. 받기(claim)는 소포를 뜯을 때 재생 화면이 한다.
/// 로그인 전이면 토큰을 기기에 보관했다가 앱 본문에 들어온 뒤 처리한다.
class LinkViewModel extends ChangeNotifier {
  LinkViewModel({
    required this._deepLinks,
    required this._prefs,
    required this._share,
    required this._flow,
    required this._toast,
    required this.publicHost,
  });

  /// 커스텀 스킴 (웹 페이지의 "앱에서 열기")
  static const scheme = 'tapeletter';

  final DeepLinkService _deepLinks;
  final AppPrefs _prefs;
  final ShareRepository _share;
  final AppFlow _flow;
  final ToastController _toast;

  /// 링크 도메인 (`--dart-define=PUBLIC_HOST=`). 비어 있으면 도메인을 가리지 않는다.
  final String publicHost;

  final _events = StreamController<LinkEvent>.broadcast();
  StreamSubscription<Uri>? _sub;
  bool _busy = false;

  Stream<LinkEvent> get events => _events.stream;

  Future<void> start() async {
    _sub = _deepLinks.links.listen(accept);
    _flow.addListener(_drain);
    final first = await _deepLinks.initialLink();
    if (first != null) await accept(first);
  }

  /// 링크 주소에서 토큰을 꺼낸다. 우리 링크가 아니면 null.
  @visibleForTesting
  String? tokenOf(Uri u) {
    final segs = u.pathSegments.where((s) => s.isNotEmpty).toList();
    if (u.scheme == scheme) {
      // tapeletter://t/{token}
      if (u.host == 't' && segs.length == 1) return segs.first;
      return null;
    }
    if (u.scheme != 'https' && u.scheme != 'http') return null;
    if (publicHost.isNotEmpty && u.host != publicHost) return null;
    if (segs.length == 2 && segs.first == 't') return segs.last;
    return null;
  }

  Future<void> accept(Uri uri) async {
    final token = tokenOf(uri);
    if (token == null) return;
    if (_flow.inApp) {
      await _handle(token);
    } else {
      await _prefs.setPendingLink(token);
    }
  }

  Future<void> _drain() async {
    if (!_flow.inApp || _busy) return;
    final token = await _prefs.pendingLink();
    if (token == null) return;
    await _prefs.setPendingLink(null);
    await _handle(token);
  }

  Future<void> _handle(String token) async {
    _busy = true;
    try {
      final opened = await _share.open(token);
      switch (opened) {
        case Ok<ShareLink>(:final value) when value.claimed:
          // 내가 이미 받은 링크 → 서랍의 그 테이프
          _events.add(OpenClaimedParcel(value.deliveryId!, friendMade: false));
        case Ok<ShareLink>():
          // 뜯기 전 소포 화면. 닫으면 링크는 그대로 받을 수 있다.
          _events.add(OpenLinkParcel(token));
        case Error<ShareLink>(:final error):
          _fail(error);
      }
    } finally {
      _busy = false;
    }
  }

  void _fail(Exception e) {
    if (linkErrorOf(e) case (final kind, final url)) {
      return _events.add(ShowLinkError(kind, url: url));
    }
    _toast.show(e is ApiException ? e.message : '잠시 문제가 생겼어요. 다시 시도해 주세요');
  }

  @override
  void dispose() {
    _sub?.cancel();
    _flow.removeListener(_drain);
    _events.close();
    super.dispose();
  }
}
