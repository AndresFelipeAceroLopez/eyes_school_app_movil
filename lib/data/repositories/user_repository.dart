import '../../models/user.dart';
import '../mock/mock_seed.dart';

abstract class UserRepository {
  Future<List<AppUser>> getAllUsers();
  Future<AppUser?> getUserById(String id);
  Future<List<AppUser>> getChildrenOf(AppUser parent);
}

class MockUserRepository implements UserRepository {
  @override
  Future<List<AppUser>> getAllUsers() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSeed.allUsers;
  }

  @override
  Future<AppUser?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (final u in MockSeed.allUsers) {
      if (u.id == id) return u;
    }
    return null;
  }

  @override
  Future<List<AppUser>> getChildrenOf(AppUser parent) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return MockSeed.allUsers.where((u) => parent.childrenIds.contains(u.id)).toList();
  }
}
