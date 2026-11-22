import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:movielog/core/auth/token_storage.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Android secure storage write/read/new instance/delete', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('보안 저장소 검증 중'))),
    );
    final first = SecureTokenStorage();
    const phase = String.fromEnvironment('STORAGE_PROBE_PHASE');
    if (phase == 'write') {
      await first.saveAccessToken('non-secret-platform-test-value');
      expect(await first.readAccessToken(), 'non-secret-platform-test-value');
      return;
    }
    if (phase == 'verify') {
      expect(await first.readAccessToken(), 'non-secret-platform-test-value');
      await first.deleteAccessToken();
      expect(await first.readAccessToken(), isNull);
      return;
    }

    await first.deleteAccessToken();
    expect(await first.readAccessToken(), isNull);
    await first.saveAccessToken('non-secret-platform-test-value');
    expect(await first.readAccessToken(), 'non-secret-platform-test-value');
    final recreated = SecureTokenStorage();
    expect(await recreated.readAccessToken(), 'non-secret-platform-test-value');
    await recreated.deleteAccessToken();
    expect(await first.readAccessToken(), isNull);
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('보안 저장소 저장·읽기·삭제 성공'))),
    );
  });
}
