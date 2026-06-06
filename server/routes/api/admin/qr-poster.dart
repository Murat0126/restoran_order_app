import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

import 'package:restaurant_server/src/app_context.dart';

/// `GET /api/admin/qr-poster?base=<optional>`
///
/// Печатная страница со всеми QR-кодами столиков, сгруппированными
/// по залам. Админ открывает в браузере, нажимает Ctrl+P и печатает
/// стикеры. На А4 при крупной сетке помещается 6–9 QR.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response.json(
      statusCode: 405,
      body: {'error': 'Method not allowed'},
    );
  }

  final ctx = AppContext.instance;
  final halls = ctx.tables.allHalls();
  final tables = ctx.tables.all();
  final tablesByHall = <String, List<RestaurantTable>>{
    for (final h in halls)
      h.id: tables.where((t) => t.hallId == h.id).toList(),
  };

  final base = context.request.uri.queryParameters['base']?.trim() ?? '';
  final baseSuffix = base.isEmpty ? '' : '&base=${Uri.encodeQueryComponent(base)}';

  final buf = StringBuffer()
    ..writeln('<!DOCTYPE html>')
    ..writeln('<html lang="ru"><head>')
    ..writeln('<meta charset="utf-8">')
    ..writeln('<title>QR-стикеры столиков</title>')
    ..writeln('<style>$_css</style>')
    ..writeln('</head><body>')
    ..writeln('<div class="toolbar">')
    ..writeln('<h1>QR-меню для столиков</h1>')
    ..writeln(
      '<p>Чтобы скачать всё одним PDF — Ctrl+P → «Сохранить как PDF».</p>',
    )
    ..writeln(
      '<p class="hint">URL на QR-кодах строится из текущего адреса. '
      'Если нужно перегенерировать под другой публичный адрес — '
      'откройте страницу так: '
      '<code>?base=https://menu.example.com</code></p>',
    )
    ..writeln('</div>');

  for (final hall in halls) {
    final hallTables = tablesByHall[hall.id] ?? const [];
    if (hallTables.isEmpty) continue;
    buf
      ..writeln('<section class="hall">')
      ..writeln('<h2>${_escape(hall.name)}</h2>')
      ..writeln('<div class="grid">');
    for (final t in hallTables) {
      final token = t.qrToken;
      if (token == null || token.isEmpty) continue;
      final imgSrc = '/api/qr/$token.png?size=600$baseSuffix';
      buf
        ..writeln('<div class="card">')
        ..writeln('<div class="num">Стол ${_escape(t.number)}</div>')
        ..writeln('<img alt="QR стол ${_escape(t.number)}" src="$imgSrc">')
        ..writeln('<div class="hint">Сканируйте, чтобы открыть меню</div>')
        ..writeln('</div>');
    }
    buf
      ..writeln('</div>')
      ..writeln('</section>');
  }

  buf.writeln('</body></html>');

  return Response(
    body: buf.toString(),
    headers: const {
      'Content-Type': 'text/html; charset=utf-8',
      'Cache-Control': 'no-store',
    },
  );
}

String _escape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

const _css = '''
  * { box-sizing: border-box; }
  body { font-family: system-ui, -apple-system, "Segoe UI", Roboto, sans-serif;
         margin: 24px; color: #1d1d1f; }
  h1 { margin: 0 0 8px; }
  h2 { margin: 28px 0 12px; }
  .toolbar { margin-bottom: 24px; }
  .toolbar p { margin: 4px 0; color: #555; }
  .hint { color: #777; font-size: 13px; }
  .grid {
    display: grid;
    grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
    gap: 16px;
  }
  .card {
    border: 1px solid #ddd;
    border-radius: 12px;
    padding: 16px;
    text-align: center;
    background: #fff;
    break-inside: avoid;
    page-break-inside: avoid;
  }
  .card img { width: 100%; height: auto; display: block; margin: 8px 0; }
  .num { font-size: 18px; font-weight: 600; }
  code { background: #f3f3f3; padding: 2px 6px; border-radius: 4px; }
  @media print {
    .toolbar p, .toolbar .hint { display: none; }
    .card { border-color: #999; }
    @page { margin: 1cm; }
  }
''';
