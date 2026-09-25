import 'tape_type.dart';

/// 상점에서 크레딧으로 사는 상품 (`shopTapes`, `shopEtc`)
sealed class ShopItem {
  const ShopItem({required this.id, required this.name, required this.price});

  final String id;
  final String name;

  /// 크레딧
  final int price;
}

/// 테이프 (5개 묶음은 쌓인 모양)
class TapeProduct extends ShopItem {
  const TapeProduct({
    required super.id,
    required super.name,
    required super.price,
    required this.type,
    required this.qty,
  });

  final TapeType type;
  final int qty;
}

/// 서랍 넓히기
class DrawerProduct extends ShopItem {
  const DrawerProduct({
    required super.id,
    required super.name,
    required super.price,
    required this.slots,
  });

  final int slots;
}

/// 크레딧 팩 (스토어 결제, `packs`)
class CreditPack {
  const CreditPack({
    required this.productId,
    required this.credits,
    required this.priceLabel,
  });

  final String productId;
  final int credits;

  /// `₩1,100`
  final String priceLabel;
}

class ShopCatalog {
  const ShopCatalog({
    required this.tapes,
    required this.drawer,
    required this.packs,
    required this.giftAmounts,
  });

  static const empty = ShopCatalog(
    tapes: [],
    drawer: [],
    packs: [],
    giftAmounts: [10, 30, 50, 100],
  );

  final List<TapeProduct> tapes;
  final List<DrawerProduct> drawer;
  final List<CreditPack> packs;
  final List<int> giftAmounts;
}

/// 구매 뒤 잔액·보유·서랍 (`POST /shop/purchases`)
class PurchaseResult {
  const PurchaseResult({
    required this.credits,
    required this.owned,
    required this.stored,
    required this.cap,
  });

  final int credits;
  final Map<TapeType, int> owned;
  final int stored;
  final int cap;
}

/// 스토어 결제 영수증 (`POST /billing/iap`)
class IapReceipt {
  const IapReceipt({
    required this.store,
    required this.productId,
    required this.transactionId,
    required this.verificationData,
  });

  /// App Store — 서버 `IAP_STORES`의 `app_store`
  static const appStore = 'app_store';

  /// Google Play — 서버 `IAP_STORES`의 `play`
  static const playStore = 'play';

  /// 스토어 없이 흉내 낸 결제 — 서버에는 `POST /dev/credits {charge}`로 보낸다.
  static const localStore = 'local';

  /// 기기에 맞는 `store` 값
  static String storeFor({required bool isIOS}) => isIOS ? appStore : playStore;

  /// [appStore] · [playStore] · [localStore]
  final String store;
  final String productId;
  final String transactionId;
  final String verificationData;
}
