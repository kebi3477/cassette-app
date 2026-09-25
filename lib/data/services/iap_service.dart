import 'dart:async';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../domain/models/shop.dart';

/// 스토어 결제 결과.
sealed class IapOutcome {
  const IapOutcome();
}

class IapPurchased extends IapOutcome {
  const IapPurchased(this.receipt);

  final IapReceipt receipt;
}

/// 사용자가 결제를 취소했다 (서버 호출 없이 토스트만)
class IapCanceled extends IapOutcome {
  const IapCanceled();
}

class IapFailed extends IapOutcome {
  const IapFailed([this.message]);

  final String? message;
}

/// 크레딧 팩 결제 (`in_app_purchase`). 실제 구현은 [StoreIapService].
abstract class IapService {
  /// [productId]를 결제한다. 스토어 결제창이 닫힐 때까지 기다린다.
  Future<IapOutcome> buy(String productId);

  /// 서버 확인(`POST /billing/iap`)이 끝난 거래를 스토어에 마무리한다.
  Future<void> complete(IapReceipt receipt);

  /// 결제 진행 시트의 "결제 취소" — 진행 중인 [buy]를 [IapCanceled]로 끝낸다.
  void cancel();
}

/// App Store / Google Play 결제.
class StoreIapService implements IapService {
  StoreIapService() {
    _sub = _iap.purchaseStream.listen(_onPurchases);
  }

  final InAppPurchase _iap = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final Map<String, PurchaseDetails> _pending = {};
  Completer<IapOutcome>? _waiting;
  String? _waitingFor;

  static String get _store => IapReceipt.storeFor(isIOS: Platform.isIOS);

  @override
  Future<IapOutcome> buy(String productId) async {
    if (!await _iap.isAvailable()) return const IapFailed();
    final res = await _iap.queryProductDetails({productId});
    if (res.productDetails.isEmpty) return const IapFailed();
    final done = Completer<IapOutcome>();
    _waiting = done;
    _waitingFor = productId;
    final started = await _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: res.productDetails.first),
      // 서버 확인 뒤 complete()로 마무리한다.
      autoConsume: false,
    );
    if (!started) return const IapFailed();
    return done.future;
  }

  void _onPurchases(List<PurchaseDetails> list) {
    for (final p in list) {
      if (p.productID != _waitingFor) continue;
      final done = _waiting;
      if (done == null || done.isCompleted) continue;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final id = p.purchaseID ?? p.transactionDate ?? p.productID;
          _pending[id] = p;
          done.complete(
            IapPurchased(
              IapReceipt(
                store: _store,
                productId: p.productID,
                transactionId: id,
                verificationData: p.verificationData.serverVerificationData,
              ),
            ),
          );
        case PurchaseStatus.canceled:
          done.complete(const IapCanceled());
        case PurchaseStatus.error:
          done.complete(IapFailed(p.error?.message));
        case PurchaseStatus.pending:
          break;
      }
    }
  }

  /// iOS는 `finishTransaction`. Android는 서버가 consume하므로 앱은 하지 않는다 (계약서 §15).
  @override
  Future<void> complete(IapReceipt receipt) async {
    final p = _pending.remove(receipt.transactionId);
    if (!Platform.isIOS) return;
    if (p != null && p.pendingCompletePurchase) await _iap.completePurchase(p);
  }

  @override
  void cancel() {
    final done = _waiting;
    if (done != null && !done.isCompleted) done.complete(const IapCanceled());
  }

  Future<void> dispose() => _sub.cancel();
}
