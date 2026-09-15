import 'package:flutter/material.dart';

/// La mascota de EyeSchool: el monstruo saltando con su libro.
///
/// El GIF de `assets/` ya viene con el fondo blanco recortado (lo hace
/// `tool/make_transparent_gif.dart` con el paquete `image`), así que se apoya
/// directamente sobre el degradado de la cabecera, sin caja ni recuadro detrás.
class MonsterMascot extends StatelessWidget {
  const MonsterMascot({super.key, this.height = 128});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/monster_reading.gif',
      height: height,
      fit: BoxFit.contain,
      // El GIF se reproduce solo; `gaplessPlayback` evita el parpadeo al
      // reconstruir la pantalla (por ejemplo al mostrar un error de acceso).
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
  }
}
