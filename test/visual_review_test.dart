// Optional review: flutter test test/visual_review_test.dart --dart-define=CAPTURE_UI=true
// Loads the same bundled fonts and icons used on devices.
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imperial_tomb/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('capture real Flutter room and closeup frames', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fonts = {
      'TombSans': 'assets/fonts/Roboto-Regular.ttf',
      'TombSerif': 'assets/fonts/DejaVuSerif.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    };
    for (final entry in fonts.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(rootBundle.load(entry.value));
      await loader.load();
    }
    SharedPreferences.setMockInitialValues({});
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: ImperialTombApp(prefs: await SharedPreferences.getInstance())));
    Future<void> capture(String name) async {
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/ui-review')..createSync(recursive: true);
        File('${dir.path}/$name.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await capture('01-menu');
    await tester.tap(find.text('BẮT ĐẦU KHÁM PHÁ'));
    await tester.pumpAndSettle();
    await capture('02-room');
    await tester.tap(find.byKey(const ValueKey('hotspot-glyph_lock')));
    await tester.pumpAndSettle();
    await capture('03-closeup');
    await tester.tap(find.byTooltip('Trở lại phòng'));
    tester.view.physicalSize = const Size(640, 360);
    await tester.pumpAndSettle();
    await capture('04-landscape');
    expect(tester.takeException(), isNull);
  }, skip: !const bool.fromEnvironment('CAPTURE_UI'));
}
