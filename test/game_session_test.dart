import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:imperial_tomb/game/game_session.dart';

void take(GameSession g, String id, [String? item]) {
  if (item != null) {
    g.selectedItem = null;
    g.chooseItem(item);
  }
  g.inspect(id);
}

void firstChapter(GameSession g) {
  take(g, 'lantern');
  take(g, 'stele');
  expect(g.solveGlyphs(GameSession.glyphAnswer), isTrue);
  g.navigate(1);
  take(g, 'supplies');
  take(g, 'ledger');
  expect(g.solveChest('421'), isTrue);
  take(g, 'dark_mural', 'brush');
  take(g, 'dark_mural', 'oil_lamp');
  take(g, 'alcove', 'bronze_stylus');
}

void wellChapter(GameSession g) {
  g.navigate(4);
  take(g, 'rope');
  take(g, 'lotus_relief');
  expect(g.solveLotus(GameSession.lotusAnswer), isTrue);
  g.combine('rope', 'hook');
  take(g, 'well', 'hooked_rope');
  g.combine('sealed_tin', 'bronze_stylus');
}

void machineryChapter(GameSession g) {
  g.navigate(5);
  take(g, 'engineer_plan');
  expect(g.solveBalance([2, 5, 3]), isTrue);
  take(g, 'pump', 'wrench');
  expect(g.solvePipes([0, 0, 2, 1, 0, 3]), isTrue);
}

void reflectionChapter(GameSession g) {
  g.navigate(2);
  take(g, 'mirror', 'bronze_stylus');
  g.combine('cloth', 'oil_lamp');
  g.combine('mirror_disk', 'oiled_cloth');
  take(g, 'mirror_stand', 'polished_mirror');
  expect(g.solveMirror([2, 4, 1]), isTrue);
  take(g, 'canal_map', 'rubbing_paper');
  take(g, 'orrery', 'bronze_stylus');
  expect(g.solveStars(GameSession.starsAnswer), isTrue);
}

GameSession preparedGame() {
  final g = GameSession();
  firstChapter(g);
  wellChapter(g);
  machineryChapter(g);
  reflectionChapter(g);
  return g;
}

void main() {
  test('room locks and action scope cannot be bypassed', () {
    final g = GameSession();
    for (final target in [2, 3, 5, -1, 6]) {
      g.navigate(target);
      expect(g.scene, 0);
    }
    expect(g.solveChest('421'), isFalse);
    expect(g.solveStars(GameSession.starsAnswer), isFalse);
    g.inspect('main_gate');
    expect(g.ending, isNull);
    g.inspect('supplies');
    expect(g.has('brush'), isFalse);
  });
  test('wrong answers do not grant rewards or erase clues', () {
    final g = GameSession();
    take(g, 'stele');
    expect(g.solveGlyphs(['moon', 'sun', 'mountain']), isFalse);
    expect(g.has('bronze_stylus'), isFalse);
    expect(g.did('stele_read'), isTrue);
    expect(g.solveGlyphs(GameSession.glyphAnswer), isTrue);
    final size = g.journal.length;
    expect(g.solveGlyphs(GameSession.glyphAnswer), isTrue);
    expect(g.journal.length, size);
  });
  test('mural requires cleaning and then directional light', () {
    final g = GameSession();
    firstChapter(g);
    expect(g.did('mural_clean'), isTrue);
    expect(g.did('mural_read'), isTrue);
    final fresh = GameSession()..navigate(1);
    fresh.inventory.add('oil_lamp');
    take(fresh, 'dark_mural', 'oil_lamp');
    expect(fresh.did('mural_read'), isFalse);
  });
  test('combinations consume parts once and keep reusable tools', () {
    final g = GameSession();
    firstChapter(g);
    wellChapter(g);
    expect(
      g.inventory,
      containsAll(['brass_key', 'cloth', 'bronze_stylus', 'oil_lamp']),
    );
    expect(g.inventory, isNot(contains('sealed_tin')));
    final items = Set.of(g.inventory), notes = g.journal.length;
    g.combine('sealed_tin', 'bronze_stylus');
    expect(g.inventory, items);
    expect(g.journal.length, notes);
    g.combine('brass_key', 'oil_lamp');
    expect(g.inventory, items);
    g.combine('cloth', 'oil_lamp');
    expect(g.has('oiled_cloth'), isTrue);
    expect(g.has('oil_lamp'), isTrue);
  });
  test('star machine requires installed axis, mirror and mural', () {
    final g = GameSession();
    firstChapter(g);
    g.navigate(2);
    expect(g.solveStars(GameSession.starsAnswer), isFalse);
    take(g, 'orrery', 'bronze_stylus');
    expect(g.did('star_axis'), isTrue);
    expect(g.solveStars(GameSession.starsAnswer), isFalse);
    wellChapter(g);
    machineryChapter(g);
    reflectionChapter(g);
    expect(g.has('wheel_core'), isTrue);
  });
  test('balance is derived from three independent constraints', () {
    final g = GameSession();
    firstChapter(g);
    wellChapter(g);
    g.navigate(5);
    expect(g.solveBalance([3, 5, 2]), isFalse);
    expect(g.solveBalance([2, 5, 3]), isTrue);
    expect(g.inventory, containsAll(['wrench', 'wheel_handle']));
  });
  test('pipes verify actual connectivity, boundaries and every segment', () {
    expect(GameSession.pipesConnected([0, 0, 2, 1, 0, 3]), isTrue);
    expect(GameSession.pipesConnected([0, 0, 2, 0, 0, 3]), isFalse);
    expect(GameSession.pipesConnected([1, 1, 0, 0, 1, 0]), isFalse);
    expect(GameSession.pipesConnected([0, 0, 2, 1, 0]), isFalse);
    expect(GameSession.pipesConnected([0, 0, 2, -1, 0, 3]), isFalse);
    final g = GameSession();
    firstChapter(g);
    wellChapter(g);
    g.navigate(5);
    expect(g.solvePipes([0, 0, 2, 1, 0, 3]), isFalse);
    machineryChapter(g);
    expect(g.canEnter(3), isTrue);
  });
  test('complete original play route gives true ending', () {
    final g = preparedGame();
    g.combine('wheel_core', 'wheel_handle');
    g.navigate(3);
    take(g, 'side_valve', 'valve_wheel');
    expect(g.has('valve_wheel'), isFalse);
    expect(g.did('wheel_installed'), isTrue);
    expect(g.solvePressure([1, 2, 3]), isFalse);
    expect(g.solvePressure([3, 1, 2]), isTrue);
    expect(g.inspect('service_exit').ending, EndingType.trueEnding);
  });
  test('escape without names is ordinary even with diverted water', () {
    final g = preparedGame();
    g.inventory.remove('village_rubbing');
    g.combine('wheel_core', 'wheel_handle');
    g.navigate(3);
    take(g, 'side_valve', 'valve_wheel');
    g.solvePressure([3, 1, 2]);
    expect(g.inspect('service_exit').ending, EndingType.ordinary);
  });
  test('opening sluice prematurely gives bad ending and freezes rules', () {
    final g = preparedGame();
    g.navigate(3);
    expect(g.inspect('main_gate').ending, EndingType.bad);
    final saved = g.serialize();
    g.navigate(0);
    g.solvePressure([3, 1, 2]);
    g.combine('wheel_core', 'wheel_handle');
    g.inspect('service_exit');
    expect(g.serialize(), saved);
  });
  test('save resumes partially adjusted machinery and installed items', () {
    final g = preparedGame();
    g.combine('wheel_core', 'wheel_handle');
    g.navigate(3);
    take(g, 'side_valve', 'valve_wheel');
    g.saveMechanism(PuzzleType.pressure, [3, 0, 2]);
    final restored = GameSession.deserialize(g.serialize());
    expect(restored.scene, 3);
    expect(restored.did('wheel_installed'), isTrue);
    expect(restored.mechanisms['pressure'], [3, 0, 2]);
    expect(restored.inventory, g.inventory);
    expect(restored.journal, g.journal);
    expect(restored.solvePressure([3, 1, 2]), isTrue);
  });
  test('v1 progress migrates without losing acquired evidence', () {
    final old = jsonEncode({
      'schema': 1,
      'scene': 2,
      'inventory': ['jade_seal', 'decree', 'valve_wheel'],
      'flags': ['stars_solved'],
      'journal': ['Ghi chép cũ'],
    });
    final g = GameSession.deserialize(old);
    expect(g.scene, 2);
    expect(g.did('mirror_aligned'), isTrue);
    expect(g.has('valve_wheel'), isTrue);
    expect(jsonDecode(g.serialize())['schema'], 2);
  });
  test(
    'invalid schema is rejected and malformed optional fields are ignored',
    () {
      expect(() => GameSession.deserialize('{bad'), throwsFormatException);
      expect(
        () => GameSession.deserialize('{"schema":99}'),
        throwsFormatException,
      );
      final g = GameSession.deserialize(
        '{"schema":2,"scene":500,"inventory":{},"flags":1,"mechanisms":{"mirror":["bad"]}}',
      );
      expect(g.scene, 0);
      expect(g.mechanisms, isEmpty);
    },
  );
}
