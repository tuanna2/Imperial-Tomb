import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/content.dart';
import 'game/game_session.dart';
import 'ui/tomb_art.dart';

const gold = Color(0xFFD8B77A);
const ink = Color(0xFF0B1518);
const panel = Color(0xFF18262A);
const muted = Color(0xFF91A6A1);
const saveKey = 'imperial_tomb_save_v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(ImperialTombApp(prefs: prefs));
}

class ImperialTombApp extends StatelessWidget {
  const ImperialTombApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Imperial Tomb',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: ink,
          colorScheme: ColorScheme.fromSeed(
            seedColor: gold,
            surface: panel,
            brightness: Brightness.dark,
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontFamily: 'serif',
              color: gold,
              fontSize: 35,
              letterSpacing: 3,
            ),
            bodyMedium: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        home: TombHome(prefs: prefs),
      );
}

class TombHome extends StatefulWidget {
  const TombHome({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<TombHome> createState() => _TombHomeState();
}

class _TombHomeState extends State<TombHome> {
  late GameSession game;
  bool playing = false;
  bool hasSave = false;
  int hintTier = 0;
  String message = 'Lối vào lăng mộ đóng sầm sau lưng tôi.';

  @override
  void initState() {
    super.initState();
    final raw = widget.prefs.getString(saveKey);
    try {
      game = raw == null ? GameSession() : GameSession.deserialize(raw);
      hasSave = raw != null;
    } catch (_) {
      game = GameSession();
    }
  }

  void persist() {
    hasSave = true;
    unawaited(widget.prefs.setString(saveKey, game.serialize()));
  }

  void newGame() {
    setState(() {
      game = GameSession();
      playing = true;
      hintTier = 0;
      message = '“Đừng mở cửa của nhà vua.” Lời cuối Mai để lại trước khi biến mất.';
    });
    persist();
  }

  void continueGame() {
    setState(() => playing = true);
  }

  void navigate(int target) {
    final result = game.navigate(target);
    setState(() {
      message = result.message;
      hintTier = 0;
    });
    persist();
  }

  void chooseItem(String item) {
    setState(() {
      game.chooseItem(item);
      message = game.selectedItem == null
          ? 'Đã bỏ chọn vật phẩm.'
          : 'Đang cầm ' + (itemLabels[item] ?? item) + '. Chạm vào nơi cần sử dụng.';
    });
  }

  Future<void> inspect(String id) async {
    if (id == 'main_gate' && !game.did('valve_diverted')) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('CỬA XẢ CHÍNH'),
          content: const Text(
            'Cánh cửa giữ một khối nước khổng lồ. '
            'Có chắc muốn kéo cần xả trước khi kiểm tra van phụ?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Dừng lại')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kéo cần')),
          ],
        ),
      );
      if (sure != true || !mounted) return;
    }

    final result = game.inspect(id);
    if (result.puzzle != null) {
      final solved = await showDialog<bool>(
        context: context,
        builder: (context) => PuzzleDialog(type: result.puzzle!, game: game),
      );
      if (!mounted) return;
      setState(() {
        message = solved == true
            ? switch (result.puzzle!) {
                PuzzleType.glyphs => 'Khóa đá mở. Tôi nhặt được kim đồng từ bên trong.',
                PuzzleType.ledgerCode => 'Rương ngọc bật mở, để lộ ngọc ấn và một sắc chỉ.',
                PuzzleType.stars => 'Vòng tinh tượng tách ra, bên trong có bánh van đồng.',
              }
            : result.message;
      });
    } else {
      setState(() => message = result.message);
    }
    persist();
  }

  void showHint() {
    final text = game.hint(tier: hintTier);
    final title = hintTier == 0 ? 'GỢI Ý' : 'LỜI GIẢI';
    setState(() => hintTier = 1);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(color: gold)),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đã hiểu')),
        ],
      ),
    );
  }

  void showNotebook() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: panel,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .65,
          child: Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NHẬT KÝ KHẢO CỔ',
                    style: TextStyle(color: gold, fontSize: 19, letterSpacing: 2)),
                const SizedBox(height: 5),
                const Text('Các manh mối đã thu thập', style: TextStyle(color: muted)),
                const Divider(height: 22),
                Expanded(
                  child: game.journal.isEmpty
                      ? const Center(child: Text('Chưa phát hiện manh mối.'))
                      : ListView.separated(
                          itemCount: game.journal.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, i) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text((i + 1).toString().padLeft(2, '0') +
                                '  ' + game.journal[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: !playing
                  ? buildMenu()
                  : game.ending != null
                      ? buildEnding()
                      : buildGame(),
            ),
          ),
        ),
      );

  Widget buildMenu() => LayoutBuilder(
        builder: (context, c) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              const Text('AN ORIGINAL ESCAPE ROOM',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 11, letterSpacing: 3)),
              const SizedBox(height: 19),
              Text('IMPERIAL\nTOMB',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 43,
                        height: 1.1,
                      )),
              const SizedBox(height: 7),
              const Text('LĂNG MỘ KHÔNG TÊN',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: gold, fontSize: 12, letterSpacing: 3)),
              const SizedBox(height: 23),
              SizedBox(
                height: c.maxHeight < 650 ? 230 : 315,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(
                    painter: const TombArtPainter(0),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(height: 23),
              const Text(
                'Chị gái tôi mất tích sau khi bước vào lăng mộ. '
                'Đoạn ghi âm cuối cùng chỉ có một lời cảnh báo: '
                '“Đừng mở cửa của nhà vua.”',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFFD4D7CB), height: 1.65),
              ),
              const SizedBox(height: 25),
              if (hasSave) ...[
                FilledButton.icon(
                  onPressed: continueGame,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('TIẾP TỤC'),
                  style: FilledButton.styleFrom(
                    backgroundColor: gold,
                    foregroundColor: ink,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
                const SizedBox(height: 9),
              ],
              OutlinedButton.icon(
                onPressed: newGame,
                icon: const Icon(Icons.account_balance_outlined),
                label: Text(hasSave ? 'CHƠI LẠI' : 'BẮT ĐẦU KHÁM PHÁ'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: gold,
                  side: const BorderSide(color: gold),
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Khám phá · Thu thập · Suy luận · Tự động lưu',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: muted)),
            ],
          ),
        ),
      );

  Widget buildGame() {
    final scene = scenes[game.scene];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Menu',
                onPressed: () => setState(() => playing = false),
                icon: const Icon(Icons.arrow_back_ios_new, color: gold, size: 17),
              ),
              Expanded(
                child: Column(
                  children: [
                    const Text('IMPERIAL TOMB',
                        style: TextStyle(color: gold, letterSpacing: 3, fontSize: 12)),
                    Text(scene.title,
                        style: const TextStyle(color: muted, letterSpacing: 2, fontSize: 10)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Nhật ký',
                onPressed: showNotebook,
                icon: const Icon(Icons.menu_book_outlined, color: gold),
              ),
              IconButton(
                tooltip: 'Gợi ý',
                onPressed: showHint,
                icon: const Icon(Icons.lightbulb_outline, color: gold),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(
                      painter: TombArtPainter(
                        game.scene,
                        waterDiverted: game.did('valve_diverted'),
                      ),
                    ),
                    for (final hotspot in scene.hotspots)
                      Positioned(
                        left: (hotspot.x * w).clamp(0, (w - 123).clamp(0, w)),
                        top: (hotspot.y * h).clamp(0, (h - 42).clamp(0, h)),
                        child: HotspotButton(
                          hotspot: hotspot,
                          onTap: () => inspect(hotspot.id),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      left: 10,
                      right: 10,
                      child: IgnorePointer(
                        child: Text(
                          scene.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            color: gold,
                            fontSize: 12,
                            shadows: [Shadow(color: Colors.black, blurRadius: 12)],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 66),
          margin: const EdgeInsets.fromLTRB(8, 6, 8, 2),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: gold.withAlpha(50)),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            message,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, height: 1.35),
          ),
        ),
        SizedBox(
          height: 51,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            itemCount: scenes.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final active = game.scene == i;
              final locked = i == 3 && !game.has('jade_seal');
              return OutlinedButton.icon(
                onPressed: () => navigate(i),
                icon: Icon(locked ? Icons.lock_outline : Icons.place_outlined, size: 14),
                label: Text(scenes[i].title, style: const TextStyle(fontSize: 10)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  backgroundColor: active ? gold : Colors.transparent,
                  foregroundColor: active ? ink : gold,
                  side: BorderSide(color: active ? gold : gold.withAlpha(85)),
                ),
              );
            },
          ),
        ),
        Container(
          height: 93,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(9, 6, 9, 8),
          decoration: const BoxDecoration(
            color: Color(0xFF101E20),
            border: Border(top: BorderSide(color: Color(0xFF63593B))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TÚI ĐỒ  ·  CHỌN ĐỒ RỒI CHẠM VÀO CẢNH',
                  style: TextStyle(color: muted, fontSize: 9, letterSpacing: 1)),
              const SizedBox(height: 6),
              Expanded(
                child: game.inventory.isEmpty
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Chưa có vật phẩm.', style: TextStyle(color: muted)),
                      )
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final item in game.inventory)
                            Padding(
                              padding: const EdgeInsets.only(right: 7),
                              child: InventorySlot(
                                label: itemLabels[item] ?? item,
                                icon: itemIcons[item] ?? Icons.category_outlined,
                                selected: game.selectedItem == item,
                                onTap: () => chooseItem(item),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildEnding() {
    final ending = game.ending!;
    final isTrue = ending == EndingType.trueEnding;
    final title = switch (ending) {
      EndingType.bad => 'BI KỊCH LẶP LẠI',
      EndingType.ordinary => 'LỐI THOÁT',
      EndingType.trueEnding => 'DÒNG SÔNG TRỞ VỀ',
    };
    final story = switch (ending) {
      EndingType.bad =>
        'Tôi mở cánh cổng lớn. Dòng nước ầm ầm đổ xuống thung lũng, '
        'và tiếng chuông của ba ngôi làng vang lên từ bóng tối. '
        'Tôi đã lặp lại tội lỗi từng bị chôn giấu dưới lăng mộ.',
      EndingType.ordinary =>
        'Tôi thoát qua lối hầm. Không ai biết phía sau núi là một cỗ máy '
        'có thể thay đổi số phận ba ngôi làng. Tôi còn sống, nhưng sự thật '
        'vẫn bị chôn vùi trong đá.',
      EndingType.trueEnding =>
        'Tôi đưa dòng nước về lòng sông cũ và mang sắc chỉ cùng thư Mai '
        'ra ánh sáng. Tôi vẫn chưa tìm ra chị, nhưng đã hiểu điều chị '
        'muốn bảo vệ. Những cái tên bị xóa cuối cùng sẽ được nhắc lại.',
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.all(27),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 34),
          Icon(isTrue ? Icons.water : ending == EndingType.bad
              ? Icons.warning_amber : Icons.door_back_door, size: 64, color: gold),
          const SizedBox(height: 23),
          Text(title, textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 29)),
          const SizedBox(height: 8),
          Text(ending == EndingType.bad
              ? 'ENDING I / III' : ending == EndingType.ordinary
                  ? 'ENDING II / III' : 'TRUE ENDING III / III',
              style: const TextStyle(color: muted, letterSpacing: 2, fontSize: 11)),
          const SizedBox(height: 25),
          Text(story, textAlign: TextAlign.center,
              style: const TextStyle(height: 1.85, fontSize: 15)),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: showNotebook,
            icon: const Icon(Icons.menu_book_outlined),
            label: const Text('XEM NHẬT KÝ'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: newGame,
            icon: const Icon(Icons.refresh),
            label: const Text('CHƠI LẠI · TÌM KẾT THÚC KHÁC'),
            style: FilledButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: ink,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => playing = false),
            child: const Text('Về menu'),
          ),
        ],
      ),
    );
  }
}

class HotspotButton extends StatelessWidget {
  const HotspotButton({super.key, required this.hotspot, required this.onTap});

  final TombHotspot hotspot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 121,
        height: 40,
        child: Material(
          elevation: 3,
          color: const Color(0xE50C1C1F),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: gold.withAlpha(190)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(hotspot.icon, color: gold, size: 16),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      hotspot.label,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: const TextStyle(color: Color(0xFFF2E8D5), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class InventorySlot extends StatelessWidget {
  const InventorySlot({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 89,
          decoration: BoxDecoration(
            color: selected ? gold.withAlpha(45) : panel,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? gold : gold.withAlpha(50),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? gold : muted, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10)),
            ],
          ),
        ),
      );
}

class PuzzleDialog extends StatefulWidget {
  const PuzzleDialog({super.key, required this.type, required this.game});

  final PuzzleType type;
  final GameSession game;

  @override
  State<PuzzleDialog> createState() => _PuzzleDialogState();
}

class _PuzzleDialogState extends State<PuzzleDialog> {
  final TextEditingController code = TextEditingController();
  final List<String> selection = [];
  String error = '';

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void pressSymbol(String symbol) {
    setState(() {
      selection.add(symbol);
      error = '';
    });
    if (selection.length < 3) return;
    final correct = widget.type == PuzzleType.glyphs
        ? widget.game.solveGlyphs(selection)
        : widget.game.solveStars(selection);
    if (correct) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        error = 'Thứ tự chưa chính xác. Cơ quan trở lại vị trí ban đầu.';
        selection.clear();
      });
    }
  }

  void submitCode() {
    if (widget.game.solveChest(code.text)) {
      Navigator.pop(context, true);
    } else {
      setState(() => error = 'Rương vẫn khóa. Hãy kiểm tra lại thứ tự I – II – III.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final keypad = widget.type == PuzzleType.ledgerCode;
    final stars = widget.type == PuzzleType.stars;
    return AlertDialog(
      backgroundColor: panel,
      title: Text(
        keypad ? 'RƯƠNG NGỌC' : stars ? 'BÀN TINH TƯỢNG' : 'KHÓA TAM TƯỢNG',
        style: const TextStyle(color: gold, letterSpacing: 1.5, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                keypad
                    ? 'Nhập số ngọn đèn của ba đoàn thuyền theo thứ tự I – II – III.'
                    : stars
                        ? 'Đặt ba vòng theo lộ trình cổ được giấu trong Tàng thư.'
                        : 'Đặt ba biểu tượng theo lời thề trên bia đá.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 18),
              if (keypad) ...[
                TextField(
                  controller: code,
                  maxLength: 3,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onSubmitted: (_) => submitCode(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: gold, fontSize: 27, letterSpacing: 14),
                  decoration: const InputDecoration(
                    hintText: '— — —',
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: submitCode,
                  child: const Text('MỞ KHÓA'),
                ),
              ] else ...[
                Container(
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    selection.map((symbol) => symbolLabels[symbol]).join(' → '),
                    style: const TextStyle(color: gold),
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 7,
                  runSpacing: 8,
                  children: [
                    for (final symbol in (stars
                        ? <String>['sun', 'river', 'moon']
                        : <String>['moon', 'mountain', 'sun']))
                      OutlinedButton(
                        onPressed: () => pressSymbol(symbol),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: gold),
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 13),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(symbolIcons[symbol], color: gold, size: 26),
                            const SizedBox(height: 6),
                            Text(symbolLabels[symbol] ?? symbol,
                                style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() {
                    selection.clear();
                    error = '';
                  }),
                  child: const Text('Xóa thứ tự'),
                ),
              ],
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFB5A0), fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Quan sát thêm'),
        ),
      ],
    );
  }
}
