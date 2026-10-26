import 'package:flutter_test/flutter_test.dart';
import 'package:imperial_tomb/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('game menu renders and starts a new adventure', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ImperialTombApp(prefs: prefs));
    expect(find.text('IMPERIAL\nTOMB'), findsOneWidget);
    await tester.tap(find.text('BẮT ĐẦU KHÁM PHÁ'));
    await tester.pumpAndSettle();
    expect(find.text('TIỀN ĐIỆN'), findsWidgets);
    expect(find.text('Bia đá'), findsOneWidget);
  });
}
