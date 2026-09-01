import 'guardian.dart';
import 'role.dart';

enum AccountStatus { active, inactive }

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.photoUrl,
    this.status = AccountStatus.active,
    this.subject,
    this.institution,
    this.grade,
    this.jornada,
    this.code,
    this.document,
    this.phone,
    this.average,
    this.attendancePercent,
    this.guardians = const [],
    this.childrenIds = const [],
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final Role role;
  final String photoUrl;
  final AccountStatus status;

  // Teacher / Admin
  final String? subject;
  final String? institution;

  // Student
  final String? grade;
  final String? jornada;
  final String? code;
  final String? document;
  final String? phone;
  final double? average;
  final double? attendancePercent;
  final List<Guardian> guardians;

  // Parent
  final List<String> childrenIds;

  String get firstName => name.split(' ').first;
}
