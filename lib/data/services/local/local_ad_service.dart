import '../ad_service.dart';
import '../../model/shop_dto.dart';
import '../api/api_client.dart';
import 'local_behavior.dart';

/// 광고 SDK 없이 디자인의 광고 시트(3·2·1)로 흉내 낸다.
/// 카운트가 끝나면 `POST /dev/credits {type: ad}`로 SSV 보상을 흉내 낸다. `FAIL_MODE=adFail`이면 불러오기 실패.
class LocalAdService implements AdService {
  LocalAdService(this._api, [this._behavior = const LocalBehavior()]);

  final ApiClient _api;
  final LocalBehavior _behavior;

  @override
  bool get simulated => true;

  @override
  Future<bool> load({required String userId}) async => !_behavior.failsAd;

  @override
  Future<AdOutcome> show() async => AdOutcome.failed;

  @override
  Future<void> simulateReward() async {
    await _api.devCredits(const DevCreditsRequest.ad());
  }
}
