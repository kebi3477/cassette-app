import '../../model/delivery_dto.dart';
import '../../model/friend_dto.dart';
import '../../model/me_dto.dart';
import '../../model/page_dto.dart';
import '../../model/recording_dto.dart';
import '../../model/shelf_dto.dart';
import '../../model/wallet_dto.dart';

/// 서버 API — `cassette-api/docs/api.md`의 엔드포인트와 1:1.
///
/// 실패하면 [ApiException](../../model/api_error.dart)을 던진다.
/// 지금은 메모리 구현([LocalApiClient])만 있고, 다음 단계에서 HTTP 구현을 넣는다.
abstract class ApiClient {
  // users
  /// `GET /users/me`
  Future<MeDto> getMe();

  /// `PATCH /users/me`
  Future<MeDto> patchMe(PatchMeRequest body);

  // friends
  /// `GET /friends`
  Future<PageDto<FriendDto>> getFriends();

  /// `PATCH /friends/{userId}` `{ starred }`
  Future<FriendDto> patchFriend(String userId, {required bool starred});

  /// `GET /friends/{userId}/tapes`
  Future<FriendTapesDto> getFriendTapes(String userId);

  // recordings
  /// `POST /recordings`
  Future<RecordingUploadDto> createRecording(CreateRecordingRequest body);

  /// `POST /recordings/{id}/complete`
  Future<RecordingDto> completeRecording(String id);

  /// `GET /recordings/{id}`
  Future<RecordingDto> getRecording(String id);

  /// `POST /recordings/{id}/retry`
  Future<RecordingDto> retryRecording(String id);

  // deliveries
  /// `POST /deliveries` 🔑
  Future<SentTapeDto> createDelivery(
    CreateDeliveryRequest body, {
    required String idempotencyKey,
  });

  /// `GET /deliveries/sent`
  Future<PageDto<SentTapeDto>> getSent({String? cursor, int? limit});

  /// `GET /deliveries/{id}`
  Future<ShelfItemDto> getDelivery(String id);

  /// `POST /deliveries/{id}/open`
  Future<ShelfItemDto> openDelivery(String id);

  /// `GET /deliveries/{id}/audio`
  Future<AudioUrlDto> getDeliveryAudio(String id);

  // shelf
  /// `GET /shelf`
  Future<ShelfDto> getShelf();

  /// `POST /shelf/groups` `{ name }`
  Future<ShelfGroupDto> createGroup(String name);

  /// `PATCH /shelf/groups/{id}` `{ name }`
  Future<ShelfGroupDto> renameGroup(String id, String name);

  /// `DELETE /shelf/groups/{id}`
  Future<void> deleteGroup(String id);

  /// `PATCH /shelf/items/{id}` `{ groupId, afterId }`
  Future<ShelfItemDto> moveShelfItem(String id, MoveShelfItemRequest body);

  /// `DELETE /shelf/items/{id}`
  Future<void> deleteShelfItem(String id);

  // wallet
  /// `GET /wallet`
  Future<WalletDto> getWallet();

  /// `GET /wallet/ledger`
  Future<PageDto<LedgerEntryDto>> getLedger({String? cursor, int? limit});
}
