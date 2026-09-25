import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/delivery_repository.dart';
import '../data/repositories/delivery_repository_local.dart';
import '../data/repositories/friend_repository.dart';
import '../data/repositories/friend_repository_local.dart';
import '../data/repositories/recording_repository.dart';
import '../data/repositories/recording_repository_local.dart';
import '../data/repositories/shelf_repository.dart';
import '../data/repositories/shelf_repository_local.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/user_repository_local.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/repositories/wallet_repository_local.dart';
import '../data/services/app_settings_service.dart';
import '../data/services/audio_player_service.dart';
import '../data/services/local/local_behavior.dart';
import '../data/services/local/local_store.dart';
import '../data/services/recorder_service.dart';
import '../data/services/share_service.dart';
import '../ui/core/ui/toast.dart';
import '../ui/record/view_model/record_view_model.dart';
import '../ui/shell/view_model/shell_view_model.dart';

/// 서버 없이 도는 구성. 데이터는 프로토타입 초기 state([LocalStore])이고,
/// 녹음·재생·공유는 실제 기기 기능을 쓴다.
///
/// 실패 흉내: `flutter run --dart-define=FAIL_MODE=convertSlow`
/// (`convertSlow` · `convertFail` · `sendFail` · `offline`)
List<SingleChildWidget> providersLocal({
  LocalStore? store,
  LocalBehavior? behavior,
}) {
  final s = store ?? LocalStore();
  final b = behavior ?? LocalBehavior.fromEnvironment();
  final friends = FriendRepositoryLocal(s);
  final wallet = WalletRepositoryLocal(s);
  return [
    Provider<UserRepository>.value(value: UserRepositoryLocal(s)),
    ChangeNotifierProvider<FriendRepository>.value(value: friends),
    ChangeNotifierProvider<WalletRepository>.value(value: wallet),
    ChangeNotifierProvider<ShelfRepository>.value(
      value: ShelfRepositoryLocal(s),
    ),
    Provider<RecordingRepository>.value(value: RecordingRepositoryLocal(s, b)),
    Provider<DeliveryRepository>.value(
      value: DeliveryRepositoryLocal(s, b, friends, wallet),
    ),
    ...deviceServices,
  ];
}

/// 기기 기능 (녹음·재생·공유·설정)
List<SingleChildWidget> get deviceServices => [
  Provider<RecorderService>(
    create: (_) => RecordRecorderService(),
    dispose: (_, s) => s.dispose(),
  ),
  Provider<AudioPlayerService>(
    create: (_) => JustAudioPlayerService(),
    dispose: (_, s) => s.dispose(),
  ),
  Provider<ShareService>(create: (_) => SystemShareService()),
  Provider<AppSettingsService>(create: (_) => SystemAppSettingsService()),
];

/// 화면 전체에서 함께 쓰는 ViewModel. repository·service 뒤에 둔다.
List<SingleChildWidget> get appViewModels => [
  ChangeNotifierProvider(create: (_) => ToastController()),
  ChangeNotifierProvider(
    create: (c) => ShellViewModel(shelfRepository: c.read())..load(),
  ),
  ChangeNotifierProvider(
    create: (c) => RecordViewModel(
      userRepository: c.read(),
      friendRepository: c.read(),
      walletRepository: c.read(),
      recordingRepository: c.read(),
      deliveryRepository: c.read(),
      recorder: c.read(),
      player: c.read(),
      share: c.read(),
      settings: c.read(),
      toast: c.read(),
    )..load(),
  ),
];
