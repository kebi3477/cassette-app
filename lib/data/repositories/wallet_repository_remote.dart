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
  Future<Result<List<LedgerEntry>>> getLedger() => guard(
    () async =>
        (await _api.getLedger()).items.map((e) => e.toDomain()).toList(),
  );
}
