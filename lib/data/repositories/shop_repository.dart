import '../../domain/models/shop.dart';
import '../../utils/result.dart';

/// 상점 (`/shop`)과 스토어 결제 확인 (`/billing/iap`).
abstract class ShopRepository {
  /// `GET /shop/products` — 가격은 서버가 정한다.
  Future<Result<ShopCatalog>> getCatalog();

  /// 크레딧으로 사기 (`POST /shop/purchases`). 모자라면 `INSUFFICIENT_CREDITS`(+`need`).
  Future<Result<PurchaseResult>> purchase(
    String productId, {
    required String idempotencyKey,
  });

  /// 스토어 영수증 확인 → 크레딧 충전 (`POST /billing/iap`). 성공하면 새 잔액.
  Future<Result<int>> verifyIap(
    IapReceipt receipt, {
    required String idempotencyKey,
  });
}
