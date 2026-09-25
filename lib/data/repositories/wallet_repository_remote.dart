import '../../domain/models/wallet.dart';
import '../../utils/result.dart';
import '../model/mappers.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';
import 'wallet_repository.dart';

class WalletRepositoryRemote extends WalletRepository {
  WalletRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<Result<Wallet>> getWallet() => guard(() async {
    final me = await _api.getMe();
    final wallet = await _api.getWallet();
    return me.toWallet(wallet);
  });

  @override
  Future<Result<LedgerPage>> getLedger({String? cursor}) => guard(() async {
    final page = await _api.getLedger(cursor: cursor);
    return LedgerPage(
      items: page.items.map((e) => e.toDomain()).toList(),
      nextCursor: page.nextCursor,
    );
  });

  @override
  Future<Result<int>> gift({
    required String toUserId,
    required int amount,
    required String idempotencyKey,
  }) async {
    final r = await guard(
      () async => (await _api.sendGift(
        toUserId: toUserId,
        amount: amount,
        idempotencyKey: idempotencyKey,
      )).credits,
    );
    if (r is Ok) notifyListeners();
    return r;
  }
}
