import '../../domain/models/tape_type.dart';
import '../../domain/models/wallet.dart';
import '../../utils/result.dart';
import '../services/local/local_store.dart';
import 'wallet_repository.dart';

class WalletRepositoryLocal extends WalletRepository {
  WalletRepositoryLocal(this._store);

  final LocalStore _store;

  @override
  Future<Result<Wallet>> getWallet() async => Result.ok(_store.wallet);

  @override
  Future<Result<List<LedgerEntry>>> getLedger() async =>
      Result.ok(List.unmodifiable(_store.ledger));

  /// 보낼 때 3분·5분 테이프 1개를 쓴다. 모자라면 false.
  bool consume(TapeType type) {
    if (type.isUnlimited) return true;
    final n = _store.owned[type] ?? 0;
    if (n <= 0) return false;
    _store.owned = {..._store.owned, type: n - 1};
    notifyListeners();
    return true;
  }
}
