// MC-02: cada flavor de Android habla con su API y con su proyecto de Firebase.
import 'package:flutter_test/flutter_test.dart';

import 'package:eyes_school/core/network/api_config.dart';

void main() {
  test('el flavor qa usa la API de QA', () {
    expect(
      ApiConfig.hostFor('qa'),
      'https://apieyeschool-q-g4hfgrgvepbecacc.chilecentral-01.azurewebsites.net',
    );
  });

  test('prod, o sin flavor (pruebas, iOS), usa producción', () {
    const prod =
        'https://api-eyesschool-hrf2gsg7hyf9dacq.westus3-01.azurewebsites.net';
    expect(ApiConfig.hostFor('prod'), prod);
    expect(ApiConfig.hostFor(null), prod);
  });

  test('la ruta de la API cuelga del host', () {
    expect(ApiConfig.baseUrl, '${ApiConfig.host}/api/v1');
  });
}
