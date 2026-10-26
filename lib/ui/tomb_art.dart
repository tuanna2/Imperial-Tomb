import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Original vector-style concept art. Drawn at design coordinates 360x540;
/// it scales to any scene viewport without copyrighted external assets.
class TombArtPainter extends CustomPainter {
  const TombArtPainter(this.scene, {this.waterDiverted = false});

  final int scene;
  final bool waterDiverted;

  static const gold = Color(0xFFD1AE6E);
  static const stone = Color(0xFF4C5550);
  static const jade = Color(0xFF6C9E8D);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 360, size.height / 540);
    final full = Rect.fromLTWH(0, 0, 360, 540);

    canvas.drawRect(
      full,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF293932), Color(0xFF111C1F), Color(0xFF080F14)],
        ).createShader(full),
    );

    // Recessed vault, concentric arches and stone block courses.
    _arch(canvas, 20, 22, 320, 490, const Color(0xFF4B554C));
    _arch(canvas, 34, 41, 292, 455, const Color(0xFF303D39));
    _arch(canvas, 50, 62, 260, 414, const Color(0xFF17252A));
    _archOutline(canvas, 29, 30, 302, 473, gold.withAlpha(100), 1.4);
    _archOutline(canvas, 57, 70, 246, 404, gold.withAlpha(50), 1);

    for (var y = 130.0; y < 480; y += 39) {
      _line(canvas, Offset(20, y), Offset(340, y), const Color(0xFF68736A).withAlpha(30));
      for (var i = 0; i < 7; i++) {
        final x = (i * 53 + ((y.toInt() ~/ 39) % 2) * 25).toDouble();
        _line(canvas, Offset(x, y), Offset(x, y + 38), const Color(0xFF7C8676).withAlpha(19));
      }
    }

    final ground = Path()
      ..moveTo(0, 445)
      ..lineTo(360, 445)
      ..lineTo(360, 540)
      ..lineTo(0, 540)
      ..close();
    canvas.drawPath(ground, Paint()..color = const Color(0xFF1C282A));
    for (var x = -50.0; x < 410; x += 70) {
      _line(canvas, Offset(180, 442), Offset(x, 540), gold.withAlpha(23));
    }
    _line(canvas, const Offset(0, 480), const Offset(360, 480), gold.withAlpha(28));

    // Soft dust motes and light from above.
    for (var i = 0; i < 34; i++) {
      final dx = (i * 79 + 21) % 340 + 10.0;
      final dy = (i * 113 + 53) % 495 + 8.0;
      _disc(canvas, dx, dy, i % 4 == 0 ? 1.5 : .75, gold.withAlpha(i % 3 == 0 ? 68 : 22));
    }
    final halo = Rect.fromCircle(center: const Offset(180, 190), radius: 205);
    canvas.drawCircle(
      const Offset(180, 190),
      205,
      Paint()
        ..shader = RadialGradient(
          colors: [gold.withAlpha(30), Colors.transparent],
        ).createShader(halo),
    );

    switch (scene) {
      case 0:
        _vestibule(canvas);
      case 1:
        _archive(canvas);
      case 2:
        _observatory(canvas);
      case 3:
        _floodgate(canvas);
    }

    final vignette = Paint()
      ..shader = RadialGradient(
        radius: .8,
        colors: [Colors.transparent, const Color(0xFF030809).withAlpha(170)],
        stops: const [.43, 1],
      ).createShader(full);
    canvas.drawRect(full, vignette);
    canvas.restore();
  }

  void _vestibule(Canvas c) {
    _stonePanel(c, const Rect.fromLTWH(53, 118, 103, 182), const Color(0xFF48554C));
    _line(c, const Offset(67, 149), const Offset(143, 149), gold.withAlpha(190), 2);
    _symbol(c, 'sun', const Offset(86, 187), 13, gold);
    _symbol(c, 'mountain', const Offset(124, 215), 12, gold);
    _symbol(c, 'moon', const Offset(87, 243), 12, gold);
    _stonePanel(c, const Rect.fromLTWH(208, 309, 113, 99), const Color(0xFF5B5343));
    for (var i = 0; i < 3; i++) {
      final x = 228.0 + i * 36;
      _disc(c, x, 357, 16, const Color(0xFF1A2527));
      _ring(c, Offset(x, 357), 16, gold.withAlpha(170));
      _symbol(c, ['sun', 'mountain', 'moon'][i], Offset(x, 357), 9, gold);
    }
    _lamp(c, 87, 380);
    _line(c, const Offset(67, 420), const Offset(142, 420), gold.withAlpha(70), 3);
    _door(c, const Rect.fromLTWH(171, 122, 141, 178), const Color(0xFF16252A));
    _symbol(c, 'river', const Offset(246, 200), 27, gold.withAlpha(140));
  }

  void _archive(Canvas c) {
    for (final x in [54.0, 270.0]) {
      _stonePanel(c, Rect.fromLTWH(x, 136, 44, 284), const Color(0xFF3D4038));
      for (var i = 0; i < 5; i++) {
        _line(c, Offset(x + 5, 166 + i * 49), Offset(x + 39, 166 + i * 49), gold.withAlpha(80), 4);
        for (var j = 0; j < 4; j++) {
          _fill(c, Rect.fromLTWH(x + 7 + j * 8, 139 + i * 49, 6, 25),
              Color.lerp(const Color(0xFF7A6344), const Color(0xFF243F37), j / 4)!);
        }
      }
    }
    _stonePanel(c, const Rect.fromLTWH(119, 110, 144, 152), const Color(0xFF303B36));
    _symbol(c, 'moon', const Offset(165, 157), 22, jade.withAlpha(175));
    _symbol(c, 'river', const Offset(215, 182), 20, jade.withAlpha(175));
    _symbol(c, 'sun', const Offset(169, 222), 18, jade.withAlpha(175));
    _stonePanel(c, const Rect.fromLTWH(50, 282, 112, 62), const Color(0xFF827258));
    for (var i = 0; i < 4; i++) {
      _line(c, Offset(62, 297 + i * 10), Offset(149, 297 + i * 10), const Color(0xFF253330), 1.7);
    }
    _stonePanel(c, const Rect.fromLTWH(262, 275, 68, 100), const Color(0xFF182323));
    _line(c, const Offset(281, 304), const Offset(314, 305), gold.withAlpha(140), 1.5);
    _stonePanel(c, const Rect.fromLTWH(169, 400, 131, 82), const Color(0xFF5E4639));
    _line(c, const Offset(169, 433), const Offset(300, 433), gold, 2);
    for (var i = 0; i < 3; i++) {
      _disc(c, 217 + i * 20, 430, 5, gold);
    }
  }

  void _observatory(Canvas c) {
    _stonePanel(c, const Rect.fromLTWH(43, 130, 110, 143), const Color(0xFF3B4A47));
    final path = Path()
      ..moveTo(60, 242)
      ..quadraticBezierTo(94, 203, 73, 175)
      ..quadraticBezierTo(111, 194, 137, 155);
    c.drawPath(path, Paint()..color = jade..style = PaintingStyle.stroke..strokeWidth = 5);
    _symbol(c, 'mountain', const Offset(104, 154), 13, gold);
    _ring(c, const Offset(275, 182), 51, gold.withAlpha(120), 2);
    _disc(c, 275, 182, 40, const Color(0xFF19282D));
    _symbol(c, 'moon', const Offset(267, 175), 29, jade);
    _stonePanel(c, const Rect.fromLTWH(122, 400, 124, 73), const Color(0xFF494C43));
    _disc(c, 184, 339, 104, const Color(0xFF273B3D));
    for (var r in [84.0, 61.0, 39.0]) {
      _ring(c, const Offset(184, 339), r, gold.withAlpha(175), 3);
    }
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      final px = 184 + math.cos(a) * 71;
      final py = 339 + math.sin(a) * 71;
      _disc(c, px, py, 3.2, gold);
    }
    _symbol(c, 'moon', const Offset(160, 319), 16, gold);
    _symbol(c, 'river', const Offset(206, 320), 16, jade);
    _symbol(c, 'sun', const Offset(183, 374), 15, gold);
    _disc(c, 184, 339, 6, gold);
  }

  void _floodgate(Canvas c) {
    final water = waterDiverted ? jade.withAlpha(66) : const Color(0xFF356879).withAlpha(150);
    for (var i = 0; i < 8; i++) {
      final y = 360.0 + i * 19;
      final path = Path()..moveTo(0, y);
      for (var x = 0.0; x <= 360; x += 15) {
        path.lineTo(x, y + math.sin(x / 24 + i) * 7);
      }
      c.drawPath(path, Paint()..color = water..strokeWidth = 5..style = PaintingStyle.stroke);
    }
    _door(c, const Rect.fromLTWH(117, 109, 145, 315), const Color(0xFF10252C));
    for (var y = 157.0; y <= 378; y += 35) {
      _line(c, Offset(143, y), Offset(235, y), gold.withAlpha(80), 3);
    }
    _disc(c, 186, 273, 28, const Color(0xFF3A453F));
    _ring(c, const Offset(186, 273), 29, gold);
    _symbol(c, 'river', const Offset(186, 273), 16, gold);
    _stonePanel(c, const Rect.fromLTWH(44, 121, 75, 136), const Color(0xFF4A5048));
    _line(c, const Offset(57, 145), const Offset(106, 145), gold, 2);
    _symbol(c, 'sun', const Offset(80, 185), 18, gold);
    _disc(c, 77, 406, 41, const Color(0xFF364B48));
    _ring(c, const Offset(77, 406), 37, gold, 5);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      _line(c, const Offset(77, 406),
          Offset(77 + math.cos(a) * 36, 406 + math.sin(a) * 36), gold, 4);
    }
    _door(c, const Rect.fromLTWH(266, 303, 60, 147), const Color(0xFF1B403E));
    _line(c, const Offset(296, 321), const Offset(296, 429), jade, 2);
    _disc(c, 312, 391, 4, gold);
  }

  void _lamp(Canvas c, double x, double y) {
    _disc(c, x, y - 26, 32, gold.withAlpha(29));
    _disc(c, x, y - 26, 15, const Color(0xFFEDA95C).withAlpha(150));
    _line(c, Offset(x, y - 14), Offset(x, y + 15), gold, 5);
    _line(c, Offset(x - 15, y + 15), Offset(x + 15, y + 15), gold, 5);
  }

  void _door(Canvas c, Rect r, Color color) {
    _fill(c, r, color);
    c.drawRect(r, Paint()..color = gold.withAlpha(100)..style = PaintingStyle.stroke..strokeWidth = 3);
    _line(c, Offset(r.center.dx, r.top + 12), Offset(r.center.dx, r.bottom - 10),
        gold.withAlpha(70), 1.4);
    _disc(c, r.center.dx, r.center.dy, 7, gold.withAlpha(140));
  }

  void _symbol(Canvas c, String kind, Offset center, double radius, Color color) {
    if (kind == 'sun') {
      _ring(c, center, radius * .55, color, 2);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        _line(c, Offset(center.dx + math.cos(a) * radius * .72,
                center.dy + math.sin(a) * radius * .72),
            Offset(center.dx + math.cos(a) * radius * 1.07,
                center.dy + math.sin(a) * radius * 1.07), color, 2);
      }
    } else if (kind == 'mountain') {
      final p = Path()
        ..moveTo(center.dx - radius, center.dy + radius * .65)
        ..lineTo(center.dx - radius * .23, center.dy - radius)
        ..lineTo(center.dx + radius * .12, center.dy - radius * .15)
        ..lineTo(center.dx + radius * .45, center.dy - radius * .64)
        ..lineTo(center.dx + radius, center.dy + radius * .65);
      c.drawPath(p, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
    } else if (kind == 'moon') {
      _disc(c, center.dx, center.dy, radius * .75, color);
      _disc(c, center.dx + radius * .4, center.dy - radius * .24, radius * .69,
          const Color(0xFF20302F));
    } else {
      for (var i = -1; i <= 1; i++) {
        final p = Path()..moveTo(center.dx - radius, center.dy + i * radius * .45);
        p.quadraticBezierTo(center.dx - radius * .3, center.dy - radius * .3 + i * radius * .45,
            center.dx, center.dy + i * radius * .45);
        p.quadraticBezierTo(center.dx + radius * .5, center.dy + radius * .95 + i * radius * .45,
            center.dx + radius, center.dy + i * radius * .45);
        c.drawPath(p, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
      }
    }
  }

  void _arch(Canvas c, double x, double y, double w, double h, Color color) {
    final p = Path()
      ..moveTo(x, y + h)
      ..lineTo(x, y + w * .38)
      ..quadraticBezierTo(x + w * .04, y, x + w * .5, y)
      ..quadraticBezierTo(x + w * .96, y, x + w, y + w * .38)
      ..lineTo(x + w, y + h)
      ..close();
    c.drawPath(p, Paint()..color = color);
  }

  void _archOutline(Canvas c, double x, double y, double w, double h, Color color, double width) {
    final p = Path()
      ..moveTo(x, y + h)
      ..lineTo(x, y + w * .38)
      ..quadraticBezierTo(x + w * .04, y, x + w * .5, y)
      ..quadraticBezierTo(x + w * .96, y, x + w, y + w * .38)
      ..lineTo(x + w, y + h);
    c.drawPath(p, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = width);
  }

  void _stonePanel(Canvas c, Rect rect, Color color) {
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = color,
    );
    c.drawRect(rect, Paint()..color = gold.withAlpha(125)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    c.drawRect(rect.deflate(7), Paint()..color = gold.withAlpha(36)..style = PaintingStyle.stroke);
  }

  void _fill(Canvas c, Rect rect, Color color) => c.drawRect(rect, Paint()..color = color);
  void _disc(Canvas c, double x, double y, double r, Color color) =>
      c.drawCircle(Offset(x, y), r, Paint()..color = color);
  void _ring(Canvas c, Offset p, double r, Color color, [double width = 2]) =>
      c.drawCircle(p, r, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = width);
  void _line(Canvas c, Offset a, Offset b, Color color, [double width = 1]) =>
      c.drawLine(a, b, Paint()..color = color..strokeWidth = width..strokeCap = StrokeCap.round);

  @override
  bool shouldRepaint(covariant TombArtPainter oldDelegate) =>
      oldDelegate.scene != scene || oldDelegate.waterDiverted != waterDiverted;
}
