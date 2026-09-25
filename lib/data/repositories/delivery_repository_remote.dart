import '../../domain/models/recipient.dart';
import '../../domain/models/sent_tape.dart';
import '../../utils/result.dart';
import '../model/delivery_dto.dart';
import '../model/mappers.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';
import 'delivery_repository.dart';

class DeliveryRepositoryRemote implements DeliveryRepository {
  DeliveryRepositoryRemote(this._api);

  final ApiClient _api;

  @override
  Future<Result<SentTape>> send({
    required String recordingId,
    required Recipient to,
    required String idempotencyKey,
  }) => guard(
    () async => (await _api.createDelivery(
      CreateDeliveryRequest(
        recordingId: recordingId,
        recipientId: to.isNew ? null : to.friendId,
        linkName: to.isNew ? to.name : null,
      ),
      idempotencyKey: idempotencyKey,
    )).toDomain(),
  );

  @override
  Future<Result<SentPage>> getSent({String? cursor}) => guard(() async {
    final page = await _api.getSent(cursor: cursor);
    return SentPage(
      items: page.items.map((e) => e.toDomain()).toList(),
      nextCursor: page.nextCursor,
    );
  });

  @override
  Future<Result<SentTape>> getSentOne(String id) =>
      guard(() async => (await _api.getSentTape(id)).toDomain());

  @override
  Future<Result<Uri>> reshare(String sentId) =>
      guard(() async => Uri.parse((await _api.reshareSent(sentId)).url));
}
