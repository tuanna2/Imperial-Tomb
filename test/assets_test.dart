import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('every room, state and detail image is bundled and decodable', () async {
    for (final name in [
      'vestibule',
      'vestibule_taken',
      'archive',
      'archive_open',
      'courtyard',
      'courtyard_taken',
      'observatory',
      'observatory_taken',
      'workshop',
      'floodgate',
      'floodgate_safe',
      'closeup_glyph',
      'closeup_well',
      'closeup_pump',
    ]) {
      final bytes = await rootBundle.load('assets/rooms/$name.webp');
      expect(bytes.lengthInBytes, greaterThan(1000), reason: name);
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      expect(frame.image.width, greaterThanOrEqualTo(1024), reason: name);
      expect(frame.image.height, greaterThanOrEqualTo(1024), reason: name);
      frame.image.dispose();
      codec.dispose();
    }
  });
}
