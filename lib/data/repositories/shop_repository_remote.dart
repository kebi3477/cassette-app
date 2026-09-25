import '../../domain/models/shop.dart';
import '../../utils/result.dart';
import '../model/mappers.dart';
import '../model/shop_dto.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';
import 'shop_repository.dart';

class ShopRepositoryRemote implements ShopRepository {
  ShopRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<Result<ShopCatalog>> getCatalog() =>
      guard(() async => (await _api.getProducts()).toDomain());

  @override
  Future<Result<PurchaseResult>> purchase(
    String productId, {
    required String idempotencyKey,
  }) => guard(
    () async => (await _api.purchase(
      productId,
      idempotencyKey: idempotencyKey,
    )).toDomain(),
  );

  @override
  Future<Result<int>> verifyIap(
    IapReceipt receipt, {
    required String idempotencyKey,
  }) => guard(() async {
    // 스토어 없이 흉내 낸 결제는 개발 서버의 충전 흉내로 보낸다.
    if (receipt.store == IapReceipt.localStore) {
      return (await _api.devCredits(
        DevCreditsRequest.charge(receipt.productId),
      )).credits;
    }
    return (await _api.verifyIap(
      IapRequest(
        store: receipt.store,
        productId: receipt.productId,
        transactionId: receipt.transactionId,
        verificationData: receipt.verificationData,
      ),
      idempotencyKey: idempotencyKey,
    )).credits;
  });
}
