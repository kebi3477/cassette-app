import '../../domain/models/shelf.dart';
import '../../utils/result.dart';
import '../services/local/local_store.dart';
import 'shelf_repository.dart';

class ShelfRepositoryLocal extends ShelfRepository {
  ShelfRepositoryLocal(this._store);

  final LocalStore _store;

  @override
  Future<Result<Shelf>> getShelf() async => Result.ok(_store.shelf);
}
