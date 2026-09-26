/// 여러 화면에서 같은 문구를 쓰는 안내 (디자인 README "결제·환불 안내 문구").
abstract final class NoticeCopy {
  /// `shBuy` 버튼 아래
  static const noRefundPurchase = '구매한 테이프와 서랍은 바로 제공돼서 구매를 취소할 수 없어요';

  /// 상점 결제 팩 아래 · `shCharge`
  static const refundWithin7Days =
      '쓰지 않은 유료 크레딧은 결제 후 7일 안에 App Store·Google Play에서 환불을 신청할 수 있어요';

  /// `shWithdraw` 요약 상자 아래
  static const refundBeforeWithdraw =
      '결제 후 7일이 지나지 않은 쓰지 않은 유료 크레딧은 탈퇴 전에 App Store·Google Play에서 환불을 신청해 주세요';
}
