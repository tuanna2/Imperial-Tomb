import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:imperial_tomb/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetController.hitTestWarningShouldBeFatal = true;
  testWidgets(
    'phone game opens a closeup and returns without obstructing art',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(ImperialTombApp(prefs: prefs));
      expect(find.text('IMPERIAL\nTOMB'), findsOneWidget);
      await tester.tap(find.text('BẮT ĐẦU KHÁM PHÁ'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hotspot-stele')));
      await tester.pumpAndSettle();
      expect(find.text('TIỀN ĐIỆN / CẬN CẢNH'), findsOneWidget);
      expect(find.text('Mặt Trời'), findsOneWidget);
      await tester.tap(find.byTooltip('Trở lại phòng'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('hotspot-lantern')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-oil_lamp')), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(prefs.getString(saveKey), contains('oil_lamp'));
    },
  );
  testWidgets('small and landscape displays remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(640, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ImperialTombApp(prefs: await SharedPreferences.getInstance()),
    );
    await tester.ensureVisible(find.text('BẮT ĐẦU KHÁM PHÁ'));
    await tester.tap(find.text('BẮT ĐẦU KHÁM PHÁ'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('hotspot-glyph_lock')));
    await tester.pumpAndSettle();
    expect(find.text('TIỀN ĐIỆN / CẬN CẢNH'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
