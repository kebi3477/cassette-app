import 'package:tapeletter_app/data/services/local/local_behavior.dart';
import 'package:tapeletter_app/domain/models/share_link.dart';
import 'package:tapeletter_app/ui/link/view_model/link_view_model.dart';
import 'package:tapeletter_app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/record_harness.dart';

void main() {
  Future<(RecordHarness, List<LinkEvent>)> setup({
    FailMode mode = FailMode.none,
    bool signedIn = true,
  }) async {
    final h = RecordHarness(
      behavior: LocalBehavior.instant.copyWith(failMode: mode),
      signedIn: signedIn,
    );
    final events = <LinkEvent>[];
    h.linkVm.events.listen(events.add);
    await pumpEventQueue();
    return (h, events);
  }

  group('링크 주소', () {
    late RecordHarness h;
    setUp(() => h = RecordHarness());

    test('https://<PUBLIC_HOST>/t/{token}', () {
      final vm = h.linkVm;
      expect(
        vm.tokenOf(Uri.parse('https://tapeletter.example/t/abc123')),
        'abc123',
      );
      expect(
        vm.tokenOf(Uri.parse('https://tapeletter.example/t/abc123/')),
        'abc123',
      );
      expect(vm.tokenOf(Uri.parse('https://other.example/t/abc123')), isNull);
      expect(
        vm.tokenOf(Uri.parse('https://tapeletter.example/x/abc123')),
        isNull,
      );
      expect(vm.tokenOf(Uri.parse('https://tapeletter.example/t')), isNull);
    });

    test('카카오 로그인 복귀 주소(kakao{키}://oauth)는 건드리지 않는다', () async {
      final vm = h.linkVm;
      final kakao = Uri.parse('kakaob53a18d3://oauth?code=abc&state=x');
      expect(vm.tokenOf(kakao), isNull);
      await vm.accept(kakao);
      expect(await h.prefs.pendingLink(), isNull);
    });

    test('웹의 "앱에서 열기": tapeletter://t/{token}', () {
      final vm = h.linkVm;
      expect(vm.tokenOf(Uri.parse('tapeletter://t/abc123')), 'abc123');
      expect(vm.tokenOf(Uri.parse('tapeletter://t/')), isNull);
      expect(vm.tokenOf(Uri.parse('tapeletter://x/abc123')), isNull);
      expect(vm.tokenOf(Uri.parse('other://t/abc123')), isNull);
    });
  });

  test('열기: GET /share만 부르고 소포 화면으로 (받지는 않는다)', () async {
    final (h, events) = await setup();
    h.deepLinks.open(Uri.parse('https://tapeletter.example/t/tok1'));
    await pumpEventQueue();
    expect((events.single as OpenLinkParcel).token, 'tok1');
    expect(h.store.claimedLinks, isEmpty);
    expect(h.shareRepo.peek('tok1')?.senderName, '유진');
  });

  test('tapeletter:// 링크도 같은 처리', () async {
    final (h, events) = await setup();
    h.deepLinks.open(Uri.parse('tapeletter://t/tok2'));
    await pumpEventQueue();
    expect(events.single, isA<OpenLinkParcel>());
  });

  test('이미 내가 받은 링크를 다시 열면 서랍의 그 테이프로', () async {
    final (h, events) = await setup();
    final c = await h.shareRepo.claim('tok3');
    final id = (c as Ok<ClaimedTape>).value.item.id;
    h.deepLinks.open(Uri.parse('tapeletter://t/tok3'));
    await pumpEventQueue();
    final e = events.single as OpenClaimedParcel;
    expect(e.itemId, id);
    expect(e.friendMade, isFalse);
  });

  for (final (mode, kind) in [
    (FailMode.linkTaken, LinkErrorKind.taken),
    (FailMode.linkExpired, LinkErrorKind.expired),
    (FailMode.linkOwn, LinkErrorKind.own),
  ]) {
    test('오류: ${kind.name}', () async {
      final (h, events) = await setup(mode: mode);
      h.deepLinks.open(Uri.parse('https://tapeletter.example/t/tok'));
      await pumpEventQueue();
      final e = events.single as ShowLinkError;
      expect(e.kind, kind);
      if (kind == LinkErrorKind.own) expect(e.url, contains('/t/'));
    });
  }

  test('로그인 전에 연 링크는 저장했다가 로그인 뒤에 처리한다', () async {
    final (h, events) = await setup(signedIn: false);
    h.deepLinks.open(Uri.parse('tapeletter://t/later'));
    await pumpEventQueue();
    expect(events, isEmpty);
    expect(await h.prefs.pendingLink(), 'later');

    await h.auth.signInKakao();
    await pumpEventQueue();
    expect(events.single, isA<OpenLinkParcel>());
    expect(await h.prefs.pendingLink(), isNull);
  });

  test('앱이 링크로 처음 열렸을 때 (initialLink)', () async {
    final h = RecordHarness(signedIn: false);
    h.deepLinks.initial = Uri.parse('tapeletter://t/cold');
    final events = <LinkEvent>[];
    h.linkVm.events.listen(events.add);
    await pumpEventQueue();
    expect(await h.prefs.pendingLink(), 'cold');
    await h.auth.signInDev(key: 'k');
    await pumpEventQueue();
    expect(events.single, isA<OpenLinkParcel>());
  });
}
