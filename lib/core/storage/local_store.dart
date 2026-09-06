import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Tiny JSON-document store backed by files in the app documents directory.
///
/// Used for data that must survive a process restart but is not a secret: the
/// student catalog that resolves scanned QR codes, and the pending-attendance
/// queue. Reads are cached in memory; writes are atomic (temp file + rename)
/// so a kill mid-write can never leave a half-written queue behind.
class LocalStore {
  LocalStore();

  final Map<String, Object?> _memory = {};
  Directory? _dir;

  /// True once the platform has been found to have no usable documents
  /// directory (the web build, or a device that denies it). The store then
  /// works in memory only: the app keeps running, it just forgets on restart.
  bool _fileSystemUnavailable = false;

  Future<Directory?> _directory() async {
    if (_fileSystemUnavailable) return null;
    final cached = _dir;
    if (cached != null) return cached;
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/eyeschool');
      if (!dir.existsSync()) await dir.create(recursive: true);
      return _dir = dir;
    } catch (_) {
      _fileSystemUnavailable = true;
      return null;
    }
  }

  Future<File?> _file(String name) async {
    final dir = await _directory();
    return dir == null ? null : File('${dir.path}/$name.json');
  }

  Future<T?> read<T extends Object>(String name) async {
    if (_memory.containsKey(name)) return _memory[name] as T?;
    try {
      final file = await _file(name);
      if (file == null || !file.existsSync()) return null;
      final decoded = jsonDecode(await file.readAsString());
      _memory[name] = decoded;
      return decoded as T?;
    } catch (_) {
      // A corrupt file is treated as "no data": the caller refetches.
      return null;
    }
  }

  Future<List<Map<String, Object?>>> readList(String name) async {
    final raw = await read<List<Object?>>(name);
    if (raw == null) return [];
    return raw.cast<Map<String, Object?>>();
  }

  /// Writing must never take down the caller: a scan that cannot reach the
  /// disk is still a scan the user made, and it stays in memory and in the
  /// send queue.
  Future<void> write(String name, Object value) async {
    _memory[name] = value;
    final file = await _file(name);
    if (file == null) return;
    try {
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(jsonEncode(value), flush: true);
      await temp.rename(file.path);
    } catch (_) {
      _fileSystemUnavailable = true;
    }
  }

  Future<void> delete(String name) async {
    _memory.remove(name);
    try {
      final file = await _file(name);
      if (file != null && file.existsSync()) await file.delete();
    } catch (_) {
      // Nothing to clean up.
    }
  }
}
