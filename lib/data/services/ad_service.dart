import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// 보상형 광고 결과. 보상은 AdMob SSV로 서버가 준다 — 앱은 `GET /wallet`을 다시 읽는다.
enum AdOutcome { rewarded, closedEarly, failed }

/// 보상형 광고. 실제 구현은 [AdMobAdService].
abstract class AdService {
  /// 광고 SDK 대신 디자인의 광고 시트(3·2·1 카운트)로 흉내 내는지.
  bool get simulated;

  /// 광고를 불러온다. SSV 콜백이 [userId]에게 보상하도록 설정한다. 실패하면 false (`shAdFail`).
  Future<bool> load({required String userId});

  /// 불러온 광고를 띄운다 (SDK 광고일 때).
  Future<AdOutcome> show();

  /// [simulated]일 때 광고 시트 카운트가 끝나면 부른다 — 서버의 SSV 보상을 흉내 낸다.
  Future<void> simulateReward();
}

/// google_mobile_ads 보상형 광고. `--dart-define=ADMOB_REWARDED_ID=`가 있을 때만 쓴다.
class AdMobAdService implements AdService {
  AdMobAdService(this.adUnitId);

  final String adUnitId;
  RewardedAd? _ad;

  /// 테스트 기기로 등록한 기기에는 실제 광고 단위에서도 테스트 광고가 나온다.
  /// 자기 광고를 직접 보면 무효 트래픽이 되므로 개발자 기기는 꼭 넣는다 (Env.admobTestDeviceIds).
  static Future<void> initialize({
    List<String> testDeviceIds = const [],
  }) async {
    if (testDeviceIds.isNotEmpty) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: testDeviceIds),
      );
    }
    await MobileAds.instance.initialize();
  }

  @override
  bool get simulated => false;

  @override
  Future<bool> load({required String userId}) async {
    final done = Completer<bool>();
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) async {
          await ad.setServerSideOptions(
            ServerSideVerificationOptions(userId: userId),
          );
          _ad = ad;
          done.complete(true);
        },
        onAdFailedToLoad: (_) => done.complete(false),
      ),
    );
    return done.future;
  }

  @override
  Future<AdOutcome> show() async {
    final ad = _ad;
    if (ad == null) return AdOutcome.failed;
    _ad = null;
    final done = Completer<AdOutcome>();
    var rewarded = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) {
          done.complete(rewarded ? AdOutcome.rewarded : AdOutcome.closedEarly);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!done.isCompleted) done.complete(AdOutcome.failed);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => rewarded = true);
    return done.future;
  }

  @override
  Future<void> simulateReward() async {}
}
