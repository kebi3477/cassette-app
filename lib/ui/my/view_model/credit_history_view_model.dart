import 'package:flutter/foundation.dart';

import '../../../data/repositories/wallet_repository.dart';
import '../../../domain/models/wallet.dart';
import '../../../utils/format.dart';
import '../../../utils/result.dart';

/// 크레딧 내역 (`histOn`) — `GET /wallet/ledger` 커서 페이지.
class CreditHistoryViewModel extends ChangeNotifier {
  CreditHistoryViewModel({required WalletRepository walletRepository})
    : _wallet = walletRepository;

  final WalletRepository _wallet;

  int _credits = 0;
  final List<LedgerEntry> _entries = [];
  String? _cursor;
  bool _hasMore = true;
  bool _loading = false;

  int get credits => _credits;
  List<LedgerEntry> get entries => List.unmodifiable(_entries);
  bool get hasMore => _hasMore;
  bool get loading => _loading;

  /// `+10` / `−30` (마이너스 기호는 U+2212)
  static String amountText(LedgerEntry e) =>
      e.amount > 0 ? '+${e.amount}' : '−${-e.amount}';

  static String dateText(LedgerEntry e) => formatMonthDay(e.date);

  Future<void> load() async {
    _entries.clear();
    _cursor = null;
    _hasMore = true;
    final w = await _wallet.getWallet();
    if (w is Ok<Wallet>) _credits = w.value.credits;
    await loadMore();
  }

  /// 다음 페이지
  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    notifyListeners();
    final r = await _wallet.getLedger(cursor: _cursor);
    _loading = false;
    if (r is Ok<LedgerPage>) {
      _entries.addAll(r.value.items);
      _cursor = r.value.nextCursor;
      _hasMore = _cursor != null;
    }
    notifyListeners();
  }
}
