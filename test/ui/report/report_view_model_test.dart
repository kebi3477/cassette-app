import 'package:tapeletter_app/data/services/local/local_behavior.dart';
import 'package:tapeletter_app/domain/models/report.dart';
import 'package:tapeletter_app/ui/report/view_model/report_view_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/record_harness.dart';

void main() {
  late RecordHarness h;

  ReportViewModel make(
    FakeAsync async,
    ReportTarget target, {
    FailMode mode = FailMode.none,
    bool alreadyBlocked = false,
  }) {
    h = RecordHarness(behavior: LocalBehavior.instant.copyWith(failMode: mode));
    final vm = ReportViewModel(
      target: target,
      reports: h.reports,
      friends: h.friends,
      toast: h.toast,
      alreadyBlocked: alreadyBlocked,
    );
    async.flushMicrotasks();
    return vm;
  }

  TapeReport tape(RecordHarness? _) => const TapeReport(
    deliveryId: '',
    name: '지현',
    userId: 'u-jihyun',
    date: '09.24',
  );

  test('사유 6개는 디자인 순서, 서버 코드', () {
    expect(ReportReason.values.map((r) => r.label), [
      '괴롭힘·혐오 표현',
      '성적인 내용',
      '스팸·광고',
      '불법·권리 침해',
      '사칭',
      '기타',
    ]);
    expect(ReportReason.values.map((r) => r.code), [
      'harassment',
      'sexual',
      'spam',
      'illegal',
      'impersonation',
      'other',
    ]);
  });

  test('테이프 신고: 사유 전에는 못 누른다 → 보내는 중… → 신고하고 차단', () {
    fakeAsync((async) {
      h = RecordHarness();
      final id = h.store.unsorted.first.id; // 지현 3분
      final vm = make(
        async,
        TapeReport(
          deliveryId: id,
          name: '지현',
          userId: 'u-jihyun',
          date: '09.24',
        ),
      );
      final item = h.store.unsorted.first;
      expect(vm.subtitle, '지현님이 보낸 09.24 테이프');
      expect(vm.canBlock, isTrue);
      expect(vm.block, isTrue, reason: '기본 켜짐');
      expect(vm.blockLabel, '지현님 차단하기');
      expect(vm.canSubmit, isFalse);
      vm.submit();
      async.flushMicrotasks();
      expect(h.api.reports, isEmpty);

      vm.selectReason(ReportReason.spam);
      vm.setMemo('모르는 쇼핑몰 광고가 녹음돼 있어요');
      expect(vm.canSubmit, isTrue);
      vm.submit();
      expect(vm.cta, '보내는 중…');
      expect(vm.canSubmit, isFalse);
      async.flushMicrotasks();
      expect(vm.done, isTrue);
      expect(h.toast.message, '신고하고 차단했어요');
      final r = h.api.reports.single;
      expect(r.toJson(), {
        'target': {'type': 'tape', 'deliveryId': item.id},
        'reason': 'spam',
        'memo': '모르는 쇼핑몰 광고가 녹음돼 있어요',
        'alsoBlock': true,
      });
      expect(h.store.blocked.map((b) => b.userId), contains('u-jihyun'));
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('사람 신고, 차단 끄면 "신고가 접수됐어요"', () {
    fakeAsync((async) {
      final vm = make(async, const PersonReport(userId: 'u-minsu', name: '민수'));
      expect(vm.subtitle, '민수님');
      vm.toggleBlock();
      vm.selectReason(ReportReason.harassment);
      vm.submit();
      async.flushMicrotasks();
      expect(h.toast.message, '신고가 접수됐어요. 확인 후 조치할게요');
      expect(h.api.reports.single.toJson(), {
        'target': {'type': 'user', 'userId': 'u-minsu'},
        'reason': 'harassment',
        'alsoBlock': false,
      });
      expect(h.store.blocked, isEmpty);
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('이미 차단한 사람: 차단 체크를 숨기고 alsoBlock false', () {
    fakeAsync((async) {
      final vm = make(
        async,
        const PersonReport(userId: 'u-minsu', name: '민수'),
        alreadyBlocked: true,
      );
      expect(vm.canBlock, isFalse);
      vm.selectReason(ReportReason.other);
      vm.submit();
      async.flushMicrotasks();
      expect(h.api.reports.single.alsoBlock, isFalse);
      expect(h.toast.message, '신고가 접수됐어요. 확인 후 조치할게요');
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('차단 목록에 있는 사람이면 열 때 알아서 숨긴다', () {
    fakeAsync((async) {
      h = RecordHarness();
      final vm = make(async, const PersonReport(userId: 'u-minsu', name: '민수'));
      h.api.blockUser('u-minsu');
      async.flushMicrotasks();
      final again = ReportViewModelTestHook.fresh(h, 'u-minsu');
      async.flushMicrotasks();
      expect(again.canBlock, isFalse);
      expect(vm.canBlock, isTrue);
    });
  });

  test('하루 한도 (429) → "오늘은 더 신고할 수 없어요"', () {
    fakeAsync((async) {
      final vm = make(
        async,
        const PersonReport(userId: 'u-minsu', name: '민수'),
        mode: FailMode.reportLimit,
      );
      vm.selectReason(ReportReason.spam);
      vm.submit();
      async.flushMicrotasks();
      expect(vm.done, isTrue);
      expect(h.toast.message, '오늘은 더 신고할 수 없어요');
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('대상 없음 (404) → 테이프·사람 문구', () {
    fakeAsync((async) {
      var vm = make(async, tape(null), mode: FailMode.reportGone);
      vm.selectReason(ReportReason.spam);
      vm.submit();
      async.flushMicrotasks();
      expect(h.toast.message, '이미 사라진 테이프예요');
      async.elapse(const Duration(seconds: 3));

      vm = make(
        async,
        const PersonReport(userId: 'u-minsu', name: '민수'),
        mode: FailMode.reportGone,
      );
      vm.selectReason(ReportReason.spam);
      vm.submit();
      async.flushMicrotasks();
      expect(h.toast.message, '이미 탈퇴한 사람이에요');
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('네트워크 실패 → 실패 화면, 돌아가기는 적은 내용 유지', () {
    fakeAsync((async) {
      final vm = make(
        async,
        const PersonReport(userId: 'u-minsu', name: '민수'),
        mode: FailMode.offline,
      );
      vm.selectReason(ReportReason.sexual);
      vm.setMemo('메모');
      vm.submit();
      async.flushMicrotasks();
      expect(vm.failed, isTrue);
      expect(vm.done, isFalse);
      vm.back();
      expect(vm.failed, isFalse);
      expect(vm.reason, ReportReason.sexual);
      expect(vm.memo, '메모');
    });
  });

  test('자세히 적기는 300자까지', () {
    fakeAsync((async) {
      final vm = make(async, const PersonReport(userId: 'u-minsu', name: '민수'));
      vm.setMemo('가' * 320);
      expect(vm.memoLength, 300);
    });
  });
}

/// 새 시트를 연 것처럼 ViewModel을 하나 더 만든다
abstract final class ReportViewModelTestHook {
  static ReportViewModel fresh(RecordHarness h, String userId) =>
      ReportViewModel(
        target: PersonReport(userId: userId, name: '민수'),
        reports: h.reports,
        friends: h.friends,
        toast: h.toast,
      );
}
