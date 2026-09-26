import 'package:cassette_app/config/links.dart';
import 'package:cassette_app/data/services/local/local_store.dart';
import 'package:cassette_app/routing/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../testing/app.dart';
import '../../../testing/fonts.dart';
import '../../../testing/record_harness.dart';

void main() {
  setUpAll(loadAppFonts);

  testWidgets('로그인: 약관 동의·만 14세 안내, 이용약관·개인정보 처리방침 링크', (tester) async {
    useDesignScreen(tester);
    final h = RecordHarness(store: LocalStore(newUser: true), signedIn: false);
    await tester.pumpWidget(testApp(h, initialLocation: Routes.login));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(
      find.text(
        '계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요.\n만 14세 이상만 이용할 수 있어요',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tapOnText(find.textRange.ofSubstring('이용약관'));
    await tester.pump();
    await tester.tapOnText(find.textRange.ofSubstring('개인정보 처리방침'));
    await tester.pump();
    expect(h.links.opened, [AppLinks.terms, AppLinks.privacy]);

    // 안내 문구가 화면 안에 다 들어온다 (390×844)
    final rect = tester.getRect(
      find.textContaining('만 14세 이상만', findRichText: true),
    );
    expect(rect.bottom, lessThanOrEqualTo(844));
    await tester.pump(const Duration(seconds: 1));
  });
}
