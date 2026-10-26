import 'package:flutter/material.dart';

import '../game/content.dart';
import '../game/game_session.dart';
import 'room_artwork.dart';

class MechanismPanel extends StatefulWidget {
  const MechanismPanel({
    super.key,
    required this.type,
    required this.game,
    required this.onChanged,
    required this.onSolved,
  });
  final PuzzleType type;
  final GameSession game;
  final VoidCallback onChanged;
  final VoidCallback onSolved;
  @override
  State<MechanismPanel> createState() => _MechanismPanelState();
}

class _MechanismPanelState extends State<MechanismPanel> {
  late List<int> values;
  String feedback = '';
  bool get sequence =>
      [PuzzleType.glyphs, PuzzleType.lotus].contains(widget.type);
  List<String> get symbols => widget.type == PuzzleType.lotus
      ? ['north', 'east', 'south', 'west']
      : ['moon', 'mountain', 'sun'];
  @override
  void initState() {
    super.initState();
    final initial = switch (widget.type) {
      PuzzleType.pipes => [1, 1, 0, 0, 1, 0],
      PuzzleType.balance => [1, 1, 1],
      PuzzleType.glyphs || PuzzleType.lotus => <int>[],
      _ => [0, 0, 0],
    };
    final saved = widget.game.mechanisms[widget.type.name];
    final limit = switch (widget.type) {
      PuzzleType.mirror => 8,
      PuzzleType.ledgerCode => 10,
      PuzzleType.stars || PuzzleType.glyphs => 3,
      PuzzleType.pipes || PuzzleType.lotus => 4,
      PuzzleType.pressure => 5,
      PuzzleType.balance => 7,
    };
    values = saved != null &&
            (sequence
                ? saved.length < (widget.type == PuzzleType.lotus ? 4 : 3)
                : saved.length == initial.length) &&
            saved.every((v) => v >= 0 && v < limit)
        ? List.of(saved)
        : initial;
  }

  void changed() {
    widget.game.saveMechanism(widget.type, values);
    widget.onChanged();
  }

  void setDial(int i, int max) {
    setState(() {
      values[i] = (values[i] + 1) % max;
      if (widget.type == PuzzleType.balance && values[i] == 0) values[i] = 1;
      feedback = '';
    });
    changed();
  }

  void press(int i) {
    setState(() {
      values.add(i);
      feedback = '';
    });
    changed();
    if (values.length == (widget.type == PuzzleType.lotus ? 4 : 3)) submit();
  }

  void submit() {
    final type = widget.type;
    final solved = switch (type) {
      PuzzleType.glyphs => widget.game.solveGlyphs(
          values.map((i) => symbols[i]).toList(),
        ),
      PuzzleType.lotus => widget.game.solveLotus(
          values.map((i) => symbols[i]).toList(),
        ),
      PuzzleType.ledgerCode => widget.game.solveChest(values.join()),
      PuzzleType.mirror => widget.game.solveMirror(values),
      PuzzleType.stars => widget.game.solveStars(
          values.map((i) => ['sun', 'river', 'moon'][i]).toList(),
        ),
      PuzzleType.balance => widget.game.solveBalance(values),
      PuzzleType.pipes => widget.game.solvePipes(values),
      PuzzleType.pressure => widget.game.solvePressure(values),
    };
    if (solved) {
      widget.onSolved();
      return;
    }
    setState(() {
      feedback = type == PuzzleType.pipes
          ? 'Đường ống còn hở hoặc có đoạn chưa được nối.'
          : 'Cơ quan chưa nhả. Hãy đối chiếu manh mối trong nhật ký.';
      if (sequence) values.clear();
    });
    changed();
  }

  Widget dial(int i, String label, int max, {bool star = false}) => Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: brass, fontSize: 11)),
            const SizedBox(height: 8),
            Semantics(
              label: '$label: ${star ? symbolLabels[[
                  'sun',
                  'river',
                  'moon'
                ][values[i]]] : values[i]}. Chạm để xoay',
              button: true,
              child: InkWell(
                key: ValueKey('dial-$i'),
                onTap: () => setDial(i, max),
                borderRadius: BorderRadius.circular(40),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF68604B), Color(0xFF292A22)],
                    ),
                    border: Border.all(color: brass, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 8),
                    ],
                  ),
                  child: Center(
                    child: star
                        ? Icon(
                            symbolIcons[['sun', 'river', 'moon'][values[i]]],
                            color: paper,
                            size: 28,
                          )
                        : Text(
                            '${values[i]}',
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 29,
                              color: paper,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Icon(Icons.rotate_right, size: 15, color: brass),
          ],
        ),
      );
  @override
  Widget build(BuildContext context) {
    final type = widget.type;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sequence) ...[
          SizedBox(
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                type == PuzzleType.lotus ? 4 : 3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    i < values.length
                        ? symbolIcons[symbols[values[i]]]
                        : Icons.radio_button_unchecked,
                    color: brass,
                  ),
                ),
              ),
            ),
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < symbols.length; i++)
                OutlinedButton(
                  onPressed: () => press(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(symbolIcons[symbols[i]], size: 26),
                      Text(
                        symbolLabels[symbols[i]]!,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          TextButton(
            onPressed: () {
              setState(() => values.clear());
              changed();
            },
            child: const Text('Xóa thứ tự'),
          ),
        ] else if (type == PuzzleType.pipes) ...[
          const Text(
            'VÀO → hàng trên  ·  RA ↓ dưới trái',
            style: TextStyle(color: brass, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 264,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, i) => Semantics(
                label: 'Ống ${i + 1}, xoay một phần tư vòng',
                button: true,
                child: InkWell(
                  key: ValueKey('pipe-$i'),
                  onTap: () => setDial(i, 4),
                  child: Container(
                    color: const Color(0xFF282E29),
                    child: CustomPaint(
                      painter: PipePainter(
                        GameSession.pipeMask(i, values[i]),
                        connected: GameSession.pipesConnected(values),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ] else ...[
          if (type == PuzzleType.mirror)
            SizedBox(
              height: 160,
              width: 210,
              child: CustomPaint(painter: RingPainter(List.of(values))),
            ),
          if (type == PuzzleType.balance) ...[
            Text(
              'TỔNG: ${values.fold(0, (a, b) => a + b)} / 10',
              style: const TextStyle(color: brass, letterSpacing: 2),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (values[0] + values[2]) / 12,
              minHeight: 3,
              color: brass,
              backgroundColor: Colors.white12,
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              for (var i = 0; i < 3; i++)
                dial(
                  i,
                  type == PuzzleType.mirror
                      ? ['NGOÀI', 'GIỮA', 'TRONG'][i]
                      : type == PuzzleType.pressure
                          ? ['SÔNG CŨ', 'BỂ LẮNG', 'ĐỐI LƯU'][i]
                          : type == PuzzleType.balance
                              ? ['TRÁI', 'GIỮA', 'PHẢI'][i]
                              : type == PuzzleType.ledgerCode
                                  ? ['I', 'II', 'III'][i]
                                  : ['VÒNG I', 'VÒNG II', 'VÒNG III'][i],
                  type == PuzzleType.mirror
                      ? 8
                      : type == PuzzleType.ledgerCode
                          ? 10
                          : type == PuzzleType.stars
                              ? 3
                              : type == PuzzleType.balance
                                  ? 7
                                  : 5,
                  star: type == PuzzleType.stars,
                ),
            ],
          ),
        ],
        if (feedback.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              feedback,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFD8A695), fontSize: 12),
            ),
          ),
        if (!sequence)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: FilledButton.icon(
              onPressed: submit,
              icon: const Icon(Icons.check, size: 17),
              label: Text(
                type == PuzzleType.pipes ? 'THỬ DÒNG NƯỚC' : 'VẬN HÀNH',
              ),
            ),
          ),
      ],
    );
  }
}
