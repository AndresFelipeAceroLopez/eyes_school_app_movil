import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/activity_log.dart';
import '../../models/attendance_summary.dart';
import '../../models/class_session.dart';
import '../../models/grade.dart';
import '../../models/guardian.dart';
import '../../models/novedad.dart';
import '../../models/role.dart';
import '../../models/roster_student.dart';
import '../../models/subject.dart';
import '../../models/user.dart';

/// Seed data mirroring the EyeSchool mockups. This is the single source of
/// truth for the mock repositories — swap the repositories for real API
/// implementations later without touching any UI code.
abstract final class MockSeed {
  // ---------------------------------------------------------------------
  // Users (demo accounts — one per role, matching the screenshots)
  // ---------------------------------------------------------------------
  static const teacher = AppUser(
    id: 'u-teacher-garcia',
    name: 'Prof. García',
    email: 'docente@eyeschool.edu',
    password: 'docente123',
    role: Role.teacher,
    photoUrl: '',
    subject: 'Matemáticas',
    institution: 'Col. San Marcos',
  );

  static const studentCarlos = AppUser(
    id: 'u-student-carlos',
    name: 'Carlos Jiménez',
    email: 'carlos.j@colegio.edu',
    password: 'estudiante123',
    role: Role.student,
    photoUrl: '',
    grade: 'Grado 8°A',
    jornada: 'Jornada mañana',
    code: 'STU-2024-0142',
    document: '1023456789',
    phone: '+57 310 555 4321',
    average: 8.7,
    attendancePercent: 94,
    guardians: [
      Guardian(name: 'María Jiménez', relation: 'Madre', phone: '+57 320 123 4567'),
    ],
  );

  static const studentSofia = AppUser(
    id: 'u-student-sofia',
    name: 'Sofía Jiménez',
    email: 'sofia.j@colegio.edu',
    password: 'estudiante123',
    role: Role.student,
    photoUrl: '',
    grade: 'Grado 6°B',
    jornada: 'Jornada mañana',
    code: 'STU-2024-0198',
    document: '1023456790',
    phone: '+57 310 555 4322',
    average: 9.1,
    attendancePercent: 98,
    guardians: [
      Guardian(name: 'María Jiménez', relation: 'Madre', phone: '+57 320 123 4567'),
    ],
  );

  static const parent = AppUser(
    id: 'u-parent-maria',
    name: 'María Jiménez',
    email: 'padre@eyeschool.edu',
    password: 'padre123',
    role: Role.parent,
    photoUrl: '',
    childrenIds: ['u-student-carlos', 'u-student-sofia'],
  );

  static const admin = AppUser(
    id: 'u-admin-carlos',
    name: 'Carlos Méndez',
    email: 'admin@eyeschool.edu',
    password: 'admin123',
    role: Role.admin,
    photoUrl: '',
    institution: 'Col. San Marcos',
  );

  // Extra users shown in the Admin "Usuarios" directory.
  static const anaGomez = AppUser(
    id: 'u-teacher-ana',
    name: 'Ana Gómez',
    email: 'ana.gomez@eyeschool.edu',
    password: 'demo1234',
    role: Role.teacher,
    photoUrl: '',
    subject: 'Ciencias Naturales',
  );

  static const carlosPerez = AppUser(
    id: 'u-student-perez',
    name: 'Carlos Pérez',
    email: 'carlos.perez@colegio.edu',
    password: 'demo1234',
    role: Role.student,
    photoUrl: '',
    grade: 'Grado 9°B',
    jornada: 'Jornada tarde',
    code: 'STU-2024-0210',
    document: '1023456999',
    phone: '+57 300 111 2233',
    average: 7.9,
    attendancePercent: 90,
    guardians: [
      Guardian(name: 'Jorge Pérez', relation: 'Padre', phone: '+57 300 999 1122'),
    ],
  );

  static const martaLopez = AppUser(
    id: 'u-admin-marta',
    name: 'Marta López',
    email: 'marta.lopez@eyeschool.edu',
    password: 'demo1234',
    role: Role.admin,
    photoUrl: '',
    institution: 'Col. San Marcos',
  );

  static const luisHernandez = AppUser(
    id: 'u-teacher-luis',
    name: 'Luis Hernández',
    email: 'luis.hernandez@eyeschool.edu',
    password: 'demo1234',
    role: Role.teacher,
    photoUrl: '',
    subject: 'Historia',
    status: AccountStatus.inactive,
  );

  static const robertoSilva = AppUser(
    id: 'u-parent-roberto',
    name: 'Roberto Silva',
    email: 'roberto.silva@eyeschool.edu',
    password: 'demo1234',
    role: Role.parent,
    photoUrl: '',
    childrenIds: ['u-student-perez'],
  );

  static List<AppUser> get allUsers => [
        teacher,
        studentCarlos,
        studentSofia,
        parent,
        admin,
        anaGomez,
        carlosPerez,
        martaLopez,
        luisHernandez,
        robertoSilva,
      ];

  static List<AppUser> get demoAccounts => [teacher, studentCarlos, parent, admin];

  // ---------------------------------------------------------------------
  // Teacher: today's classes
  // ---------------------------------------------------------------------
  static const teacherClasses = [
    ClassSession(
      time: '08:00',
      subject: 'Matemáticas',
      group: '8°A · Aula 204',
      room: 'Aula 204',
      status: ClassStatus.inCourse,
    ),
    ClassSession(
      time: '10:00',
      subject: 'Álgebra',
      group: '9°B · Aula 101',
      room: 'Aula 101',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      time: '13:00',
      subject: 'Geometría',
      group: '10°C · Aula 305',
      room: 'Aula 305',
      status: ClassStatus.upcoming,
    ),
  ];

  // ---------------------------------------------------------------------
  // Teacher: weekly schedule (Horario/Clases tab)
  // ---------------------------------------------------------------------
  static const teacherWeeklySchedule = [
    ClassSession(
      day: 'Lunes',
      time: '08:00',
      subject: 'Matemáticas',
      group: '8°A · Aula 204',
      room: 'Aula 204',
      status: ClassStatus.done,
    ),
    ClassSession(
      day: 'Lunes',
      time: '10:00',
      subject: 'Álgebra',
      group: '9°B · Aula 101',
      room: 'Aula 101',
      status: ClassStatus.done,
    ),
    ClassSession(
      day: 'Lunes',
      time: '13:00',
      subject: 'Geometría',
      group: '10°C · Aula 305',
      room: 'Aula 305',
      status: ClassStatus.done,
    ),
    ClassSession(
      day: 'Martes',
      time: '09:00',
      subject: 'Matemáticas',
      group: '8°A · Aula 204',
      room: 'Aula 204',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      day: 'Martes',
      time: '11:00',
      subject: 'Geometría',
      group: '10°C · Aula 305',
      room: 'Aula 305',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      day: 'Miércoles',
      time: '08:00',
      subject: 'Álgebra',
      group: '9°B · Aula 101',
      room: 'Aula 101',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      day: 'Miércoles',
      time: '10:00',
      subject: 'Matemáticas',
      group: '8°A · Aula 204',
      room: 'Aula 204',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      day: 'Jueves',
      time: '09:00',
      subject: 'Geometría',
      group: '10°C · Aula 305',
      room: 'Aula 305',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      day: 'Jueves',
      time: '13:00',
      subject: 'Álgebra',
      group: '9°B · Aula 101',
      room: 'Aula 101',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      day: 'Viernes',
      time: '08:00',
      subject: 'Matemáticas',
      group: '8°A · Aula 204',
      room: 'Aula 204',
      status: ClassStatus.upcoming,
    ),
    ClassSession(
      day: 'Viernes',
      time: '10:00',
      subject: 'Álgebra',
      group: '9°B · Aula 101',
      room: 'Aula 101',
      status: ClassStatus.upcoming,
    ),
  ];

  // Rosters for the teacher's groups, used by the attendance/grade-entry flows.
  static const rosterByGroup = {
    '8°A': [
      RosterStudent(id: 'u-student-carlos', name: 'Carlos Jiménez'),
      RosterStudent(id: 'r-8a-2', name: 'Valentina Rojas'),
      RosterStudent(id: 'r-8a-3', name: 'Santiago Ortiz'),
      RosterStudent(id: 'r-8a-4', name: 'Isabella Moreno'),
      RosterStudent(id: 'r-8a-5', name: 'Mateo Cárdenas'),
      RosterStudent(id: 'r-8a-6', name: 'Camila Rueda'),
      RosterStudent(id: 'r-8a-7', name: 'Samuel Vargas'),
      RosterStudent(id: 'r-8a-8', name: 'Luciana Peña'),
    ],
    '9°B': [
      RosterStudent(id: 'u-student-perez', name: 'Carlos Pérez'),
      RosterStudent(id: 'r-9b-2', name: 'Daniela Restrepo'),
      RosterStudent(id: 'r-9b-3', name: 'Julián Salazar'),
      RosterStudent(id: 'r-9b-4', name: 'Pedro Martínez'),
      RosterStudent(id: 'r-9b-5', name: 'Laura Sánchez'),
      RosterStudent(id: 'r-9b-6', name: 'Emiliano Duarte'),
      RosterStudent(id: 'r-9b-7', name: 'Antonella Ríos'),
    ],
    '10°C': [
      RosterStudent(id: 'r-10c-1', name: 'Nicolás Castaño'),
      RosterStudent(id: 'r-10c-2', name: 'Gabriela Pardo'),
      RosterStudent(id: 'r-10c-3', name: 'Tomás Aguirre'),
      RosterStudent(id: 'r-10c-4', name: 'Sara Beltrán'),
      RosterStudent(id: 'r-10c-5', name: 'Andrés Molina'),
      RosterStudent(id: 'r-10c-6', name: 'Renata Cifuentes'),
    ],
  };

  // ---------------------------------------------------------------------
  // Admin: Materias
  // ---------------------------------------------------------------------
  static const subjects = [
    Subject(name: 'Matemáticas', teacherName: 'Prof. García', groups: '8°A · 9°B · 10°C', studentCount: 96),
    Subject(name: 'Ciencias Naturales', teacherName: 'Ana Gómez', groups: '6°B · 7°A · 8°A', studentCount: 88),
    Subject(name: 'Historia', teacherName: 'Luis Hernández', groups: '8°A · 9°B · 10°C', studentCount: 96),
    Subject(name: 'Lengua y Literatura', teacherName: 'Marta López', groups: '6°B · 8°A', studentCount: 64),
    Subject(name: 'Educación Física', teacherName: 'Roberto Silva', groups: 'Todos los grados', studentCount: 248),
    Subject(name: 'Inglés', teacherName: 'Prof. García', groups: '8°A · 9°B', studentCount: 65),
    Subject(name: 'Arte', teacherName: 'Ana Gómez', groups: '6°B · 7°A', studentCount: 52),
    Subject(name: 'Tecnología', teacherName: 'Luis Hernández', groups: '9°B · 10°C', studentCount: 58),
  ];

  // ---------------------------------------------------------------------
  // Student: next class + grades
  // ---------------------------------------------------------------------
  static const studentNextClass = ClassSession(
    time: '10:00',
    subject: 'Matemáticas',
    group: 'Prof. García · Aula 204',
    room: 'Aula 204',
    status: ClassStatus.upcoming,
  );

  static Map<String, List<ClassSession>> weeklyScheduleByStudentId = {
    'u-student-carlos': const [
      ClassSession(day: 'Lunes', time: '08:00', subject: 'Matemáticas', group: 'Prof. García · Aula 204', room: 'Aula 204', status: ClassStatus.done),
      ClassSession(day: 'Lunes', time: '10:00', subject: 'Ciencias Naturales', group: 'Ana Gómez · Aula 105', room: 'Aula 105', status: ClassStatus.done),
      ClassSession(day: 'Martes', time: '09:00', subject: 'Lengua y Literatura', group: 'Marta López · Aula 110', room: 'Aula 110', status: ClassStatus.upcoming),
      ClassSession(day: 'Martes', time: '11:00', subject: 'Educación Física', group: 'Roberto Silva · Cancha', room: 'Cancha', status: ClassStatus.upcoming),
      ClassSession(day: 'Miércoles', time: '08:00', subject: 'Historia', group: 'Luis Hernández · Aula 112', room: 'Aula 112', status: ClassStatus.upcoming),
      ClassSession(day: 'Miércoles', time: '10:00', subject: 'Matemáticas', group: 'Prof. García · Aula 204', room: 'Aula 204', status: ClassStatus.upcoming),
      ClassSession(day: 'Jueves', time: '09:00', subject: 'Ciencias Naturales', group: 'Ana Gómez · Aula 105', room: 'Aula 105', status: ClassStatus.upcoming),
      ClassSession(day: 'Jueves', time: '13:00', subject: 'Lengua y Literatura', group: 'Marta López · Aula 110', room: 'Aula 110', status: ClassStatus.upcoming),
      ClassSession(day: 'Viernes', time: '08:00', subject: 'Educación Física', group: 'Roberto Silva · Cancha', room: 'Cancha', status: ClassStatus.upcoming),
      ClassSession(day: 'Viernes', time: '10:00', subject: 'Historia', group: 'Luis Hernández · Aula 112', room: 'Aula 112', status: ClassStatus.upcoming),
    ],
    'u-student-sofia': const [
      ClassSession(day: 'Lunes', time: '08:00', subject: 'Ciencias Naturales', group: 'Ana Gómez · Aula 106', room: 'Aula 106', status: ClassStatus.done),
      ClassSession(day: 'Lunes', time: '10:00', subject: 'Matemáticas', group: 'Prof. García · Aula 201', room: 'Aula 201', status: ClassStatus.done),
      ClassSession(day: 'Martes', time: '09:00', subject: 'Arte', group: 'Ana Gómez · Aula 118', room: 'Aula 118', status: ClassStatus.upcoming),
      ClassSession(day: 'Miércoles', time: '08:00', subject: 'Lengua y Literatura', group: 'Marta López · Aula 109', room: 'Aula 109', status: ClassStatus.upcoming),
      ClassSession(day: 'Jueves', time: '09:00', subject: 'Historia', group: 'Luis Hernández · Aula 111', room: 'Aula 111', status: ClassStatus.upcoming),
      ClassSession(day: 'Viernes', time: '08:00', subject: 'Educación Física', group: 'Roberto Silva · Cancha', room: 'Cancha', status: ClassStatus.upcoming),
    ],
    'u-student-perez': const [
      ClassSession(day: 'Lunes', time: '08:00', subject: 'Álgebra', group: 'Prof. García · Aula 101', room: 'Aula 101', status: ClassStatus.done),
      ClassSession(day: 'Martes', time: '09:00', subject: 'Ciencias Naturales', group: 'Ana Gómez · Aula 105', room: 'Aula 105', status: ClassStatus.upcoming),
      ClassSession(day: 'Miércoles', time: '08:00', subject: 'Historia', group: 'Luis Hernández · Aula 112', room: 'Aula 112', status: ClassStatus.upcoming),
      ClassSession(day: 'Jueves', time: '13:00', subject: 'Tecnología', group: 'Luis Hernández · Sala TI', room: 'Sala TI', status: ClassStatus.upcoming),
    ],
  };

  static Map<String, List<Grade>> gradesByStudentId = {
    'u-student-carlos': const [
      Grade(subject: 'Matemáticas', score: 8.7, period: 'Período 2 · 2024'),
      Grade(subject: 'Ciencias Naturales', score: 9.2, period: 'Período 2 · 2024'),
      Grade(subject: 'Lengua y Literatura', score: 8.1, period: 'Período 2 · 2024'),
      Grade(subject: 'Historia', score: 7.5, period: 'Período 2 · 2024'),
      Grade(subject: 'Educación Física', score: 9.8, period: 'Período 2 · 2024'),
    ],
    'u-student-sofia': const [
      Grade(subject: 'Matemáticas', score: 9.0, period: 'Período 2 · 2024'),
      Grade(subject: 'Ciencias Naturales', score: 9.4, period: 'Período 2 · 2024'),
      Grade(subject: 'Lengua y Literatura', score: 8.8, period: 'Período 2 · 2024'),
      Grade(subject: 'Historia', score: 9.1, period: 'Período 2 · 2024'),
      Grade(subject: 'Educación Física', score: 9.5, period: 'Período 2 · 2024'),
    ],
    'u-student-perez': const [
      Grade(subject: 'Matemáticas', score: 7.4, period: 'Período 2 · 2024'),
      Grade(subject: 'Ciencias Naturales', score: 8.0, period: 'Período 2 · 2024'),
      Grade(subject: 'Historia', score: 7.9, period: 'Período 2 · 2024'),
    ],
  };

  static Map<String, AttendanceSummary> attendanceByStudentId = {
    'u-student-carlos':
        const AttendanceSummary(percent: 94, present: 47, absent: 2, late: 1),
    'u-student-sofia':
        const AttendanceSummary(percent: 98, present: 49, absent: 0, late: 1),
    'u-student-perez':
        const AttendanceSummary(percent: 90, present: 45, absent: 3, late: 2),
  };

  static Map<String, List<Novedad>> novedadesByStudentId = {
    'u-student-carlos': const [
      Novedad(
        studentName: 'Carlos Jiménez',
        studentPhotoUrl: '',
        title: 'Retraso académico',
        timeAgo: 'Hace 2h',
        severity: NovedadSeverity.medium,
      ),
    ],
    'u-student-perez': const [
      Novedad(
        studentName: 'Carlos Pérez',
        studentPhotoUrl: '',
        title: 'Inasistencia injustificada',
        timeAgo: 'Ayer',
        severity: NovedadSeverity.high,
      ),
    ],
  };

  // Teacher's pending novedades feed (across their students).
  static const teacherPendingNovedades = [
    Novedad(
      studentName: 'Pedro Martínez',
      studentPhotoUrl: '',
      title: 'Retraso académico',
      timeAgo: 'Hace 2h',
      severity: NovedadSeverity.medium,
    ),
    Novedad(
      studentName: 'Laura Sánchez',
      studentPhotoUrl: '',
      title: 'Inasistencia injustificada',
      timeAgo: 'Ayer',
      severity: NovedadSeverity.high,
    ),
  ];

  // Parent's recent-updates feed.
  static const parentRecentActivity = [
    ActivityLog(
      icon: Icons.notifications_active_rounded,
      iconBg: Color(0xFFFCEEDD),
      iconColor: AppColors.orange,
      title: 'Novedad registrada en 8°A',
      subtitle: '',
      timeAgo: 'Hace 1h',
    ),
    ActivityLog(
      icon: Icons.star_rounded,
      iconBg: Color(0xFFF1E9FE),
      iconColor: AppColors.indigo,
      title: 'Nueva nota publicada · Carlos',
      subtitle: '',
      timeAgo: 'Ayer',
    ),
    ActivityLog(
      icon: Icons.check_circle_rounded,
      iconBg: Color(0xFFDDF8F3),
      iconColor: AppColors.tealDark,
      title: 'Asistencia registrada · Sofía',
      subtitle: '',
      timeAgo: 'Hoy 8:05',
    ),
  ];

  // ---------------------------------------------------------------------
  // Admin dashboard
  // ---------------------------------------------------------------------
  static const adminAttendanceToday =
      AttendanceSummary(percent: 94, present: 232, absent: 16, late: 8);

  static const adminActivity = [
    ActivityLog(
      icon: Icons.qr_code_scanner_rounded,
      iconBg: Color(0xFFDDF8F3),
      iconColor: AppColors.tealDark,
      title: 'QR escaneado',
      subtitle: 'Juan Pérez · Entrada registrada',
      timeAgo: 'Hoy · 7:48 AM',
    ),
    ActivityLog(
      icon: Icons.note_add_rounded,
      iconBg: Color(0xFFFCEEDD),
      iconColor: AppColors.orange,
      title: 'Novedad registrada',
      subtitle: 'Llegada tarde · Grado 8B',
      timeAgo: 'Hoy · 8:12 AM',
    ),
    ActivityLog(
      icon: Icons.person_add_alt_1_rounded,
      iconBg: Color(0xFFE9EDFE),
      iconColor: AppColors.blue,
      title: 'Usuario creado',
      subtitle: 'Ana Gómez · Docente agregada',
      timeAgo: 'Ayer · 3:40 PM',
    ),
    ActivityLog(
      icon: Icons.star_rounded,
      iconBg: Color(0xFFF1E9FE),
      iconColor: AppColors.indigo,
      title: 'Nota publicada',
      subtitle: 'Matemáticas · Grado 10A',
      timeAgo: 'Ayer · 11:20 AM',
    ),
  ];

  // All novedades across the school (Admin > Novedades).
  static const adminNovedades = [
    Novedad(
      studentName: 'Pedro Martínez',
      studentPhotoUrl: '',
      title: 'Retraso académico · Grado 9°B',
      timeAgo: 'Hace 2h',
      severity: NovedadSeverity.medium,
    ),
    Novedad(
      studentName: 'Laura Sánchez',
      studentPhotoUrl: '',
      title: 'Inasistencia injustificada · Grado 9°B',
      timeAgo: 'Ayer',
      severity: NovedadSeverity.high,
    ),
    Novedad(
      studentName: 'Carlos Jiménez',
      studentPhotoUrl: '',
      title: 'Retraso académico · Grado 8°A',
      timeAgo: 'Hace 2h',
      severity: NovedadSeverity.medium,
    ),
    Novedad(
      studentName: 'Carlos Pérez',
      studentPhotoUrl: '',
      title: 'Inasistencia injustificada · Grado 9°B',
      timeAgo: 'Ayer',
      severity: NovedadSeverity.high,
    ),
    Novedad(
      studentName: 'Grado 8°B',
      studentPhotoUrl: '',
      title: 'Llegada tarde generalizada',
      timeAgo: 'Hoy · 8:12 AM',
      severity: NovedadSeverity.low,
    ),
  ];

  static const adminStudentCount = 248;
  static const adminTeacherCount = 32;
  static const adminAlertCount = 6;
  static const adminGradesRegistered = 1248;
  static const adminIncidents = 6;
  static const adminIncidentsUnresolved = 2;
}
