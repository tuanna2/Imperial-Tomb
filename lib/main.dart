import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game/content.dart';
import 'game/game_session.dart';
import 'ui/room_artwork.dart';
import 'ui/mechanism_panel.dart';

// Keep the original key so v1 journeys can be migrated in place.
const saveKey = 'imperial_tomb_save_v1';
const panel = Color(0xFF222823);
const muted = Color(0xFFA8AD9E);

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
          fontFamily: 'TombSans',
          brightness: Brightness.dark,
          scaffoldBackgroundColor: night,
          colorScheme: ColorScheme.fromSeed(
            seedColor: brass,
            brightness: Brightness.dark,
            surface: panel,
          ),
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: paper, fontSize: 14, height: 1.55),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              backgroundColor: brass,
              foregroundColor: night,
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: paper,
              side: BorderSide(color: brass.withAlpha(100)),
            ),
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
  bool playing = false, hasSave = false, reveal = false, combining = false;
  bool saveFailed = false;
  int hintTier = 0;
  TombHotspot? focus;
  PuzzleType? puzzle;
  String message = '“Đừng mở cửa của nhà vua.” Đó là lời cuối Mai để lại.';
  Future<void> saveQueue = Future.value();
  @override
  void initState() {
    super.initState();
    final raw = widget.prefs.getString(saveKey);
    try {
      game = raw == null ? GameSession() : GameSession.deserialize(raw);
      hasSave = raw != null;
    } catch (_) {
      game = GameSession();
      message =
          'Bản lưu không đọc được. Bạn có thể bắt đầu một hành trình mới.';
    }
  }

  void persist() {
    hasSave = true;
    final snapshot = game.serialize();
    // Serialize writes; a slower earlier save must never overwrite newer progress.
    saveQueue = saveQueue.then((_) async {
      try {
        final ok = await widget.prefs.setString(saveKey, snapshot);
        if (mounted && saveFailed == ok) setState(() => saveFailed = !ok);
      } catch (_) {
        if (mounted) setState(() => saveFailed = true);
      }
    });
  }

  Future<bool> confirm(String title, String text, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> newGame() async {
    if (hasSave &&
        !await confirm(
          'BẮT ĐẦU LẠI?',
          'Tiến trình đang lưu sẽ được thay bằng hành trình mới.',
          'Bắt đầu lại',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      game = GameSession();
      playing = true;
      hintTier = 0;
      focus = null;
      puzzle = null;
      combining = false;
      message =
          'Cửa đá khép lại sau lưng. Tôi phải tìm Mai trước khi dòng nước dâng thêm.';
    });
    persist();
  }

  void navigate(int target) {
    final result = game.navigate(target);
    setState(() {
      message = result.message;
      focus = null;
      puzzle = null;
      combining = false;
    });
    persist();
  }

  void selectItem(String item) {
    setState(() {
      if (combining && game.selectedItem != null && game.selectedItem != item) {
        final before = game.inventory.length;
        message = game.combine(game.selectedItem!, item).message;
        combining = false;
        if (game.inventory.length != before) hintTier = 0;
        persist();
      } else {
        game.chooseItem(item);
        combining = false;
      }
    });
  }

  void examineItem(String item) {
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(itemLabels[item] ?? item),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(itemIcons[item], color: brass, size: 54),
            const SizedBox(height: 18),
            Text(itemDescriptions[item] ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cất lại'),
          ),
        ],
      ),
    );
  }

  Future<void> openHotspot(TombHotspot spot) async {
    setState(() {
      focus = spot;
      puzzle = null;
      combining = false;
    });
    if (spot.id == 'main_gate' || spot.id == 'service_exit') {
      setState(
        () => message = spot.id == 'main_gate'
            ? 'Cần xả nối với cổng lớn. Tiếng nước ép sau cánh cửa. Tôi có nên kéo nó?'
            : 'Đường hầm bảo trì dẫn lên sườn núi. Rời khỏi đây sẽ khép lại hành trình.',
      );
    } else {
      await interact();
    }
  }

  Future<void> interact() async {
    final spot = focus;
    if (spot == null) return;
    if (spot.id == 'main_gate' && !game.did('valve_diverted')) {
      if (!await confirm(
        'KÉO CẦN XẢ?',
        'Khối nước phía sau cổng sẽ được giải phóng. Tôi chưa chắc dòng nước sẽ đi về đâu.',
        'Kéo cần xả',
      )) {
        return;
      }
    }
    if (spot.id == 'service_exit') {
      if (!await confirm(
        'RỜI LĂNG MỘ?',
        game.did('valve_diverted')
            ? 'Nước đã đổi dòng. Hãy chắc rằng tôi mang đủ bằng chứng về ba làng.'
            : 'Dòng nước vẫn chưa đổi hướng. Tôi có thể thoát, nhưng sự thật sẽ còn ở lại.',
        'Rời đường hầm',
      )) {
        return;
      }
    }
    if (!mounted) return;
    final before = game.flags.length + game.inventory.length;
    final result = game.inspect(spot.id);
    setState(() {
      message = result.message;
      puzzle = result.puzzle;
      if (game.flags.length + game.inventory.length != before) hintTier = 0;
      if (game.ending != null) {
        focus = null;
        puzzle = null;
      }
    });
    unawaited(HapticFeedback.selectionClick());
    persist();
  }

  void solved() {
    setState(() {
      message = switch (puzzle!) {
        PuzzleType.glyphs => 'Một tiếng bật khẽ. Hộc đá mở ra, để lộ kim đồng.',
        PuzzleType.ledgerCode =>
          'Rương mở. Ngọc ấn và sắc chỉ nằm dưới lớp vải.',
        PuzzleType.lotus => 'Cánh sen lùi vào vách. Một móc sắt ở trong hộc.',
        PuzzleType.mirror =>
          'Ba tia sáng chập lại. Những nét chữ cũ hiện lên trên bản đồ.',
        PuzzleType.stars =>
          'Hộc dưới tinh tượng nhả ra. Lõi bánh van còn thiếu một tay quay.',
        PuzzleType.balance =>
          'Ba đòn cân ngang bằng. Tủ nhả tay quay và cờ lê vuông.',
        PuzzleType.pipes =>
          'Nước chạy kín mạch. Máy bơm khởi động, cầu Thủy môn dần lộ ra.',
        PuzzleType.pressure =>
          'Áp lực chuyển qua nhánh phụ. Tiếng nước rền dần rời khỏi thung lũng.',
      };
      puzzle = null;
      hintTier = 0;
    });
    unawaited(HapticFeedback.mediumImpact());
    persist();
  }

  void showHint() {
    final text = game.hint(tier: hintTier);
    final title = hintTier == 0 ? 'MỘT GỢI Ý NHỎ' : 'LỜI GIẢI TIẾP THEO';
    hintTier = 1;
    showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  void notebook() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: panel,
      builder: (c) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(c).height * .78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NHẬT KÝ KHẢO CỔ',
                  style: TextStyle(
                    color: brass,
                    fontFamily: 'TombSerif',
                    letterSpacing: 2,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  game.objective,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const Divider(height: 26),
                Expanded(
                  child: game.journal.isEmpty
                      ? const Center(child: Text('Chưa có ghi chép.'))
                      : ListView.separated(
                          itemCount: game.journal.length,
                          separatorBuilder: (_, index) =>
                              const Divider(height: 25),
                          itemBuilder: (_, i) => Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}'.padLeft(2, '0'),
                                style: const TextStyle(
                                  color: brass,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(child: Text(game.journal[i])),
                            ],
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
  Widget build(BuildContext context) => PopScope(
        canPop: !playing,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            setState(() {
              if (focus != null) {
                focus = null;
                puzzle = null;
              } else {
                playing = false;
              }
            });
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: !playing
                    ? menu()
                    : game.ending != null
                        ? endingView()
                        : gameView(),
              ),
            ),
          ),
        ),
      );

  Widget menu() => LayoutBuilder(
        builder: (context, bounds) => SingleChildScrollView(
          child: SizedBox(
            height: math.max(bounds.maxHeight, 660),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/rooms/vestibule.webp',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xBB111510),
                        Color(0x08111510),
                        Color(0xF5111510),
                      ],
                      stops: [0, .4, 1],
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 36),
                  child: Column(
                    children: [
                      const Text(
                        'AN ORIGINAL ESCAPE MYSTERY',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: paper,
                          fontSize: 9,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'IMPERIAL\nTOMB',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'TombSerif',
                          fontSize: 48,
                          height: 1.04,
                          letterSpacing: 5,
                          color: paper,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'LĂNG MỘ KHÔNG TÊN',
                        style: TextStyle(
                          color: brass,
                          fontSize: 11,
                          letterSpacing: 2.6,
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Chị tôi bước vào lăng mộ rồi biến mất.\nLời cuối chị để lại: “Đừng mở cửa của nhà vua.”',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: paper, fontSize: 13, height: 1.8),
                      ),
                      const SizedBox(height: 24),
                      if (hasSave) ...[
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () => setState(() {
                              playing = true;
                              focus = null;
                              puzzle = null;
                            }),
                            child: const Padding(
                              padding: EdgeInsets.all(13),
                              child: Text('TIẾP TỤC HÀNH TRÌNH'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: newGame,
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: Text(
                              hasSave ? 'HÀNH TRÌNH MỚI' : 'BẮT ĐẦU KHÁM PHÁ',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '6 khu vực · 8 cơ cấu · 3 kết thúc',
                        style: TextStyle(
                          color: muted,
                          letterSpacing: 1,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
  Widget gameHeader() => SizedBox(
      height: 54,
      child: Row(children: [
        IconButton(
            tooltip: focus == null ? 'Menu' : 'Trở lại phòng',
            onPressed: () => setState(() {
                  if (focus != null) {
                    focus = null;
                    puzzle = null;
                  } else {
                    playing = false;
                  }
                }),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: brass)),
        Expanded(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(focus?.label.toUpperCase() ?? scenes[game.scene].title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'TombSerif',
                  letterSpacing: 2,
                  color: paper,
                  fontSize: 16)),
          Text(
              focus == null
                  ? scenes[game.scene].subtitle
                  : '${scenes[game.scene].title} / CẬN CẢNH',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(color: muted, fontSize: 9, letterSpacing: 1)),
        ])),
        if (focus == null)
          IconButton(
              tooltip: reveal ? 'Ẩn điểm tương tác' : 'Hiện điểm tương tác',
              onPressed: () => setState(() => reveal = !reveal),
              icon: Icon(reveal ? Icons.visibility : Icons.touch_app_outlined,
                  size: 20, color: brass)),
        IconButton(
            tooltip: 'Nhật ký',
            onPressed: notebook,
            icon: const Icon(Icons.menu_book_outlined, size: 21, color: brass)),
        IconButton(
            tooltip: 'Gợi ý',
            onPressed: showHint,
            icon: const Icon(Icons.lightbulb_outline, size: 21, color: brass)),
      ]));
  Widget gameView() => LayoutBuilder(builder: (context, bounds) {
        final horizontal = bounds.maxHeight < 500 && bounds.maxWidth > 500;
        return Column(children: [
          gameHeader(),
          if (saveFailed)
            const Padding(
                padding: EdgeInsets.all(4),
                child: Text('Chưa lưu được tiến trình trên thiết bị.',
                    style: TextStyle(color: Colors.orange, fontSize: 11))),
          Expanded(
              child: horizontal
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          Expanded(
                              child:
                                  focus == null ? roomView() : closeupView()),
                          SizedBox(
                              width: 300,
                              child: Column(children: [
                                Expanded(
                                    child: SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(message))),
                                roomNavigation(),
                                inventoryView(),
                              ])),
                        ])
                  : Column(children: [
                      Expanded(
                          child: focus == null ? roomView() : closeupView()),
                      if (focus == null) ...[messageView(), roomNavigation()],
                      inventoryView(),
                    ])),
        ]);
      });
  Widget roomView() => LayoutBuilder(
        builder: (context, c) {
          final w = math.min(c.maxWidth, c.maxHeight * 2 / 3);
          final h = w * 1.5;
          final room = scenes[game.scene];
          return Center(
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RoomArtwork(scene: room, game: game),
                  ),
                  for (final spot in room.hotspots)
                    Positioned(
                      left: (spot.x * w - 25).clamp(0, math.max(0, w - 50)),
                      top: (spot.y * h - 25).clamp(0, math.max(0, h - 50)),
                      child: Semantics(
                        label: spot.label,
                        button: true,
                        child: Tooltip(
                          message: spot.label,
                          child: GestureDetector(
                            key: ValueKey('hotspot-${spot.id}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => openHotspot(spot),
                            child: SizedBox(
                              width: 50,
                              height: 50,
                              child: reveal
                                  ? Center(
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: night.withAlpha(190),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: paper.withAlpha(180),
                                          ),
                                        ),
                                        child: Icon(
                                          spot.icon,
                                          size: 17,
                                          color: paper,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 9,
                    left: 9,
                    right: 9,
                    child: IgnorePointer(
                      child: Text(
                        reveal
                            ? 'Chạm biểu tượng để nhìn gần'
                            : 'Chạm vào vật trong phòng để nhìn gần',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: paper,
                          fontSize: 10,
                          shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
  Widget closeupView() {
    final spot = focus!;
    return SingleChildScrollView(
      key: ValueKey('closeup-${spot.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height < 700 ? 150 : 210,
            child: RoomArtwork(
              scene: scenes[game.scene],
              focus: spot,
              game: game,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 17, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: paper, height: 1.65),
                ),
                evidencePlate(spot.id),
                if (puzzle != null) ...[
                  const Divider(height: 32),
                  MechanismPanel(
                    key: ValueKey(puzzle),
                    type: puzzle!,
                    game: game,
                    onChanged: persist,
                    onSolved: solved,
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: interact,
                    icon: Icon(
                      spot.id == 'main_gate'
                          ? Icons.warning_amber
                          : spot.id == 'service_exit'
                              ? Icons.logout
                              : game.selectedItem == null
                                  ? Icons.search
                                  : Icons.pan_tool_alt_outlined,
                      size: 18,
                    ),
                    label: Text(
                      spot.id == 'main_gate'
                          ? 'KÉO CẦN XẢ'
                          : spot.id == 'service_exit'
                              ? 'RỜI ĐƯỜNG HẦM'
                              : game.selectedItem == null
                                  ? 'QUAN SÁT LẠI'
                                  : 'DÙNG ${(itemLabels[game.selectedItem] ?? '').toUpperCase()}',
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => setState(() {
                    focus = null;
                    puzzle = null;
                  }),
                  child: const Text(
                    'Lùi lại nhìn toàn phòng',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget evidencePlate(String id) {
    List<String>? symbols;
    if (id == 'stele') symbols = GameSession.glyphAnswer;
    if (id == 'dark_mural' && game.did('mural_read')) {
      symbols = GameSession.starsAnswer;
    }
    if (id == 'lotus_relief') symbols = GameSession.lotusAnswer;
    if (symbols != null) {
      return Container(
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF33372D),
          border: Border.all(color: brass.withAlpha(80)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final s in symbols)
              Column(
                children: [
                  Icon(symbolIcons[s], color: brass),
                  const SizedBox(height: 4),
                  Text(
                    symbolLabels[s]!,
                    style: const TextStyle(fontSize: 10, color: brass),
                  ),
                ],
              ),
          ],
        ),
      );
    }
    if (id == 'canal_map' && game.did('canal_read')) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(14),
        color: const Color(0xFF33372D),
        child: const Text(
          'CỬA CHÍNH → Đông Lâm · Vạn Khê · Hạ Thủy\nVAN PHỤ → Lòng sông cũ',
          style: TextStyle(color: brass, height: 1.9, fontSize: 12),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget messageView() => InkWell(
        onTap: () => showDialog<void>(
          context: context,
          builder: (c) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c),
                child: const Text('Đóng'),
              ),
            ],
          ),
        ),
        child: Container(
          alignment: Alignment.centerLeft,
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
          child: Text(
            message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: paper, fontSize: 12, height: 1.5),
          ),
        ),
      );
  Widget roomNavigation() => SizedBox(
        height: 43,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          children: [
            for (final i in roomOrder)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: OutlinedButton(
                  onPressed: () => navigate(i),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: game.scene == i
                        ? brass.withAlpha(35)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                  ),
                  child: Row(
                    children: [
                      if (!game.canEnter(i)) ...[
                        const Icon(Icons.lock_outline, size: 12),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        scenes[i].title,
                        style: const TextStyle(fontSize: 10, letterSpacing: .5),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      );
  Widget inventoryView() => Container(
        height: 112,
        decoration: const BoxDecoration(
          color: Color(0xFF20251F),
          border: Border(top: BorderSide(color: Color(0xFF4A4A3B))),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 31,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        combining
                            ? 'CHẠM VÀO VẬT THỨ HAI'
                            : game.selectedItem == null
                                ? 'TÚI ĐỒ  ·  CHẠM CHỌN, GIỮ ĐỂ XEM'
                                : 'CẦM: ${itemLabels[game.selectedItem]}',
                        style: const TextStyle(
                          color: brass,
                          fontSize: 9,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                    if (game.selectedItem != null) ...[
                      IconButton(
                        tooltip: 'Xem vật phẩm',
                        onPressed: () => examineItem(game.selectedItem!),
                        constraints: const BoxConstraints(minWidth: 32),
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.info_outline,
                          color: brass,
                          size: 17,
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() => combining = !combining),
                        child: Text(
                          combining ? 'HỦY' : 'GHÉP',
                          style: const TextStyle(color: brass, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: game.inventory.isEmpty
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: 15),
                        child: Text(
                          'Tìm vật dụng trong phòng.',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                    )
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(10, 3, 10, 9),
                      children: [
                        for (final item in game.inventory)
                          Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: Semantics(
                              label: itemLabels[item],
                              selected: game.selectedItem == item,
                              button: true,
                              child: InkWell(
                                key: ValueKey('item-$item'),
                                onTap: () => selectItem(item),
                                onLongPress: () => examineItem(item),
                                borderRadius: BorderRadius.circular(5),
                                child: Container(
                                  width: 82,
                                  decoration: BoxDecoration(
                                    color: game.selectedItem == item
                                        ? brass.withAlpha(33)
                                        : night.withAlpha(120),
                                    borderRadius: BorderRadius.circular(5),
                                    border: Border.all(
                                      color: game.selectedItem == item
                                          ? brass
                                          : const Color(0xFF43493C),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        itemIcons[item] ??
                                            Icons.inventory_2_outlined,
                                        color: game.selectedItem == item
                                            ? paper
                                            : brass,
                                        size: 24,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        itemLabels[item] ?? item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: paper,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      );
  Widget endingView() {
    final end = game.ending!;
    final title = switch (end) {
      EndingType.bad => 'BI KỊCH LẶP LẠI',
      EndingType.ordinary => 'NGƯỜI TRỞ VỀ',
      EndingType.trueEnding => 'DÒNG SÔNG TRỞ VỀ',
    };
    final story = switch (end) {
      EndingType.bad =>
        'Cổng lớn mở ra. Dòng lũ lao xuống thung lũng. Từ khe đá, tôi nghe tiếng chuông của ba ngôi làng. Tôi đã hiểu lời Mai, nhưng quá muộn để kéo cần trở lại.',
      EndingType.ordinary =>
        'Tôi theo đường hầm lên sườn núi. Không ai biết tôi đã nhìn thấy gì dưới đó. Những bằng chứng chưa trọn vẹn, những việc chưa làm xong, khiến câu chuyện về một lăng mộ tiếp tục được tin là thật.',
      EndingType.trueEnding =>
        'Đông Lâm, Vạn Khê, Hạ Thủy. Tôi đặt bản dập bên cạnh sắc chỉ, và lần đầu những cái tên khớp lại với lịch sử. Nước đã trở về sông cũ. Trên mặt sau thư, Mai vẽ một ngọn đèn ở đầu đường hầm phía đông. Chị vẫn để lại đường cho tôi đi tiếp.',
    };
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: RoomArtwork(
                scene: scenes[end == EndingType.trueEnding ? 4 : 3],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(
                  'KẾT THÚC ${end.index + 1} / 3',
                  style: const TextStyle(
                    color: brass,
                    fontSize: 10,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: paper,
                    fontFamily: 'TombSerif',
                    fontSize: 27,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  story,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.9),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: notebook,
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('ĐỌC LẠI NHẬT KÝ'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: newGame,
                  child: const Text('HÀNH TRÌNH MỚI'),
                ),
                TextButton(
                  onPressed: () => setState(() => playing = false),
                  child: const Text('Về màn hình đầu'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
