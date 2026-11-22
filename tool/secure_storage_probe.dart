// Opt-in Android device probe. Only a non-secret sentinel is stored.
// Install once; force-stop and launch the same APK again to verify persistence.
import 'package:flutter/material.dart';
import 'package:movielog/core/auth/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = SecureTokenStorage();
  const sentinel = 'non-secret-platform-restart-probe';
  String message;
  final previous = await storage.readAccessToken();
  if (previous == null) {
    await storage.saveAccessToken(sentinel);
    if (await storage.readAccessToken() != sentinel) {
      throw StateError('Write failed');
    }
    message = '1단계: 보안 저장소 저장 성공\n앱을 종료하고 다시 실행하세요.';
    debugPrint('SECURE_STORAGE_PROBE: WRITE PASS');
  } else if (previous == sentinel) {
    await storage.deleteAccessToken();
    if (await storage.readAccessToken() != null) {
      throw StateError('Delete failed');
    }
    message = '2단계: 앱 재실행 후 읽기 성공\n보안 저장소 삭제 성공';
    debugPrint('SECURE_STORAGE_PROBE: RESTART READ AND DELETE PASS');
  } else {
    message = '기존 인증 정보가 있어 검증을 중단합니다.';
  }
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Android 보안 저장소 검증')),
        body: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
    ),
  );
}
