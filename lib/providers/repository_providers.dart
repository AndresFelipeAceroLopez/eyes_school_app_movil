import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/academic_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => MockAuthRepository());

final userRepositoryProvider = Provider<UserRepository>((ref) => MockUserRepository());

final academicRepositoryProvider =
    Provider<AcademicRepository>((ref) => MockAcademicRepository());
