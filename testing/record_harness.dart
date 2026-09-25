import 'package:cassette_app/data/repositories/auth_repository_local.dart';
import 'package:cassette_app/data/repositories/friend_repository_remote.dart';
import 'package:cassette_app/data/repositories/shop_repository_remote.dart';
import 'package:cassette_app/data/repositories/shelf_repository_remote.dart';
import 'package:cassette_app/data/repositories/user_repository_remote.dart';
import 'package:cassette_app/data/repositories/wallet_repository_remote.dart';
import 'package:cassette_app/data/services/local/local_ad_service.dart';
import 'package:cassette_app/data/services/local/local_api_client.dart';
import 'package:cassette_app/data/services/local/local_behavior.dart';
import 'package:cassette_app/data/services/local/local_store.dart';
import 'package:cassette_app/ui/core/ui/toast.dart';
import 'package:cassette_app/ui/my/view_model/my_view_model.dart';
import 'package:cassette_app/ui/record/view_model/record_view_model.dart';
import 'package:cassette_app/ui/shop/view_model/shop_view_model.dart';

import 'fakes/repositories/fake_delivery_repository.dart';
import 'fakes/repositories/fake_recording_repository.dart';
import 'fakes/services/fake_app_settings_service.dart';
import 'fakes/services/fake_audio_player_service.dart';
import 'fakes/services/fake_iap_service.dart';
import 'fakes/services/fake_link_service.dart';
import 'fakes/services/fake_recorder_service.dart';
import 'fakes/services/fake_share_service.dart';

/// 프로토타입 초기 데이터(친구 6명, 보유 {3:2, 5:0} 등)를 계약서 모양으로 돌려주는
/// 지연 없는 [LocalApiClient] + 가짜 기기 기능으로 앱 조각을 만든다.
class RecordHarness {
  RecordHarness({
    FakeRecorderService? recorder,
    FakeRecordingRepository? recordings,
    FakeDeliveryRepository? deliveries,
    LocalBehavior behavior = LocalBehavior.instant,
  }) : recorder = recorder ?? FakeRecorderService(),
       recordings = recordings ?? FakeRecordingRepository() {
    api = LocalApiClient(store, behavior);
    users = UserRepositoryRemote(api);
    friends = FriendRepositoryRemote(api);
    wallet = WalletRepositoryRemote(api);
    shelf = ShelfRepositoryRemote(api);
    this.deliveries = deliveries ?? FakeDeliveryRepository(store: store);
    shop = ShopRepositoryRemote(api);
    ads = LocalAdService(api, behavior);
    shopVm = ShopViewModel(
      shopRepository: shop,
      walletRepository: wallet,
      userRepository: users,
      friendRepository: friends,
      shelfRepository: shelf,
      iap: iap,
      ads: ads,
      toast: toast,
    );
    myVm = MyViewModel(
      userRepository: users,
      friendRepository: friends,
      walletRepository: wallet,
      deliveryRepository: this.deliveries,
      authRepository: auth,
      share: share,
      links: links,
      appInfo: FakeAppInfoService(),
      toast: toast,
    );
    vm = RecordViewModel(
      userRepository: users,
      friendRepository: friends,
      walletRepository: wallet,
      recordingRepository: this.recordings,
      deliveryRepository: this.deliveries,
      recorder: this.recorder,
      player: player,
      share: share,
      settings: settings,
      toast: toast,
    );
  }

  final LocalStore store = LocalStore(
    clock: () => DateTime.utc(2026, 9, 25, 3),
  );
  late final LocalApiClient api;
  late final UserRepositoryRemote users;
  late final FriendRepositoryRemote friends;
  late final WalletRepositoryRemote wallet;
  late final ShelfRepositoryRemote shelf;
  final FakeRecorderService recorder;
  final FakeRecordingRepository recordings;
  late final FakeDeliveryRepository deliveries;
  final FakeAudioPlayerService player = FakeAudioPlayerService();
  final FakeShareService share = FakeShareService();
  final FakeAppSettingsService settings = FakeAppSettingsService();
  final ToastController toast = ToastController();
  late final RecordViewModel vm;
  late final ShopRepositoryRemote shop;
  late final LocalAdService ads;
  final FakeIapService iap = FakeIapService();
  final FakeLinkService links = FakeLinkService();
  final AuthRepositoryLocal auth = AuthRepositoryLocal();
  late final ShopViewModel shopVm;
  late final MyViewModel myVm;
}
