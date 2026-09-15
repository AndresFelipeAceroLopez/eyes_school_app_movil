enum Role { teacher, student, parent, admin }

extension RoleLabel on Role {
  String get label => switch (this) {
        Role.teacher => 'Docente',
        Role.student => 'Estudiante',
        Role.parent => 'Padre / Acudiente',
        Role.admin => 'Administrador',
      };

  /// Landing route for the role. It is also the namespace the router guards:
  /// a session may only ever be inside its own prefix.
  String get homePath => switch (this) {
        Role.teacher => '/teacher',
        Role.student => '/student',
        Role.parent => '/parent',
        Role.admin => '/admin',
      };

  /// `id_rol` as stored by the API.
  int get apiId => switch (this) {
        Role.teacher => 1,
        Role.student => 2,
        Role.admin => 3,
        Role.parent => 4,
      };
}

/// Maps `MeResponse.id_rol` — the single source of truth for the role — onto
/// the app's enum. An unknown id is treated as a student: the most restricted
/// shell, so a future role can never accidentally inherit admin screens.
Role roleFromApiId(int idRol) => switch (idRol) {
      1 => Role.teacher,
      2 => Role.student,
      3 => Role.admin,
      4 => Role.parent,
      _ => Role.student,
    };
