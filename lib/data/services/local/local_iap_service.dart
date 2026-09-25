import 'dart:async';

import '../../../domain/models/shop.dart';
import '../iap_service.dart';
import 'local_behavior.dart';

/// 스토어 없이 결제를 흉내 낸다 — 1.4초 뒤 성공, `FAIL_MODE=payFail`이면 실패,
/// 결제 진행 시트의 "결제 취소"를 누르면 취소 (프로토타입 `charge`).
class LocalIapService implements IapService {
  LocalIapService([this._behavior = const LocalBehavior()]);

  final LocalBehavior _behavior;

  /// 프로토타입 `later('pay', 1400)`
  static const payTime = Duration(milliseconds: 1400);

  Completer<IapOutcome>? _waiting;
  Timer? _timer;
  int _n = 0;

  @override
  Future<IapOutcome> buy(String productId) {
    final done = Completer<IapOutcome>();
    _waiting = done;
    _timer?.cancel();
    _timer = Timer(payTime, () {
      if (done.isCompleted) return;
      done.complete(
        _behavior.failsPay
            ? const IapFailed()
            : IapPurchased(
                IapReceipt(
                  store: IapReceipt.localStore,
                  productId: productId,
                  transactionId:
                      'local-${DateTime.now().microsecondsSinceEpoch}-${_n++}',
                  verificationData: 'local',
                ),
              ),
      );
    });
    return done.future;
  }

  @override
  Future<void> complete(IapReceipt receipt) async {}

  @override
  void cancel() {
    _timer?.cancel();
    final done = _waiting;
    if (done != null && !done.isCompleted) done.complete(const IapCanceled());
  }
}
