import 'package:flutter/foundation.dart';

import '../../domain/models/wallet.dart';
import '../../utils/result.dart';

/// 크레딧·보유 테이프. 잔액이 바뀌면 리스너에게 알린다.
abstract class WalletRepository extends ChangeNotifier {
  Future<Result<Wallet>> getWallet();

  Future<Result<List<LedgerEntry>>> getLedger();
}
