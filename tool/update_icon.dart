// Makes the app's launcher icon from the logo an administrator uploaded in the church website Settings.
//
// Usage (from the project folder):
//   dart run tool/update_icon.dart
//   dart run tool/update_icon.dart --api https://example.org/api/member/
//   dart run tool/update_icon.dart --logo path/or/url/to/logo.png   (skip the website lookup)
//   dart run tool/update_icon.dart --no-generate                    (only write the PNGs)
//
// It writes assets/icons/logo.png (full icon) and assets/icons/logo_foreground.png (Android adaptive
// icon, padded so the round mask does not crop the logo), then runs flutter_launcher_icons.
// Rebuild and release the app afterwards: phones only get a new icon with an app update.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

const _defaultApi = 'https://pentacostal.kemmytech.com/api/member/';
const _size = 1024;

/// Share of the canvas the logo fills in each icon. Android shows only the middle ~61% of an
/// adaptive icon's foreground, so that one gets more padding.
const _fullScale = 0.86;
const _foregroundScale = 0.60;

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf(name);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln('dart run tool/update_icon.dart [--api <member api url>] [--logo <file or url>] [--no-generate]');
    return;
  }

  try {
    final source = option('--logo') ?? await _logoUrlFromWebsite(option('--api') ?? _defaultApi);
    stdout.writeln('Logo: $source');
    final logo = img.decodeImage(await _readBytes(source));
    if (logo == null) _fail('Could not read the logo as an image (use PNG or JPG).');

    _checkLogo(logo);
    final trimmed = _trimTransparent(logo);

    File('assets/icons/logo.png').writeAsBytesSync(img.encodePng(_squareIcon(trimmed, _fullScale)));
    File('assets/icons/logo_foreground.png').writeAsBytesSync(img.encodePng(_squareIcon(trimmed, _foregroundScale)));
    stdout.writeln('Wrote assets/icons/logo.png and assets/icons/logo_foreground.png ($_size x $_size).');

    if (args.contains('--no-generate')) return;
    stdout.writeln('Generating launcher icons...');
    final result = await Process.run('dart', ['run', 'flutter_launcher_icons'], runInShell: true);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) _fail('flutter_launcher_icons failed (exit ${result.exitCode}).');
    stdout.writeln('Done. Rebuild the app (flutter build apk / appbundle / ipa) to ship the new icon.');
  } on _Failure catch (e) {
    stderr.writeln('Error: ${e.message}');
    exitCode = 1;
  }
}

/// Asks the member API's public branding endpoint for the uploaded logo's address.
Future<String> _logoUrlFromWebsite(String api) async {
  final base = Uri.parse(api);
  final uri = base.replace(queryParameters: {...base.queryParameters, 'action': 'branding'});
  final response = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 30));
  final Object? body;
  try {
    body = jsonDecode(response.body);
  } on FormatException {
    _fail('The website did not return branding data (HTTP ${response.statusCode}).');
  }
  final church = body is Map ? body['church'] : null;
  final url = church is Map ? '${church['logo_url'] ?? ''}'.trim() : '';
  if (url.isEmpty) _fail('No logo has been uploaded in the website Settings yet.');
  return url;
}

Future<Uint8List> _readBytes(String source) async {
  if (source.startsWith('http://') || source.startsWith('https://')) {
    final response = await http.get(Uri.parse(source)).timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) _fail('Could not download the logo (HTTP ${response.statusCode}).');
    return response.bodyBytes;
  }
  final file = File(source);
  if (!file.existsSync()) _fail('Logo file not found: $source');
  return file.readAsBytesSync();
}

/// Warns about logos that will look poor as an app icon; they are still used.
void _checkLogo(img.Image logo) {
  final w = logo.width, h = logo.height;
  stdout.writeln('Logo size: $w x $h');
  if (w < 512 || h < 512) {
    stdout.writeln('Warning: the logo is small and may look blurry. Upload one at least 1024 x 1024.');
  }
  final ratio = w / h;
  if (ratio > 1.25 || ratio < 0.8) {
    stdout.writeln('Warning: the logo is not square, so it will look small on the icon. A square logo works best.');
  }
}

/// Cuts away fully transparent borders so the logo fills the icon evenly.
img.Image _trimTransparent(img.Image logo) {
  if (!logo.hasAlpha) return logo;
  var left = logo.width, top = logo.height, right = -1, bottom = -1;
  for (final p in logo) {
    if (p.a > 8) {
      if (p.x < left) left = p.x;
      if (p.x > right) right = p.x;
      if (p.y < top) top = p.y;
      if (p.y > bottom) bottom = p.y;
    }
  }
  if (right < 0) _fail('The logo is completely transparent.');
  return img.copyCrop(logo, x: left, y: top, width: right - left + 1, height: bottom - top + 1);
}

/// The logo centred on a transparent square canvas, filling [scale] of it.
img.Image _squareIcon(img.Image logo, double scale) {
  final target = (_size * scale).round();
  final resized = logo.width >= logo.height
      ? img.copyResize(logo, width: target, interpolation: img.Interpolation.cubic)
      : img.copyResize(logo, height: target, interpolation: img.Interpolation.cubic);
  final canvas = img.Image(width: _size, height: _size, numChannels: 4);
  img.compositeImage(canvas, resized.convert(numChannels: 4),
      dstX: (_size - resized.width) ~/ 2, dstY: (_size - resized.height) ~/ 2);
  return canvas;
}

class _Failure implements Exception {
  _Failure(this.message);
  final String message;
}

Never _fail(String message) => throw _Failure(message);
