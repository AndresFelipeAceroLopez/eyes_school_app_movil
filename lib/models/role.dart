enum Role { teacher, student, parent, admin }

extension RoleLabel on Role {
  String get label => switch (this) {
        Role.teacher => 'Docente',
        Role.student => 'Estudiante',
        Role.parent => 'Padre / Acudiente',
        Role.admin => 'Administrador',
      };

  String get homePath => switch (this) {
        Role.teacher => '/teacher',
        Role.student => '/student',
        Role.parent => '/parent',
        Role.admin => '/admin',
      };
}
