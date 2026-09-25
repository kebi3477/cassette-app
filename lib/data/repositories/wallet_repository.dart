import 'package:flutter/foundation.dart';

import '../../domain/models/wallet.dart';
import '../../utils/result.dart';

/// 크레딧·보유 테이프. 잔액이 바뀌면 리스너에게 알린다.
abstract class WalletRepository extends ChangeNotifier {
  /// 크레딧과 보유 테이프(`GET /users/me`) + 오늘 남은 광고(`GET /wallet`)
  Future<Result<Wallet>> getWallet();

  /// 크레딧 내역 한 페이지 (`GET /wallet/ledger?cursor=`)
  Future<Result<LedgerPage>> getLedger({String? cursor});

  /// 크레딧 선물 (`POST /wallet/gifts`). 성공하면 새 잔액.
  Future<Result<int>> gift({
    required String toUserId,
    required int amount,
    required String idempotencyKey,
  });

  /// 보내기·구매 뒤 다시 불러오라고 알린다.
  void invalidate() => notifyListeners();
}
