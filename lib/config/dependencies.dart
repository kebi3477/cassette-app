import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth_repository.dart';
import '../data/repositories/auth_repository_local.dart';
import '../data/repositories/delivery_repository.dart';
import '../data/repositories/delivery_repository_remote.dart';
import '../data/repositories/friend_repository.dart';
import '../data/repositories/friend_repository_remote.dart';
import '../data/repositories/recording_repository.dart';
import '../data/repositories/recording_repository_remote.dart';
import '../data/repositories/shelf_repository.dart';
import '../data/repositories/shelf_repository_remote.dart';
import '../data/repositories/shop_repository.dart';
import '../data/repositories/shop_repository_remote.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/user_repository_remote.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/repositories/wallet_repository_remote.dart';
import '../data/services/api/api_client.dart';
import '../data/services/ad_service.dart';
import '../data/services/app_info_service.dart';
import '../data/services/app_settings_service.dart';
import '../data/services/audio_player_service.dart';
import '../data/services/iap_service.dart';
import '../data/services/link_service.dart';
import '../data/services/local/local_api_client.dart';
import '../data/services/local/local_ad_service.dart';
import '../data/services/local/local_behavior.dart';
import '../data/services/local/local_iap_service.dart';
import '../data/services/local/local_store.dart';
import '../data/services/local/local_upload_service.dart';
import '../data/services/recorder_service.dart';
import '../data/services/share_service.dart';
import '../data/services/upload_service.dart';
import '../ui/core/ui/toast.dart';
import '../ui/my/view_model/my_view_model.dart';
import '../ui/record/view_model/record_view_model.dart';
import '../ui/shelf/view_model/shelf_view_model.dart';
import '../ui/shop/view_model/shop_view_model.dart';
import 'env.dart';
import '../ui/shell/view_model/shell_view_model.dart';

/// 서버 없이 도는 구성. [LocalApiClient]가 계약서 모양 그대로 응답하고,
/// 데이터는 프로토타입 초기 state([LocalStore])다. 녹음·재생·공유는 실제 기기 기능을 쓴다.
///
/// 다음 단계에서 [ApiClient]·[UploadService]만 HTTP 구현으로 바꾸면 된다.
///
/// 실패 흉내: `flutter run --dart-define=FAIL_MODE=convertSlow`
/// (`convertSlow` · `convertFail` · `sendFail` · `loadFail` · `payFail` · `adFail` · `offline`)
List<SingleChildWidget> providersLocal({
  LocalStore? store,
  LocalBehavior? behavior,
}) {
  final s = store ?? LocalStore();
  final b = behavior ?? LocalBehavior.fromEnvironment();
  final api = LocalApiClient(s, b);
  return [
    Provider<ApiClient>.value(value: api),
    Provider<UploadService>.value(value: LocalUploadService(s)),
    Provider<AuthRepository>.value(value: AuthRepositoryLocal()),
    ...repositories,
    ...deviceServices,
    ...storeServices(api, b),
  ];
}

/// 결제·광고. 키가 없으면 가짜로 돈다.
///
/// - 광고: `--dart-define=ADMOB_REWARDED_ID=<광고 단위 ID>`가 있으면 AdMob 보상형 광고
/// - 결제: `--dart-define=IAP_ENABLED=true`면 App Store / Google Play 결제
List<SingleChildWidget> storeServices(LocalApiClient api, LocalBehavior b) => [
  Provider<IapService>(
    create: (_) => Env.iapEnabled ? StoreIapService() : LocalIapService(b),
  ),
  Provider<AdService>(
    create: (_) => Env.admobRewardedId.isNotEmpty
        ? AdMobAdService(Env.admobRewardedId)
        : LocalAdService(api, b),
  ),
];

/// [ApiClient] 위의 repository. 구현은 HTTP로 바꿔도 그대로 쓴다.
List<SingleChildWidget> get repositories => [
  ChangeNotifierProvider<UserRepository>(
    create: (c) => UserRepositoryRemote(c.read()),
  ),
  ChangeNotifierProvider<FriendRepository>(
    create: (c) => FriendRepositoryRemote(c.read()),
  ),
  ChangeNotifierProvider<WalletRepository>(
    create: (c) => WalletRepositoryRemote(c.read()),
  ),
  ChangeNotifierProvider<ShelfRepository>(
    create: (c) => ShelfRepositoryRemote(c.read()),
  ),
  Provider<RecordingRepository>(
    create: (c) => RecordingRepositoryRemote(c.read(), c.read()),
  ),
  Provider<DeliveryRepository>(
    create: (c) => DeliveryRepositoryRemote(c.read()),
  ),
  Provider<ShopRepository>(create: (c) => ShopRepositoryRemote(c.read())),
];

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
  Provider<LinkService>(create: (_) => UrlLauncherLinkService()),
  Provider<AppInfoService>(create: (_) => PackageAppInfoService()),
];

/// 화면 전체에서 함께 쓰는 ViewModel. repository·service 뒤에 둔다.
List<SingleChildWidget> get appViewModels => [
  ChangeNotifierProvider(create: (_) => ToastController()),
  ChangeNotifierProvider(
    create: (c) =>
        ShellViewModel(userRepository: c.read(), shelfRepository: c.read())
          ..load(),
  ),
  ChangeNotifierProvider(
    create: (c) =>
        ShelfViewModel(shelfRepository: c.read(), toast: c.read())..load(),
  ),
  ChangeNotifierProvider(
    create: (c) => ShopViewModel(
      shopRepository: c.read(),
      walletRepository: c.read(),
      userRepository: c.read(),
      friendRepository: c.read(),
      shelfRepository: c.read(),
      iap: c.read(),
      ads: c.read(),
      toast: c.read(),
    )..load(),
  ),
  ChangeNotifierProvider(
    create: (c) => MyViewModel(
      userRepository: c.read(),
      friendRepository: c.read(),
      walletRepository: c.read(),
      deliveryRepository: c.read(),
      authRepository: c.read(),
      share: c.read(),
      links: c.read(),
      appInfo: c.read(),
      toast: c.read(),
    )..load(),
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
