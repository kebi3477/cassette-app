import 'package:cassette_app/data/repositories/friend_repository.dart';
import 'package:cassette_app/data/repositories/shelf_repository.dart';
import 'package:cassette_app/data/repositories/user_repository.dart';
import 'package:cassette_app/data/repositories/wallet_repository.dart';
import 'package:cassette_app/main.dart';
import 'package:cassette_app/ui/core/ui/toast.dart';
import 'package:cassette_app/ui/record/view_model/record_view_model.dart';
import 'package:cassette_app/ui/shell/view_model/shell_view_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'record_harness.dart';

/// 기준 화면 390×844 (@1x)
void useDesignScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// 가짜 repository·service로 앱 전체를 띄운다.
Widget testApp(RecordHarness h) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<UserRepository>.value(value: h.users),
      ChangeNotifierProvider<FriendRepository>.value(value: h.friends),
      ChangeNotifierProvider<WalletRepository>.value(value: h.wallet),
      ChangeNotifierProvider<ShelfRepository>.value(value: h.shelf),
      ChangeNotifierProvider<ToastController>.value(value: h.toast),
      ChangeNotifierProvider(
        create: (c) =>
            ShellViewModel(userRepository: h.users, shelfRepository: h.shelf)
              ..load(),
      ),
      ChangeNotifierProvider<RecordViewModel>.value(value: h.vm..load()),
    ],
    child: const CassetteApp(),
  );
}
