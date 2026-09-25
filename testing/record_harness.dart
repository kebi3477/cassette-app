import 'package:cassette_app/data/repositories/friend_repository_local.dart';
import 'package:cassette_app/data/repositories/shelf_repository_local.dart';
import 'package:cassette_app/data/repositories/user_repository_local.dart';
import 'package:cassette_app/data/repositories/wallet_repository_local.dart';
import 'package:cassette_app/data/services/local/local_store.dart';
import 'package:cassette_app/ui/core/ui/toast.dart';
import 'package:cassette_app/ui/record/view_model/record_view_model.dart';

import 'fakes/repositories/fake_delivery_repository.dart';
import 'fakes/repositories/fake_recording_repository.dart';
import 'fakes/services/fake_app_settings_service.dart';
import 'fakes/services/fake_audio_player_service.dart';
import 'fakes/services/fake_recorder_service.dart';
import 'fakes/services/fake_share_service.dart';

/// 프로토타입 초기 데이터(친구 6명, 보유 {3:2, 5:0} 등) + 가짜 기기 기능으로
/// [RecordViewModel]을 만든다.
class RecordHarness {
  RecordHarness({
    FakeRecorderService? recorder,
    FakeRecordingRepository? recordings,
    FakeDeliveryRepository? deliveries,
  }) : recorder = recorder ?? FakeRecorderService(),
       recordings = recordings ?? FakeRecordingRepository() {
    friends = FriendRepositoryLocal(store);
    wallet = WalletRepositoryLocal(store);
    shelf = ShelfRepositoryLocal(store);
    this.deliveries = deliveries ?? FakeDeliveryRepository(wallet: wallet);
    vm = RecordViewModel(
      userRepository: UserRepositoryLocal(store),
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

  final LocalStore store = LocalStore(clock: () => DateTime(2026, 9, 25));
  late final FriendRepositoryLocal friends;
  late final WalletRepositoryLocal wallet;
  late final ShelfRepositoryLocal shelf;
  final FakeRecorderService recorder;
  final FakeRecordingRepository recordings;
  late final FakeDeliveryRepository deliveries;
  final FakeAudioPlayerService player = FakeAudioPlayerService();
  final FakeShareService share = FakeShareService();
  final FakeAppSettingsService settings = FakeAppSettingsService();
  final ToastController toast = ToastController();
  late final RecordViewModel vm;
}
