import 'json.dart';
import 'me_dto.dart';
import 'wallet_dto.dart';

/// `GET /shop/products` — 가격은 서버가 정한다.
class ProductsDto {
  const ProductsDto({
    required this.tapes,
    required this.drawer,
    required this.creditPacks,
    required this.giftAmounts,
  });

  final List<TapeProductDto> tapes;
  final List<DrawerProductDto> drawer;
  final List<CreditPackDto> creditPacks;
  final List<int> giftAmounts;

  factory ProductsDto.fromJson(Json j) => ProductsDto(
    tapes: parseList(j['tapes'], TapeProductDto.fromJson),
    drawer: parseList(j['drawer'], DrawerProductDto.fromJson),
    creditPacks: parseList(j['creditPacks'], CreditPackDto.fromJson),
    giftAmounts: (j['giftAmounts'] as List).cast<int>(),
  );

  Json toJson() => {
    'tapes': tapes.map((e) => e.toJson()).toList(),
    'drawer': drawer.map((e) => e.toJson()).toList(),
    'creditPacks': creditPacks.map((e) => e.toJson()).toList(),
    'giftAmounts': giftAmounts,
  };
}

class TapeProductDto {
  const TapeProductDto({
    required this.id,
    required this.tapeType,
    required this.qty,
    required this.name,
    required this.price,
  });

  final String id;
  final int tapeType;
  final int qty;
  final String name;
  final int price;

  factory TapeProductDto.fromJson(Json j) => TapeProductDto(
    id: j['id'] as String,
    tapeType: j['tapeType'] as int,
    qty: j['qty'] as int,
    name: j['name'] as String,
    price: j['price'] as int,
  );

  Json toJson() => {
    'id': id,
    'tapeType': tapeType,
    'qty': qty,
    'name': name,
    'price': price,
  };
}

class DrawerProductDto {
  const DrawerProductDto({
    required this.id,
    required this.name,
    required this.slots,
    required this.price,
  });

  final String id;
  final String name;
  final int slots;
  final int price;

  factory DrawerProductDto.fromJson(Json j) => DrawerProductDto(
    id: j['id'] as String,
    name: j['name'] as String,
    slots: j['slots'] as int,
    price: j['price'] as int,
  );

  Json toJson() => {'id': id, 'name': name, 'slots': slots, 'price': price};
}

class CreditPackDto {
  const CreditPackDto({
    required this.productId,
    required this.credits,
    this.priceKrw,
    required this.priceLabel,
  });

  /// App Store / Play Console 상품 ID와 같다
  final String productId;
  final int credits;
  final int? priceKrw;
  final String priceLabel;

  factory CreditPackDto.fromJson(Json j) => CreditPackDto(
    productId: j['productId'] as String,
    credits: j['credits'] as int,
    priceKrw: j['priceKrw'] as int?,
    priceLabel: j['priceLabel'] as String,
  );

  Json toJson() => {
    'productId': productId,
    'credits': credits,
    'priceKrw': ?priceKrw,
    'priceLabel': priceLabel,
  };
}

/// `POST /shop/purchases` 응답
class PurchaseResultDto {
  const PurchaseResultDto({
    required this.credits,
    required this.tapes,
    required this.drawer,
    required this.entry,
  });

  final int credits;
  final List<TapeStockDto> tapes;
  final DrawerDto drawer;
  final LedgerEntryDto entry;

  factory PurchaseResultDto.fromJson(Json j) => PurchaseResultDto(
    credits: j['credits'] as int,
    tapes: parseList(j['tapes'], TapeStockDto.fromJson),
    drawer: DrawerDto.fromJson(j['drawer'] as Json),
    entry: LedgerEntryDto.fromJson(j['entry'] as Json),
  );

  Json toJson() => {
    'credits': credits,
    'tapes': tapes.map((e) => e.toJson()).toList(),
    'drawer': drawer.toJson(),
    'entry': entry.toJson(),
  };
}

/// `POST /billing/iap` 요청
class IapRequest {
  const IapRequest({
    required this.store,
    required this.productId,
    this.transactionId,
    required this.verificationData,
  });

  /// `app_store` · `google_play`
  final String store;
  final String productId;

  /// 선택 — 참고용. 서버는 스토어에서 확인한 거래 id를 쓴다.
  final String? transactionId;

  /// iOS: StoreKit 2 `jwsRepresentation` · Android: `purchaseToken`
  final String verificationData;

  Json toJson() => {
    'store': store,
    'productId': productId,
    'transactionId': ?transactionId,
    'verificationData': verificationData,
  };
}

/// `POST /billing/iap` 응답
class IapResultDto {
  const IapResultDto({
    required this.credits,
    required this.granted,
    this.alreadyProcessed = false,
    this.entry,
  });

  final int credits;
  final int granted;

  /// 같은 결제를 다시 보냈다 (지급 없음, `granted: 0`)
  final bool alreadyProcessed;
  final LedgerEntryDto? entry;

  factory IapResultDto.fromJson(Json j) => IapResultDto(
    credits: j['credits'] as int,
    granted: j['granted'] as int,
    alreadyProcessed: (j['alreadyProcessed'] as bool?) ?? false,
    entry: j['entry'] == null
        ? null
        : LedgerEntryDto.fromJson(j['entry'] as Json),
  );

  Json toJson() => {
    'credits': credits,
    'granted': granted,
    'alreadyProcessed': alreadyProcessed,
    'entry': entry?.toJson(),
  };
}

/// `POST /wallet/gifts` 응답 `{ credits, entry }`
class GiftResultDto {
  const GiftResultDto({required this.credits, required this.entry});

  final int credits;
  final LedgerEntryDto entry;

  factory GiftResultDto.fromJson(Json j) => GiftResultDto(
    credits: j['credits'] as int,
    entry: LedgerEntryDto.fromJson(j['entry'] as Json),
  );

  Json toJson() => {'credits': credits, 'entry': entry.toJson()};
}

/// `POST /dev/credits` 요청 (개발 전용) — `ad` · `charge` · `admin`
class DevCreditsRequest {
  const DevCreditsRequest.ad() : type = 'ad', productId = null, amount = null;

  const DevCreditsRequest.charge(String this.productId)
    : type = 'charge',
      amount = null;

  const DevCreditsRequest.admin(int this.amount)
    : type = 'admin',
      productId = null;

  final String type;
  final String? productId;
  final int? amount;

  Json toJson() => {'type': type, 'productId': ?productId, 'amount': ?amount};
}
