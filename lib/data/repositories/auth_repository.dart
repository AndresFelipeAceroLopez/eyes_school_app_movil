import '../../models/user.dart';
import '../mock/mock_seed.dart';

abstract class AuthRepository {
  Future<AppUser> login({required String email, required String password});
  Future<AppUser?> findById(String id);
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}

/// Mock implementation backed by [MockSeed]. Swap this for a real HTTP/
/// Firebase implementation later — the interface stays the same.
class MockAuthRepository implements AuthRepository {
  @override
  Future<AppUser> login({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 700));

    final normalizedEmail = email.trim().toLowerCase();
    final user = MockSeed.allUsers
        .where((u) => u.email.toLowerCase() == normalizedEmail)
        .firstOrNull;

    if (user == null) {
      throw AuthException('No existe una cuenta con ese correo.');
    }
    if (password.isEmpty) {
      throw AuthException('Ingresa tu contraseña.');
    }
    if (user.password != password) {
      throw AuthException('Contraseña incorrecta.');
    }
    return user;
  }

  @override
  Future<AppUser?> findById(String id) async {
    return MockSeed.allUsers.where((u) => u.id == id).firstOrNull;
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
