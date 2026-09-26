import 'package:tapeletter_app/data/repositories/auth_repository.dart';
import 'package:tapeletter_app/ui/auth/view_model/login_view_model.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/record_harness.dart';

void main() {
  test('로그인에 성공해 화면이 사라진 뒤에도 오류 없이 끝난다', () {
    fakeAsync((async) {
      final h = RecordHarness(signedIn: false);
      final vm = LoginViewModel(auth: h.auth, toast: h.toast);
      vm.signInDev();
      async.flushMicrotasks();
      expect(vm.busy, LoginProvider.kakao);
      expect(h.auth.status, AuthStatus.signedIn);
      // 관문이 다음 화면으로 넘기며 버린다
      vm.dispose();
      async.elapse(LoginViewModel.connectingTime);
      expect(h.toast.message, isNull);
    });
  });
}
