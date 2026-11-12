import 'package:eyes_school/core/storage/local_store.dart';

/// A [LocalStore] that lives in memory, so a test controls exactly what was
/// "on disk" before the app started — and needs no `path_provider` plugin.
class MemoryStore implements LocalStore {
  final Map<String, Object?> data = {};

  @override
  Future<T?> read<T extends Object>(String name) async => data[name] as T?;

  @override
  Future<List<Map<String, Object?>>> readList(String name) async {
    final raw = data[name];
    if (raw is! List) return [];
    return raw.cast<Map<String, Object?>>();
  }

  @override
  Future<void> write(String name, Object value) async => data[name] = value;

  @override
  Future<void> delete(String name) async => data.remove(name);
}
