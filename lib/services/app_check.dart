import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Test derlemelerinde `--dart-define=APPCHECK_DEBUG_TOKEN=...` ile verilir; token Firebase konsolundaki
/// "Manage debug tokens" listesine eklenmiş olmalı. Yayın derlemesinde boş bırakılır (Play Integrity).
const String _debugToken = String.fromEnvironment('APPCHECK_DEBUG_TOKEN');

/// YZ asistanının ayrı Firebase projesi. Ana proje faturalı (Blaze) olduğu için Gemini ücretsiz
/// katmanı orada geçerli değil; bu proje faturasız (Spark). Firestore ve giriş ana projede kalır.
const String assistantAppName = 'assistant';

const FirebaseOptions _assistantAndroidOptions = FirebaseOptions(
  apiKey: 'AIzaSyBxaRSNzg6gpPifiDcBdk5P-1c1fjyveYk',
  appId: '1:238145935005:android:d8ac7f5488a41d9b1da674',
  messagingSenderId: '238145935005',
  projectId: 'kktc-taksim-ai',
);

/// Asistan projesini açar ve App Check'i kurar (Firebase AI Logic için zorunlu).
/// Şimdilik yalnızca Android kayıtlı; kurulamazsa uygulama yine açılır, yalnızca asistan çalışmaz.
Future<void> initAssistantFirebase() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  try {
    final app = await Firebase.initializeApp(name: assistantAppName, options: _assistantAndroidOptions);
    await FirebaseAppCheck.instanceFor(app: app).activate(
      providerAndroid:
          _debugToken.isNotEmpty ? const AndroidDebugProvider(debugToken: _debugToken) : const AndroidPlayIntegrityProvider(),
    );
  } catch (e) {
    debugPrint('Asistan projesi kurulamadı: $e');
  }
}
