import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../game/content.dart';
import '../game/game_session.dart';

const brass = Color(0xFFC8AE7D);
const paper = Color(0xFFE6DBC7);
const night = Color(0xFF161A18);

/// A single 2:3 art coordinate system is used by artwork, hotspots and zoom crops.
class RoomArtwork extends StatelessWidget {
  const RoomArtwork({super.key, required this.scene, this.focus, this.game});
  final TombScene scene;
  final TombHotspot? focus;
  final GameSession? game;
  String get asset {
    if (scene.asset == 'vestibule' && (game?.has('oil_lamp') ?? false)) {
      return 'vestibule_taken';
    }
    if (scene.asset == 'archive' && (game?.did('chest_solved') ?? false)) {
      return 'archive_open';
    }
    if (scene.asset == 'observatory' &&
        ((game?.did('mirror_taken') ?? false) ||
            (game?.did('mirror_installed') ?? false))) {
      return 'observatory_taken';
    }
    if (scene.asset == 'courtyard' &&
        ((game?.has('hooked_rope') ?? false) ||
            (game?.did('well_retrieved') ?? false))) {
      return 'courtyard_taken';
    }
    if (scene.asset == 'floodgate' && (game?.did('valve_diverted') ?? false)) {
      return 'floodgate_safe';
    }
    return scene.asset;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, bounds) {
          final detail = switch (focus?.id) {
            'glyph_lock' => 'closeup_glyph',
            'well' when !(game?.did('well_retrieved') ?? false) =>
              'closeup_well',
            'pump' when game?.did('pump_open') ?? false => 'closeup_pump',
            _ => null,
          };
          if (detail != null) {
            return Image.asset('assets/rooms/$detail.webp',
                fit: BoxFit.cover,
                gaplessPlayback: true,
                filterQuality: FilterQuality.high,
                excludeFromSemantics: true);
          }

          final zoom = focus == null ? 1.0 : 2.35;
          final w = focus == null
              ? bounds.maxWidth
              : math.max(bounds.maxWidth * zoom, bounds.maxHeight / 1.5);
          final h = focus == null ? bounds.maxHeight : w * 1.5;
          final left = focus == null
              ? 0.0
              : (bounds.maxWidth / 2 - focus!.x * w).clamp(
                  bounds.maxWidth - w,
                  0.0,
                );
          final top = focus == null
              ? 0.0
              : (bounds.maxHeight / 2 - focus!.y * h).clamp(
                  bounds.maxHeight - h,
                  0.0,
                );
          return ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: left,
                  top: top,
                  width: w,
                  height: h,
                  child: Image.asset(
                    'assets/rooms/$asset.webp',
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.high,
                    excludeFromSemantics: true,
                  ),
                ),
                if (game != null &&
                    scene.asset == 'observatory' &&
                    game!.did('mirror_aligned'))
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                            colors: [
                              Colors.transparent,
                              brass.withAlpha(30),
                              Colors.transparent,
                            ],
                            stops: const [.2, .4, .6],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
}

/// Exact puzzle markings live in code, independent of decorative image details.
class RingPainter extends CustomPainter {
  const RingPainter(this.values, {this.segments = 8});
  final List<int> values;
  final int segments;
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    for (var i = 0; i < 3; i++) {
      final radius = math.min(s.width, s.height) * (.44 - i * .115);
      c.drawCircle(
        center,
        radius,
        Paint()
          ..color = const Color(0xFF73634A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15,
      );
      c.drawCircle(
        center,
        radius + 8,
        Paint()
          ..color = brass.withAlpha(180)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
      for (var j = 0; j < segments; j++) {
        final angle = j * math.pi * 2 / segments - math.pi / 2;
        final a =
            center + Offset(math.cos(angle), math.sin(angle)) * (radius - 5);
        final b =
            center + Offset(math.cos(angle), math.sin(angle)) * (radius + 5);
        c.drawLine(
          a,
          b,
          Paint()
            ..color = paper.withAlpha(150)
            ..strokeWidth = j == 0 ? 3 : 1,
        );
      }
      final angle = values[i] * math.pi * 2 / segments - math.pi / 2;
      final p = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      c.drawCircle(p, 7, Paint()..color = paper);
      c.drawCircle(p, 3, Paint()..color = night);
    }
    c.drawCircle(center, 8, Paint()..color = brass);
  }

  @override
  bool shouldRepaint(covariant RingPainter old) =>
      old.values.toString() != values.toString();
}

class PipePainter extends CustomPainter {
  const PipePainter(this.mask, {this.connected = false});
  final int mask;
  final bool connected;
  @override
  void paint(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height / 2);
    final ends = [
      Offset(s.width / 2, 0),
      Offset(s.width, s.height / 2),
      Offset(s.width / 2, s.height),
      Offset(0, s.height / 2),
    ];
    for (var d = 0; d < 4; d++) {
      if (mask & (1 << d) == 0) continue;
      c.drawLine(
        center,
        ends[d],
        Paint()
          ..color = const Color(0xFF090D0D)
          ..strokeWidth = 26,
      );
      c.drawLine(
        center,
        ends[d],
        Paint()
          ..color = brass
          ..strokeWidth = 21,
      );
      c.drawLine(
        center,
        ends[d],
        Paint()
          ..color =
              connected ? const Color(0xFF8DB8AE) : const Color(0xFF514D41)
          ..strokeWidth = 11,
      );
    }
    c.drawCircle(
      center,
      8,
      Paint()
        ..color = connected ? const Color(0xFF8DB8AE) : const Color(0xFF514D41),
    );
    for (final p in [const Offset(7, 7), Offset(s.width - 7, s.height - 7)]) {
      c.drawCircle(p, 2, Paint()..color = brass.withAlpha(90));
    }
  }

  @override
  bool shouldRepaint(covariant PipePainter old) =>
      old.mask != mask || old.connected != connected;
}
