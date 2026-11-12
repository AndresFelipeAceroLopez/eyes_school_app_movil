// IT-APP-07 · Contrato grabado contra la API real (PR-05).
//
// Inicia sesión en la API de QA con los usuarios de DS-01 y DS-03 y guarda,
// SIN tokens, las respuestas de los endpoints que usa la app en
// test/fixtures/api/<nombre>.json. `git diff test/fixtures/api/` muestra
// exactamente qué cambió en la API entre una corrida y otra.
//
// La planeación pedía `tool/grabar_contrato.sh` con curl y jq; se escribió en
// Dart para no depender de jq y correr igual en Windows y en el CI.
//
// Uso (nada de esto va escrito en el código; regla 9 de la planeación):
//   QA_API_URL=https://<host>/api/v1  QA_PASSWORD=...  \
//   QA_ADMIN=...  QA_DOCENTE=...  QA_ESTUDIANTE=...  QA_PADRE=...  \
//   dart run tool/grabar_contrato.dart
//
// QA_PADRE debe ser el padre de dos hijos (DS-03).
import 'dart:convert';
import 'dart:io';

late final String _api;
late final String _password;
final _out = Directory('test/fixtures/api');
final _manifest = <String, Object?>{};

Future<void> main() async {
  final env = Platform.environment;
  String need(String k) {
    final v = env[k];
    if (v == null || v.isEmpty) {
      stderr.writeln('Falta la variable de entorno $k');
      exit(64);
    }
    return v;
  }

  _api = need('QA_API_URL').replaceAll(RegExp(r'/+$'), '');
  _password = need('QA_PASSWORD');
  final admin = need('QA_ADMIN');
  final docente = need('QA_DOCENTE');
  final estudiante = need('QA_ESTUDIANTE');
  final padre = need('QA_PADRE');

  _out.createSync(recursive: true);
  final today = DateTime.now();
  final fecha =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  // ── Estudiante ──────────────────────────────────────────────────────────
  final tEst = await _login(estudiante);
  await _save('auth_me_estudiante', '/auth/me', tEst);
  final me = await _save('estudiantes_me', '/estudiantes/me', tEst) as Map;
  final idEst = me['id_estudiante'];
  final curso = me['id_curso_actual'];
  await _save('estudiantes_id_notas', '/estudiantes/$idEst/notas', tEst);
  await _save(
    'estudiantes_id_asistencia',
    '/estudiantes/$idEst/asistencia?limit=20',
    tEst,
  );
  await _save(
    'estudiantes_id_novedades',
    '/estudiantes/$idEst/novedades',
    tEst,
  );
  await _save('cursos_id_horarios', '/cursos/$curso/horarios', tEst);
  await _save('dashboard_estudiante', '/dashboard/estudiante', tEst);

  // ── Docente ─────────────────────────────────────────────────────────────
  final tDoc = await _login(docente);
  final meDoc = await _save('auth_me_docente', '/auth/me', tDoc) as Map;
  final profes = await _get('/profesores?limit=200', tDoc);
  final prof = (profes.body as List).cast<Map>().firstWhere(
    (p) => p['id_usuario'] == meDoc['id_usuario'],
    orElse: () => const {},
  );
  if (prof.isNotEmpty) {
    await _save(
      'asignaciones_docente',
      '/asignaciones?id_profesor=${prof['id_profesor']}&limit=200',
      tDoc,
    );
  }
  await _save('asistencia_fecha', '/asistencia?fecha=$fecha&limit=20', tDoc);
  await _save('dashboard_docente', '/dashboard/docente', tDoc);

  // ── Administrador ───────────────────────────────────────────────────────
  final tAdm = await _login(admin);
  await _save('auth_me_admin', '/auth/me', tAdm);
  await _save('cursos', '/cursos?limit=200', tAdm);
  await _save('materias', '/materias', tAdm);
  await _save('novedades', '/novedades?limit=20', tAdm);
  await _save('tipos_novedad', '/tipos-novedad', tAdm);
  await _save('reportes', '/reportes?limit=20', tAdm);

  // ── Padre de dos hijos (DS-03) ──────────────────────────────────────────
  final tPad = await _login(padre);
  await _save('auth_me_padre', '/auth/me', tPad);
  await _save('padres_me', '/padres/me', tPad);
  await _save('padres_me_hijos', '/padres/me/hijos', tPad);
  await _save('dashboard_padre', '/dashboard/padre', tPad);

  File('${_out.path}/_manifest.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(_manifest)}\n',
  );
  stdout.writeln('Grabados ${_manifest.length} endpoints en ${_out.path}');
}

class _Resp {
  _Resp(this.status, this.body);
  final int status;
  final Object? body;
}

final _http = HttpClient()..connectionTimeout = const Duration(seconds: 60);

Future<_Resp> _send(
  String method,
  String path, {
  String? token,
  Object? body,
}) async {
  final req = await _http.openUrl(method, Uri.parse('$_api$path'));
  req.headers.contentType = ContentType.json;
  if (token != null) req.headers.set('Authorization', 'Bearer $token');
  if (body != null) req.add(utf8.encode(jsonEncode(body)));
  final res = await req.close();
  final text = await res.transform(utf8.decoder).join();
  Object? decoded;
  try {
    decoded = text.isEmpty ? null : jsonDecode(text);
  } on FormatException {
    decoded = text;
  }
  return _Resp(res.statusCode, decoded);
}

Future<String> _login(String correo) async {
  final r = await _send(
    'POST',
    '/auth/login',
    body: {'correo': correo, 'password': _password},
  );
  if (r.status != 200) {
    stderr.writeln('Login fallido ($correo): ${r.status}');
    exit(1);
  }
  return (r.body as Map)['access_token'] as String;
}

Future<_Resp> _get(String path, String token) =>
    _send('GET', path, token: token);

/// Guarda la respuesta. Nunca escribe encabezados ni tokens: solo el cuerpo.
Future<Object?> _save(String name, String path, String token) async {
  final r = await _get(path, token);
  final route = path.split('?').first;
  _manifest[name] = {'ruta': route, 'consulta': path, 'estado': r.status};
  File('${_out.path}/$name.json').writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(r.body)}\n',
  );
  stdout.writeln('${r.status}  $path  →  $name.json');
  return r.body;
}
