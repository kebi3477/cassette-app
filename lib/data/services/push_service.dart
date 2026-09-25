import 'dart:async';
import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// 푸시 종류 — 계약서 §16 푸시 `data.type`
enum PushKind { tape, gift, claimed }

/// 받은 푸시
class PushMessage {
  const PushMessage({
    required this.kind,
    required this.title,
    required this.body,
    this.deliveryId,
  });

  final PushKind kind;
  final String title;
  final String body;

  /// `tape` · `claimed`일 때
  final String? deliveryId;

  /// FCM `notification` + `data`에서 만든다. 모르는 종류면 null.
  static PushMessage? fromData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final kind = switch (data['type']) {
      'tape' => PushKind.tape,
      'gift' => PushKind.gift,
      'claimed' => PushKind.claimed,
      _ => null,
    };
    if (kind == null) return null;
    return PushMessage(
      kind: kind,
      title: title ?? '',
      body: body ?? '',
      deliveryId: data['deliveryId'] as String?,
    );
  }
}

/// 푸시 (FCM). 실제 구현은 [FirebasePushService].
abstract class PushService {
  /// OS 알림 권한을 요청한다. 허용하면 true.
  Future<bool> requestPermission();

  /// 이 기기의 푸시 토큰. 쓸 수 없으면 null.
  Future<String?> token();

  Stream<String> get onTokenRefresh;

  /// 앱이 켜져 있을 때 온 푸시 → 앱 안 배너(`pushOn`)
  Stream<PushMessage> get onForeground;

  /// 알림을 눌러 앱이 열렸을 때
  Stream<PushMessage> get onOpened;

  /// 앱이 꺼져 있다가 알림으로 열렸을 때
  Future<PushMessage?> initialMessage();

  String get platform => Platform.isIOS ? 'ios' : 'android';
}

/// firebase_messaging. `GoogleService-Info.plist` / `google-services.json`이 없으면
/// [create]가 null을 준다 → [LocalPushService]로 대신한다.
class FirebasePushService extends PushService {
  FirebasePushService._();

  final FirebaseMessaging _fm = FirebaseMessaging.instance;

  static Future<FirebasePushService?> create() async {
    try {
      await Firebase.initializeApp();
      return FirebasePushService._();
    } catch (_) {
      return null;
    }
  }

  static PushMessage? _map(RemoteMessage m) => PushMessage.fromData(
    m.data,
    title: m.notification?.title,
    body: m.notification?.body,
  );

  @override
  Future<bool> requestPermission() async {
    final s = await _fm.requestPermission();
    return s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<String?> token() async {
    try {
      return await _fm.getToken();
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForeground => FirebaseMessaging.onMessage
      .map(_map)
      .where((m) => m != null)
      .cast<PushMessage>();

  @override
  Stream<PushMessage> get onOpened => FirebaseMessaging.onMessageOpenedApp
      .map(_map)
      .where((m) => m != null)
      .cast<PushMessage>();

  @override
  Future<PushMessage?> initialMessage() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _map(m);
  }
}
