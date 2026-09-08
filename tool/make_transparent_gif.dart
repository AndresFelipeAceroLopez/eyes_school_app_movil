// Quita el fondo blanco de un GIF y lo vuelve a codificar con transparencia,
// usando el paquete `image` (https://pub.dev/packages/image).
//
//   dart run tool/make_transparent_gif.dart [entrada.gif] [salida.gif] [opciones]
//
//   --max-width=N   reescala el resultado a N pixeles de ancho como maximo
//   --frame-step=N  conserva 1 de cada N fotogramas (alarga su duracion)
//   --no-defringe   no recorta el borde claro que deja el antialias
//
// El fondo se detecta con un relleno por inundacion (flood fill) desde los
// bordes: solo se borra el blanco conectado con el marco, asi el blanco que
// forma parte del dibujo (el libro, los ojos) se conserva intacto.
//
// El proceso es lento (segundos por GIF), por eso vive aqui y no en la app:
// se ejecuta una vez y lo que se publica en `assets/` ya viene recortado.

import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Canal minimo para considerar un pixel "blanco de fondo".
const _minChannel = 232;

/// Diferencia maxima entre canales: el fondo es gris/blanco, no un color.
const _maxSpread = 18;

/// Umbral, mas flojo, para el halo claro pegado al fondo ya recortado.
const _fringeChannel = 205;
const _fringeSpread = 34;

/// Islas opacas mas pequenas que esto se descartan: son motas sueltas del
/// tramado (dithering) del GIF original, no partes del personaje.
const _minIslandArea = 48;

void main(List<String> args) {
  final positional = args.where((a) => !a.startsWith('--')).toList();
  final input = positional.isNotEmpty
      ? positional[0]
      : 'planeacion/text.md/Blue_monster_jumping_with_book_202609072242.gif';
  final output =
      positional.length > 1 ? positional[1] : 'assets/images/monster_reading.gif';
  final maxWidth = _intFlag(args, '--max-width');
  final frameStep = _intFlag(args, '--frame-step') ?? 1;
  final defringe = !args.contains('--no-defringe');

  final source = File(input);
  if (!source.existsSync()) {
    stderr.writeln('No existe el archivo de entrada: $input');
    exitCode = 2;
    return;
  }

  final animation = img.decodeGif(source.readAsBytesSync());
  if (animation == null) {
    stderr.writeln('No se pudo decodificar el GIF: $input');
    exitCode = 2;
    return;
  }

  stdout.writeln('Entrada: $input (${animation.width}x${animation.height}, '
      '${animation.numFrames} fotogramas)');

  // Paso 1: quedarse con los fotogramas elegidos y reescalarlos si hace falta.
  final frames = <img.Image>[];
  final durations = <int>[];
  for (var i = 0; i < animation.numFrames; i += frameStep) {
    var frame = animation.frames[i];
    if (maxWidth != null && frame.width > maxWidth) {
      frame = img.copyResize(
        frame,
        width: maxWidth,
        interpolation: img.Interpolation.average,
      );
    }
    frames.add(frame);
    // El fotograma conservado dura tambien lo que duraban los descartados.
    var duration = 0;
    for (var j = i; j < i + frameStep && j < animation.numFrames; j++) {
      duration += animation.frames[j].frameDuration;
    }
    durations.add(duration);
  }

  // Paso 2: mascara de fondo por fotograma y recuadro comun del personaje.
  final masks = <Uint8List>[];
  var minX = frames.first.width, minY = frames.first.height;
  var maxX = -1, maxY = -1;
  for (final frame in frames) {
    final mask = _backgroundMask(frame);
    _removeSpeckles(mask, frame.width, frame.height);
    if (defringe) _trimFringe(frame, mask);
    masks.add(mask);
    for (var y = 0; y < frame.height; y++) {
      for (var x = 0; x < frame.width; x++) {
        if (mask[y * frame.width + x] == 1) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < 0) {
    stderr.writeln('El GIF quedo completamente transparente; revisa el umbral.');
    exitCode = 1;
    return;
  }

  final cropW = maxX - minX + 1;
  final cropH = maxY - minY + 1;
  stdout.writeln('Recorte al personaje: ${cropW}x$cropH en ($minX, $minY)');

  // Paso 3: recortar y re-empaquetar cada fotograma con el indice 0 transparente.
  final encoder = img.GifEncoder(repeat: 0, dispose: 2);
  for (var i = 0; i < frames.length; i++) {
    final frame = _cutOut(frames[i], masks[i], minX, minY, cropW, cropH);
    // GifEncoder espera centesimas de segundo.
    encoder.addFrame(frame, duration: durations[i] ~/ 10);
  }

  final bytes = encoder.finish();
  if (bytes == null) {
    stderr.writeln('El codificador no devolvio datos.');
    exitCode = 1;
    return;
  }

  final target = File(output)..parent.createSync(recursive: true);
  target.writeAsBytesSync(bytes);
  stdout.writeln('Salida: $output - ${frames.length} fotogramas, '
      '${(bytes.length / 1024).toStringAsFixed(0)} KB '
      '(antes ${(source.lengthSync() / 1024).toStringAsFixed(0)} KB)');
}

int? _intFlag(List<String> args, String name) {
  final match = args.firstWhere((a) => a.startsWith('$name='), orElse: () => '');
  if (match.isEmpty) return null;
  return int.tryParse(match.split('=')[1]);
}

/// `1` en cada pixel de fondo: blanco alcanzable desde el borde del fotograma.
Uint8List _backgroundMask(img.Image frame) {
  final w = frame.width;
  final h = frame.height;
  final mask = Uint8List(w * h);
  final stack = <int>[];

  void seed(int x, int y) {
    final i = y * w + x;
    if (mask[i] == 1) return;
    final p = frame.getPixel(x, y);
    if (!_isBackground(p.r, p.g, p.b, _minChannel, _maxSpread)) return;
    mask[i] = 1;
    stack.add(i);
  }

  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }

  while (stack.isNotEmpty) {
    final i = stack.removeLast();
    final x = i % w;
    final y = i ~/ w;
    if (x > 0) seed(x - 1, y);
    if (x < w - 1) seed(x + 1, y);
    if (y > 0) seed(x, y - 1);
    if (y < h - 1) seed(x, y + 1);
  }

  return mask;
}

bool _isBackground(num r, num g, num b, int minChannel, int maxSpread) {
  if (r < minChannel || g < minChannel || b < minChannel) return false;
  final max = r > g ? (r > b ? r : b) : (g > b ? g : b);
  final min = r < g ? (r < b ? r : b) : (g < b ? g : b);
  return max - min <= maxSpread;
}

/// Marca como fondo las islas opacas diminutas que deja el tramado del GIF.
void _removeSpeckles(Uint8List mask, int w, int h) {
  final visited = Uint8List(w * h);
  final island = <int>[];
  final stack = <int>[];

  for (var start = 0; start < mask.length; start++) {
    if (mask[start] == 1 || visited[start] == 1) continue;
    island.clear();
    stack
      ..clear()
      ..add(start);
    visited[start] = 1;

    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      island.add(i);
      final x = i % w;
      final y = i ~/ w;
      // Vecindad de 8: dos pixeles unidos en diagonal son la misma isla.
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final nx = x + dx;
          final ny = y + dy;
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final n = ny * w + nx;
          if (mask[n] == 1 || visited[n] == 1) continue;
          visited[n] = 1;
          stack.add(n);
        }
      }
    }

    if (island.length < _minIslandArea) {
      for (final i in island) {
        mask[i] = 1;
      }
    }
  }
}

/// Come el halo casi blanco que el antialias dejo pegado al fondo. El GIF solo
/// admite transparencia binaria, asi que ese borde no se puede difuminar: o se
/// recorta o se ve como un contorno claro sobre el color de la pantalla.
void _trimFringe(img.Image frame, Uint8List mask) {
  final w = frame.width;
  final h = frame.height;
  final doomed = <int>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (mask[i] == 1) continue;
      final touchesBackground = (x > 0 && mask[i - 1] == 1) ||
          (x < w - 1 && mask[i + 1] == 1) ||
          (y > 0 && mask[i - w] == 1) ||
          (y < h - 1 && mask[i + w] == 1);
      if (!touchesBackground) continue;
      final p = frame.getPixel(x, y);
      if (_isBackground(p.r, p.g, p.b, _fringeChannel, _fringeSpread)) {
        doomed.add(i);
      }
    }
  }
  for (final i in doomed) {
    mask[i] = 1;
  }
}

/// Recorta el fotograma y le construye una paleta nueva cuyo indice 0 es
/// transparente; el resto son los colores que el fotograma ya usaba.
img.Image _cutOut(
  img.Image frame,
  Uint8List mask,
  int offsetX,
  int offsetY,
  int width,
  int height,
) {
  final indices = Uint8List(width * height);
  final img.Palette palette;

  if (frame.hasPalette) {
    // El fotograma ya esta indexado: se reaprovechan sus colores tal cual, sin
    // recuantizar, y solo se reordenan para dejar libre el indice 0.
    final remap = <int, int>{};
    final colors = <List<int>>[];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final sx = x + offsetX;
        final sy = y + offsetY;
        if (mask[sy * frame.width + sx] == 1) continue; // 0 = transparente
        final pixel = frame.getPixel(sx, sy);
        final key = pixel.index.toInt();
        var index = remap[key];
        if (index == null) {
          colors.add([pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
          index = colors.length; // el 0 queda para el transparente
          remap[key] = index;
        }
        indices[y * width + x] = index;
      }
    }
    final built = img.PaletteUint8(colors.length + 1, 4);
    built.setRgba(0, 0, 0, 0, 0);
    for (var i = 0; i < colors.length; i++) {
      built.setRgba(i + 1, colors[i][0], colors[i][1], colors[i][2], 255);
    }
    palette = built;
  } else {
    // Tras reescalar ya no hay paleta: se recuantiza a 255 colores (el 0 sigue
    // reservado para el transparente).
    final visible = img.Image(width: width, height: height, numChannels: 3);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final p = frame.getPixel(x + offsetX, y + offsetY);
        visible.setPixelRgb(x, y, p.r, p.g, p.b);
      }
    }
    final quantizer = img.OctreeQuantizer(visible, numberOfColors: 255);
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final sx = x + offsetX;
        final sy = y + offsetY;
        if (mask[sy * frame.width + sx] == 1) continue;
        final p = frame.getPixel(sx, sy);
        indices[y * width + x] =
            quantizer.getColorIndexRgb(p.r.toInt(), p.g.toInt(), p.b.toInt()) + 1;
      }
    }
    final source = quantizer.palette;
    final built = img.PaletteUint8(source.numColors + 1, 4);
    built.setRgba(0, 0, 0, 0, 0);
    for (var i = 0; i < source.numColors; i++) {
      built.setRgba(i + 1, source.getRed(i).toInt(), source.getGreen(i).toInt(),
          source.getBlue(i).toInt(), 255);
    }
    palette = built;
  }

  final out = img.Image(
    width: width,
    height: height,
    numChannels: 1,
    withPalette: true,
    palette: palette,
  );
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      out.setPixelIndex(x, y, indices[y * width + x]);
    }
  }
  return out;
}
