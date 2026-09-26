import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tapeletter_app/data/repositories/friend_repository_remote.dart';
import 'package:tapeletter_app/data/repositories/shelf_repository_remote.dart';
import 'package:tapeletter_app/data/services/local/local_api_client.dart';
import 'package:tapeletter_app/data/services/local/local_behavior.dart';
import 'package:tapeletter_app/data/services/local/local_store.dart';
import 'package:tapeletter_app/data/services/sound_service.dart';
import 'package:tapeletter_app/ui/core/ui/toast.dart';
import 'package:tapeletter_app/ui/player/view_model/player_view_model.dart';
import 'package:tapeletter_app/ui/record/view_model/record_view_model.dart';

import '../../../../testing/fakes/services/fake_audio_player_service.dart';
import '../../../../testing/fakes/services/fake_sound_service.dart';
import '../../../../testing/record_harness.dart';

void main() {
  test('효과음 길이는 파일 길이(on 0.539s, off 0.429s)를 덮는다', () {
    expect(UiSound.on.duration, const Duration(milliseconds: 540));
    expect(UiSound.off.duration, const Duration(milliseconds: 430));
  });

  test('REC: on.wav가 끝난 뒤에 녹음기를 켠다 (on.wav가 녹음에 안 들어간다)', () {
    fakeAsync((async) {
      final h = RecordHarness();
      h.sound.realDuration = true;
      h.vm.load();
      async.flushMicrotasks();
      h.recorder.calls.clear();

      h.vm.startRec();
      async.flushMicrotasks();
      expect(h.vm.arming, isTrue);
      expect(h.vm.phase, RecordPhase.idle);
      expect(h.recorder.calls, ['sound:on']);

      async.elapse(const Duration(milliseconds: 539));
      expect(h.recorder.calls, isNot(contains('start')));
      async.elapse(const Duration(milliseconds: 1));
      expect(h.vm.arming, isFalse);
      expect(h.vm.phase, RecordPhase.rec);
      expect(h.recorder.calls, ['sound:on', 'sound:on:end', 'start']);

      // 녹음 시간은 실제 녹음이 시작된 때부터 센다
      expect(h.vm.sec, 0);
      async.elapse(const Duration(seconds: 2));
      expect(h.vm.sec, 2);

      // STOP: 녹음기를 먼저 멈추고 나서 off.wav
      h.vm.stopRec();
      async.flushMicrotasks();
      expect(h.recorder.calls.sublist(3), ['stop', 'sound:off']);
      async.elapse(const Duration(seconds: 3));
    });
  });

  test('비활성(잠긴 테이프)·권한 거부면 on.wav도 울리지 않는다', () {
    fakeAsync((async) {
      final h = RecordHarness()..recorder.granted = false;
      h.recorder.grantOnRequest = false;
      h.vm.load();
      async.flushMicrotasks();
      h.vm.startRec();
      async.flushMicrotasks();
      expect(h.sound.played, isEmpty);
      expect(h.vm.arming, isFalse);
    });
  });

  test('확인 화면 데크: PLAY는 on.wav + 재생, STOP은 멈춤 + off.wav, 멈춘 상태의 STOP은 조용', () {
    fakeAsync((async) {
      final h = RecordHarness();
      h.vm.load();
      async.flushMicrotasks();
      h.vm.startRec();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 3));
      h.vm.stopRec();
      async.flushMicrotasks();
      // 변환 뒤 자동 미리 듣기에는 소리가 없다
      async.elapse(const Duration(seconds: 2));
      expect(h.vm.playing, isTrue);
      expect(h.sound.played, [UiSound.on, UiSound.off]);

      h.vm.pressStop();
      async.flushMicrotasks();
      expect(h.vm.playing, isFalse);
      expect(h.sound.played.last, UiSound.off);
      h.vm.pressStop();
      async.flushMicrotasks();
      expect(h.sound.played, hasLength(3));

      h.vm.pressPlay();
      async.flushMicrotasks();
      expect(h.vm.playing, isTrue);
      expect(h.sound.played.last, UiSound.on);
      h.vm.pressPlay();
      async.flushMicrotasks();
      expect(h.vm.playing, isFalse);
      expect(h.sound.played.last, UiSound.off);
    });
  });

  test('재생 화면: 재생 버튼은 on/off, 자동 재생은 조용', () {
    fakeAsync((async) {
      final store = LocalStore(clock: () => DateTime.utc(2026, 9, 25, 3));
      final api = LocalApiClient(store, LocalBehavior.instant);
      final sound = FakeSoundService();
      final vm = PlayerViewModel(
        shelfRepository: ShelfRepositoryRemote(api),
        friendRepository: FriendRepositoryRemote(api),
        player: FakeAudioPlayerService(duration: null),
        toast: ToastController(),
        sound: sound,
      );
      vm.open(const GroupSource('g-1'), store.groups[0].items[0].id);
      async.flushMicrotasks();
      async.elapse(PlayerViewModel.openLoad);
      expect(vm.playing, isTrue);
      expect(sound.played, isEmpty);
      vm.pressPlay();
      async.flushMicrotasks();
      expect(vm.playing, isFalse);
      expect(sound.played, [UiSound.off]);
      vm.pressPlay();
      async.flushMicrotasks();
      expect(vm.playing, isTrue);
      expect(sound.played, [UiSound.off, UiSound.on]);
    });
  });
}
