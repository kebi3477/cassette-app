import '../../domain/models/shelf.dart';
import '../../domain/models/tape_audio.dart';
import '../../domain/models/tape_item.dart';
import '../../utils/result.dart';
import '../model/mappers.dart';
import '../model/shelf_dto.dart';
import '../services/api/api_client.dart';
import 'repository_guard.dart';
import 'shelf_repository.dart';

class ShelfRepositoryRemote extends ShelfRepository {
  ShelfRepositoryRemote(this._api);

  final ApiClient _api;

  Future<Result<T>> _mutate<T>(Future<T> Function() call) async {
    final r = await guard(call);
    notifyListeners();
    return r;
  }

  @override
  Future<Result<Shelf>> getShelf() =>
      guard(() async => (await _api.getShelf()).toDomain());

  @override
  Future<Result<ShelfGroup>> createGroup(String name) =>
      _mutate(() async => (await _api.createGroup(name)).toDomain());

  @override
  Future<Result<ShelfGroup>> renameGroup(String groupId, String name) =>
      _mutate(() async => (await _api.renameGroup(groupId, name)).toDomain());

  @override
  Future<Result<void>> deleteGroup(String groupId) =>
      _mutate(() => _api.deleteGroup(groupId));

  @override
  Future<Result<TapeItem>> moveItem(
    String itemId, {
    required String? groupId,
    required String? afterId,
  }) => _mutate(
    () async => (await _api.moveShelfItem(
      itemId,
      MoveShelfItemRequest(groupId: groupId, afterId: afterId),
    )).toDomain(),
  );

  @override
  Future<Result<void>> deleteItem(String itemId) =>
      _mutate(() => _api.deleteShelfItem(itemId));

  @override
  Future<Result<TapeItem>> getItem(String itemId) =>
      guard(() async => (await _api.getDelivery(itemId)).toDomain());

  @override
  Future<Result<TapeItem>> open(String itemId) =>
      _mutate(() async => (await _api.openDelivery(itemId)).toDomain());

  @override
  Future<Result<TapeAudio>> audioUrl(String itemId) =>
      guard(() async => (await _api.getDeliveryAudio(itemId)).toDomain());
}
