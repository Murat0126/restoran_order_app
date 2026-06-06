import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:qr/qr.dart';

/// Рендерит QR-код с указанной полезной нагрузкой в PNG-байты.
///
/// * [data] — текст/URL, который зашифровывается.
/// * [size] — желаемый размер итогового PNG (пиксели). Реальный размер
///   может быть чуть меньше, потому что подгоняется под целое число
///   пикселей на модуль.
/// * [margin] — белые поля (quiet zone) с каждой стороны.
/// * [errorCorrection] — уровень коррекции ошибок. По умолчанию `M`
///   (~15% избыточности) — хороший баланс для печатных стикеров.
Uint8List renderQrPng({
  required String data,
  int size = 512,
  int margin = 32,
  int errorCorrection = QrErrorCorrectLevel.M,
}) {
  final qr = QrCode.fromData(
    data: data,
    errorCorrectLevel: errorCorrection,
  );
  final qrImage = QrImage(qr);
  final moduleCount = qrImage.moduleCount;

  // Сколько пикселей займёт один модуль. Минимум 1.
  final available = size - 2 * margin;
  final pxPerModule = (available ~/ moduleCount).clamp(1, 1000);
  final actualSize = pxPerModule * moduleCount + 2 * margin;

  final image = img.Image(width: actualSize, height: actualSize);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));

  final black = img.ColorRgb8(0, 0, 0);
  for (var y = 0; y < moduleCount; y++) {
    for (var x = 0; x < moduleCount; x++) {
      if (!qrImage.isDark(y, x)) continue;
      img.fillRect(
        image,
        x1: margin + x * pxPerModule,
        y1: margin + y * pxPerModule,
        x2: margin + (x + 1) * pxPerModule - 1,
        y2: margin + (y + 1) * pxPerModule - 1,
        color: black,
      );
    }
  }

  return Uint8List.fromList(img.encodePng(image));
}
