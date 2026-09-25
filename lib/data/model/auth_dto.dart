import 'friend_dto.dart';
import 'json.dart';
import 'me_dto.dart';
import 'shelf_dto.dart';

/// 로그인 응답 — 계약서 §6 AuthResponse
class AuthResponseDto {
  const AuthResponseDto({
    required this.tokens,
    required this.isNewUser,
    this.suggestedName,
    required this.user,
  });

  final TokenPairDto tokens;
  final bool isNewUser;

  /// 이름 정하기 화면에 미리 채울 이름
  final String? suggestedName;
  final MeDto user;

  factory AuthResponseDto.fromJson(Json j) => AuthResponseDto(
    tokens: TokenPairDto.fromJson(j),
    isNewUser: j['isNewUser'] as bool,
    suggestedName: j['suggestedName'] as String?,
    user: MeDto.fromJson(j['user'] as Json),
  );

  Json toJson() => {
    ...tokens.toJson(),
    'isNewUser': isNewUser,
    'suggestedName': suggestedName,
    'user': user.toJson(),
  };
}

/// `POST /auth/refresh` 응답 (토큰 쌍)
class TokenPairDto {
  const TokenPairDto({
    required this.accessToken,
    required this.accessTokenExpiresAt,
    required this.refreshToken,
    required this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final DateTime accessTokenExpiresAt;
  final String refreshToken;
  final DateTime refreshTokenExpiresAt;

  factory TokenPairDto.fromJson(Json j) => TokenPairDto(
    accessToken: j['accessToken'] as String,
    accessTokenExpiresAt: parseDate(j['accessTokenExpiresAt']),
    refreshToken: j['refreshToken'] as String,
    refreshTokenExpiresAt: parseDate(j['refreshTokenExpiresAt']),
  );

  Json toJson() => {
    'accessToken': accessToken,
    'accessTokenExpiresAt': dateToJson(accessTokenExpiresAt),
    'refreshToken': refreshToken,
    'refreshTokenExpiresAt': dateToJson(refreshTokenExpiresAt),
  };
}

/// `POST /auth/apple` 요청
class AppleAuthRequest {
  const AppleAuthRequest({
    required this.identityToken,
    this.authorizationCode,
    this.nonce,
  });

  final String identityToken;

  /// 서버가 탈퇴할 때 Apple 토큰을 철회하려고 쓴다 — 보내 달라고 한다.
  final String? authorizationCode;

  /// Apple에 넘긴 `sha256(nonce)`의 원문
  final String? nonce;

  Json toJson() => {
    'identityToken': identityToken,
    'authorizationCode': ?authorizationCode,
    'nonce': ?nonce,
  };
}

/// `GET /app-version`
class AppVersionDto {
  const AppVersionDto({
    required this.platform,
    required this.minVersion,
    required this.latestVersion,
    required this.storeUrl,
    this.updateRequired,
    this.updateAvailable,
  });

  final String platform;
  final String minVersion;
  final String latestVersion;
  final String storeUrl;

  /// `version`을 보냈을 때만 채워진다.
  final bool? updateRequired;
  final bool? updateAvailable;

  factory AppVersionDto.fromJson(Json j) => AppVersionDto(
    platform: j['platform'] as String,
    minVersion: j['minVersion'] as String,
    latestVersion: j['latestVersion'] as String,
    storeUrl: j['storeUrl'] as String,
    updateRequired: j['updateRequired'] as bool?,
    updateAvailable: j['updateAvailable'] as bool?,
  );

  Json toJson() => {
    'platform': platform,
    'minVersion': minVersion,
    'latestVersion': latestVersion,
    'storeUrl': storeUrl,
    'updateRequired': updateRequired,
    'updateAvailable': updateAvailable,
  };
}

/// `GET /share/{token}` — 링크 테이프 미리보기
class ShareInfoDto {
  const ShareInfoDto({
    required this.state,
    this.deliveryId,
    required this.sender,
    required this.tapeType,
    required this.durationMs,
    this.tag,
    required this.sentAt,
    required this.expiresAt,
  });

  /// `available` · `claimed`(내가 이미 받음)
  final String state;

  /// `claimed`일 때 서랍의 그 테이프
  final String? deliveryId;
  final UserRefDto sender;
  final int tapeType;
  final int durationMs;
  final String? tag;
  final DateTime sentAt;
  final DateTime expiresAt;

  factory ShareInfoDto.fromJson(Json j) => ShareInfoDto(
    state: j['state'] as String,
    deliveryId: j['deliveryId'] as String?,
    sender: UserRefDto.fromJson(j['sender'] as Json),
    tapeType: j['tapeType'] as int,
    durationMs: j['durationMs'] as int,
    tag: j['tag'] as String?,
    sentAt: parseDate(j['sentAt']),
    expiresAt: parseDate(j['expiresAt']),
  );

  Json toJson() => {
    'state': state,
    'deliveryId': deliveryId,
    'sender': sender.toJson(),
    'tapeType': tapeType,
    'durationMs': durationMs,
    'tag': tag,
    'sentAt': dateToJson(sentAt),
    'expiresAt': dateToJson(expiresAt),
  };
}

/// `POST /share/{token}/claim` 응답
class ClaimResultDto {
  const ClaimResultDto({required this.item, this.friend});

  final ShelfItemDto item;

  /// 서로 친구가 됐으면 그 친구. 차단 관계면 null
  final FriendDto? friend;

  factory ClaimResultDto.fromJson(Json j) => ClaimResultDto(
    item: ShelfItemDto.fromJson(j['item'] as Json),
    friend: j['friend'] == null
        ? null
        : FriendDto.fromJson(j['friend'] as Json),
  );

  Json toJson() => {'item': item.toJson(), 'friend': friend?.toJson()};
}
