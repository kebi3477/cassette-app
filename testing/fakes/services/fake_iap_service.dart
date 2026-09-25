import 'package:cassette_app/data/services/iap_service.dart';
import 'package:cassette_app/domain/models/shop.dart';

/// 결제 결과를 시험마다 정한다 (기본: 바로 성공).
class FakeIapService implements IapService {
  IapOutcome Function(String productId) outcome = (id) => IapPurchased(
    IapReceipt(
      store: 'app_store',
      productId: id,
      transactionId: 'tx-$id-${DateTime.now().microsecondsSinceEpoch}',
      verificationData: 'jws',
    ),
  );
  Duration delay = Duration.zero;
  final List<String> bought = [];
  final List<IapReceipt> completed = [];
  bool canceled = false;

  @override
  Future<IapOutcome> buy(String productId) async {
    bought.add(productId);
    canceled = false;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return canceled ? const IapCanceled() : outcome(productId);
  }

  @override
  Future<void> complete(IapReceipt receipt) async => completed.add(receipt);

  @override
  void cancel() => canceled = true;
}
