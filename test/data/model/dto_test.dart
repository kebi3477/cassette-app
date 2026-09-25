import 'package:cassette_app/data/model/api_error.dart';
import 'package:cassette_app/data/model/delivery_dto.dart';
import 'package:cassette_app/data/model/mappers.dart';
import 'package:cassette_app/data/model/me_dto.dart';
import 'package:cassette_app/data/model/recording_dto.dart';
import 'package:cassette_app/data/model/shelf_dto.dart';
import 'package:cassette_app/domain/models/recording.dart';
import 'package:cassette_app/domain/models/sent_tape.dart';
import 'package:cassette_app/domain/models/tape_tag.dart';
import 'package:cassette_app/domain/models/tape_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 계약서(cassette-api/docs/api.md)의 예시 JSON을 그대로 읽는다.
void main() {
  test('Me (§2) — unopenedCount가 없어도 읽는다', () {
    final me = MeDto.fromJson({
      'id': 'd3d62aa5',
      'name': '민경',
      'credits': 120,
      'drawer': {'stored': 11, 'cap': 12, 'full': false},
      'tapes': [
        {'tapeType': 1, 'qty': null},
        {'tapeType': 3, 'qty': 2},
        {'tapeType': 5, 'qty': 0},
      ],
      'stats': {'receivedCount': 11, 'sentCount': 4, 'friendCount': 6},
      'providers': ['kakao'],
      'notificationsEnabled': true,
      'createdAt': '2026-09-01T03:00:00.000Z',
    }).toDomain();
    expect(me.owned, {TapeType.three: 2, TapeType.five: 0});
    expect(me.drawer.unopenedCount, 0);
  });

  test('ShelfItem (§2)', () {
    final x = ShelfItemDto.fromJson({
      'id': 'd1',
      'sender': {'userId': 'u1', 'name': '지현'},
      'tapeType': 3,
      'durationMs': 34000,
      'tag': 'birthday',
      'sentAt': '2026-09-24T09:00:00.000Z',
      'opened': false,
      'openedAt': null,
      'viaLink': false,
      'groupId': null,
    }).toDomain();
    expect(x.from, '지현');
    expect(x.senderId, 'u1');
    expect(x.tag, TapeTag.birthday);
    expect(x.duration, const Duration(seconds: 34));
    expect(x.groupId, isNull);
  });

  test('SentTape (§2) 링크 대기', () {
    final s = SentTapeDto.fromJson({
      'id': 'd2',
      'recipient': null,
      'linkName': '유진',
      'tapeType': 1,
      'durationMs': 20000,
      'tag': 'thinking',
      'sentAt': '2026-09-22T09:00:00.000Z',
      'status': 'link_pending',
      'claimedAt': null,
      'openedAt': null,
      'share': {
        'url': 'https://x/t/abc',
        'expiresAt': '2026-09-29T09:00:00.000Z',
      },
    }).toDomain();
    expect(s.status, SentStatus.linkPending);
    expect(s.to, '유진');
    expect(s.link, isTrue);
    expect(s.claimed, isFalse);
  });

  test('Recording (§9) preview', () {
    final r = RecordingDto.fromJson({
      'id': 'r1',
      'tapeType': 3,
      'durationMs': 95000,
      'status': 'ready',
      'preview': {'url': 'https://p', 'expiresAt': '2026-09-25T06:44:46.549Z'},
    }).toDomain();
    expect(r.status, RecordingStatus.ready);
    expect(r.previewUrl, 'https://p');
    expect(r.duration, const Duration(seconds: 95));
  });

  test('POST /deliveries 요청 본문: recipientId 또는 linkName + tag', () {
    expect(
      const CreateDeliveryRequest(
        recordingId: 'r1',
        recipientId: 'u1',
        tag: 'birthday',
      ).toJson(),
      {'recordingId': 'r1', 'recipientId': 'u1', 'tag': 'birthday'},
    );
    expect(
      const CreateDeliveryRequest(
        recordingId: 'r1',
        linkName: '유진',
        tag: 'thinking',
      ).toJson(),
      {'recordingId': 'r1', 'linkName': '유진', 'tag': 'thinking'},
    );
  });

  test('오류 형식 {code, message, …추가 필드}', () {
    final e = ApiException.fromJson(402, {
      'code': 'INSUFFICIENT_CREDITS',
      'message': '크레딧이 부족해요',
      'need': 20,
    });
    expect(e.code, 'INSUFFICIENT_CREDITS');
    expect(e.extra, {'need': 20});
  });

  test('PATCH /shelf/items 본문은 null도 보낸다', () {
    expect(const MoveShelfItemRequest(groupId: null, afterId: null).toJson(), {
      'groupId': null,
      'afterId': null,
    });
  });
}
