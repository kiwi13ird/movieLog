import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movielog/main.dart';

void main() {
  testWidgets('유효한 회원가입 정보일 때만 버튼이 활성화된다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    FilledButton button() =>
        tester.widget<FilledButton>(find.byKey(const Key('signUpButton')));
    expect(button().onPressed, isNull);

    await tester.enterText(find.byKey(const Key('nicknameField')), '키위');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'kiwi@movielog.com',
    );
    await tester.enterText(
      find.byKey(const Key('passwordField')),
      'password123',
    );
    await tester.ensureVisible(find.byKey(const Key('termsCheckbox')));
    await tester.tap(find.byKey(const Key('termsCheckbox')));
    await tester.pump();

    expect(button().onPressed, isNotNull);
  });

  testWidgets('잘못된 입력에 한국어 오류 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(const MovieLogApp());

    await tester.enterText(find.byKey(const Key('nicknameField')), '키');
    await tester.enterText(
      find.byKey(const Key('emailField')),
      'invalid-email',
    );
    await tester.enterText(find.byKey(const Key('passwordField')), '1234');
    await tester.pump();

    expect(find.text('닉네임은 두 글자 이상 입력해 주세요.'), findsOneWidget);
    expect(find.text('올바른 이메일 형식으로 입력해 주세요.'), findsOneWidget);
    expect(find.text('비밀번호는 8자 이상 입력해 주세요.'), findsOneWidget);
  });
}
