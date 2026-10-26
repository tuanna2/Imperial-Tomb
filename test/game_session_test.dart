import 'package:flutter_test/flutter_test.dart';
import 'package:imperial_tomb/game/game_session.dart';

void main() {
  group('Imperial Tomb puzzle logic', () {
    test('symbols require exact order and award the bronze stylus', () {
      final game = GameSession();
      expect(game.solveGlyphs(['moon', 'mountain', 'sun']), isFalse);
      expect(game.has('bronze_stylus'), isFalse);
      expect(game.solveGlyphs(['sun', 'mountain', 'moon']), isTrue);
      expect(game.has('bronze_stylus'), isTrue);
      expect(game.solveGlyphs(['sun', 'mountain', 'moon']), isTrue);
      expect(game.journal.where((entry) => entry.contains('kim đồng')).length, 1);
    });

    test('ledger puzzle combines clues from two scenes', () {
      final game = GameSession();
      game.inspect('stele');
      game.inspect('ledger');
      expect(game.solveChest('124'), isFalse);
      expect(game.solveChest('421'), isTrue);
      expect(game.has('jade_seal'), isTrue);
      expect(game.has('decree'), isTrue);
      expect(game.navigate(3).message, contains('Thủy môn'));
    });

    test('third puzzle requires bronze stylus', () {
      final game = GameSession();
      expect(game.solveStars(['moon', 'river', 'sun']), isFalse);
      game.solveGlyphs(['sun', 'mountain', 'moon']);
      expect(game.solveStars(['moon', 'river', 'sun']), isTrue);
      expect(game.has('valve_wheel'), isTrue);
    });

    test('premature floodgate entry is blocked', () {
      final game = GameSession();
      game.navigate(3);
      expect(game.scene, 0);
    });

    test('opening main sluice causes bad ending', () {
      final game = GameSession();
      game.solveChest('421');
      game.navigate(3);
      expect(game.inspect('main_gate').ending, EndingType.bad);
    });

    test('leaving too early yields ordinary ending', () {
      final game = GameSession();
      game.solveChest('421');
      game.navigate(3);
      expect(game.inspect('service_exit').ending, EndingType.ordinary);
    });

    test('all necessary evidence and safe diversion unlock true ending', () {
      final game = GameSession();
      game.inspect('lantern');
      game.inspect('stele');
      game.solveGlyphs(['sun', 'mountain', 'moon']);
      game.inspect('ledger');
      game.solveChest('421');
      game.chooseItem('oil_lamp');
      game.inspect('dark_mural');
      game.chooseItem('bronze_stylus');
      game.inspect('alcove');
      game.solveStars(['moon', 'river', 'sun']);
      game.inspect('canal_map');
      game.navigate(3);
      game.chooseItem('valve_wheel');
      game.inspect('side_valve');
      expect(game.inspect('service_exit').ending, EndingType.trueEnding);
    });

    test('save round trip preserves scene, journal and inventory', () {
      final game = GameSession();
      game.solveGlyphs(['sun', 'mountain', 'moon']);
      game.solveChest('421');
      game.navigate(2);
      final restored = GameSession.deserialize(game.serialize());
      expect(restored.scene, 2);
      expect(restored.inventory, containsAll(['bronze_stylus', 'jade_seal']));
      expect(restored.flags, containsAll(['glyph_solved', 'chest_solved']));
    });
  });
}
