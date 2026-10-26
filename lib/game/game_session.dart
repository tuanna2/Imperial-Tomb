import 'dart:convert';

/// Domain rules stay independent from Flutter widgets and persistence.
enum PuzzleType { glyphs, ledgerCode, stars }

enum EndingType { bad, ordinary, trueEnding }

class GameAction {
  const GameAction(this.message, {this.puzzle, this.ending});

  final String message;
  final PuzzleType? puzzle;
  final EndingType? ending;
}

class GameSession {
  int scene = 0;
  EndingType? ending;
  final Set<String> inventory = <String>{};
  final Set<String> flags = <String>{};
  final List<String> journal = <String>[];
  String? selectedItem;

  static const List<String> glyphAnswer = ['sun', 'mountain', 'moon'];
  static const List<String> starsAnswer = ['moon', 'river', 'sun'];
  static const String chestAnswer = '421';

  bool has(String item) => inventory.contains(item);
  bool did(String flag) => flags.contains(flag);

  void chooseItem(String item) {
    if (!has(item)) return;
    selectedItem = selectedItem == item ? null : item;
  }

  void _record(String flag, String entry) {
    if (flags.add(flag)) journal.add(entry);
  }

  void _take(String item, String entry) {
    if (inventory.add(item)) journal.add(entry);
  }

  GameAction navigate(int target) {
    if (target < 0 || target > 3) {
      return const GameAction('Lối đi này không tồn tại.');
    }
    if (target == 3 && !has('jade_seal')) {
      return const GameAction(
        'Cửa Thủy Môn có một hốc hình rồng. Một thứ gì đó phải được đặt vào đây trước.',
      );
    }
    scene = target;
    selectedItem = null;
    const introductions = [
      'Tiền điện. Không có quan tài. Chỉ có tiếng nước rền sâu dưới nền đá.',
      'Tàng thư. Những thẻ tre được xếp như sổ sách của một công trình.',
      'Tinh điện. Một bầu trời bằng đồng xoay trên lòng núi.',
      'Thủy môn. Phía sau lớp đá là tiếng nước đang bị nén lại.',
    ];
    return GameAction(introductions[target]);
  }

  GameAction inspect(String hotspot) {
    if (ending != null) {
      return const GameAction('Câu chuyện đã kết thúc. Hãy bắt đầu lại để đổi lựa chọn.');
    }
    switch (hotspot) {
      case 'lantern':
        if (!has('oil_lamp')) {
          _take('oil_lamp', 'Nhặt được đèn dầu từ chiếc đôn đá ở Tiền điện.');
          return const GameAction(
            'Chiếc đèn dầu vẫn còn dầu. Có lẽ nó đủ sáng để đọc những dòng chữ bị che khuất.',
          );
        }
        return const GameAction('Trên đôn đá chỉ còn vệt bụi hình chiếc đèn.');

      case 'stele':
        _record(
          'stele_read',
          'Bia Tiền điện: Mặt Trời → Núi → Trăng. Đoàn thuyền thứ hai có HAI ngọn đuốc.',
        );
        return const GameAction(
          'Dòng chữ trên bia: “Mặt Trời dẫn đường, Núi che lưng, Trăng giữ lời thề.” '
          'Bên dưới là hình đoàn thuyền thứ hai, có đúng HAI ngọn đuốc.',
        );

      case 'glyph_lock':
        if (did('glyph_solved')) {
          return const GameAction('Ba biểu tượng đã chìm xuống mặt đá. Kim đồng đã được lấy.');
        }
        return const GameAction(
          'Ba con dấu hình Mặt Trời, Núi, Trăng. Thứ tự của chúng có lẽ nằm trên bia đá.',
          puzzle: PuzzleType.glyphs,
        );

      case 'ledger':
        _record(
          'ledger_read',
          'Sổ Tàng thư: đoàn thuyền thứ nhất có BỐN đèn, đoàn thứ ba có MỘT đèn.',
        );
        return const GameAction(
          'Sổ đăng bộ ghi: “Đoàn I: BỐN đèn; Đoàn III: MỘT đèn.” '
          'Dòng về Đoàn II đã bị cắt bỏ. Phía cuối trang có ba ô vuông để điền số.',
        );

      case 'jade_chest':
        if (did('chest_solved')) {
          return const GameAction('Rương ngọc trống. Dưới đáy còn dấu của chiếc ấn hình rồng.');
        }
        return const GameAction(
          'Khóa rương có ba chữ số, đánh dấu I – II – III. Hãy tìm số đèn của ba đoàn thuyền.',
          puzzle: PuzzleType.ledgerCode,
        );

      case 'dark_mural':
        if (did('mural_read')) {
          return const GameAction(
            'Dưới lớp muội than: “Khi nước trở về nguồn: Trăng soi Sông, Sông đưa Mặt Trời.” '
            'Ba hình khắc theo thứ tự TRĂNG → SÔNG → MẶT TRỜI.',
          );
        }
        if (selectedItem != 'oil_lamp') {
          return const GameAction(
            'Vách đá ám đen. Tôi có thể nhìn thấy rãnh chữ, nhưng không thể đọc được. '
            'Hãy chọn một nguồn sáng trong túi đồ trước.',
          );
        }
        _record(
          'mural_read',
          'Soi đèn vào vách Tàng thư: Trăng → Sông → Mặt Trời.',
        );
        return const GameAction(
          'Ánh đèn lộ ra dòng chữ: “Trăng soi Sông. Sông đưa Mặt Trời trở về.” '
          'Ba ký hiệu khắc dưới đó lần lượt là TRĂNG – SÔNG – MẶT TRỜI.',
        );

      case 'alcove':
        if (has('letter_mai')) {
          return const GameAction(
            'Hộc đá từng giấu thư của Mai. Cô ấy đã đến được Thủy Môn trước tôi.',
          );
        }
        if (selectedItem != 'bronze_stylus') {
          return const GameAction(
            'Khe ở hộc thư quá mảnh để dùng tay. Một vật kim loại đầu nhọn có thể gạt then.',
          );
        }
        _take(
          'letter_mai',
          'Thư của Mai: “Cửa lớn là cửa xả lũ. Van phụ đưa nước trở về sông cũ. '
          'Đừng tin chữ THOÁT khắc trên cổng.”',
        );
        return const GameAction(
          'Đầu kim đồng đẩy bật then. Trong hộc là thư của Mai: “An, chị còn sống khi viết '
          'những dòng này. Cửa lớn không phải cửa ra. Nó xả nước xuống làng. '
          'Hãy tìm van phụ, rồi mang sắc chỉ ra ngoài.”',
        );

      case 'orrery':
        if (did('stars_solved')) {
          return const GameAction('Bàn tinh tượng đã đứng yên. Bánh van bằng đồng đã được lấy.');
        }
        if (!has('bronze_stylus')) {
          return const GameAction(
            'Trục tinh tượng thiếu một chiếc kim. Nó cần một mũi kim đồng để khởi động.',
          );
        }
        return const GameAction(
          'Kim đồng vừa khít với trục xoay. Ba vòng ký hiệu phải được xoay theo '
          'lộ trình dòng nước cổ.',
          puzzle: PuzzleType.stars,
        );

      case 'canal_map':
        _record(
          'canal_read',
          'Bản đồ: cửa lớn đẩy nước xuống thung lũng; van phụ dẫn nước về dòng sông cũ.',
        );
        return const GameAction(
          'Bản đồ cho thấy hai lối: CỬA CHÍNH đổ về những dấu nhà ở thung lũng; '
          'VAN PHỤ dẫn nước trở lại một lòng sông đã khô. '
          'Lăng mộ này thực chất là một công trình thủy lợi.',
        );

      case 'mirror':
        _record(
          'mirror_read',
          'Trong gương đồng có bóng ba ngôi làng. Tên làng đã bị cạo khỏi bản đồ.',
        );
        return const GameAction(
          'Tấm gương không phản chiếu tôi. Nó phản chiếu những mái nhà vẽ ở phía sau '
          'bản đồ, như thể người xây dựng muốn ai đó nhận ra phần bị xóa.',
        );

      case 'inscription':
        _record(
          'gate_read',
          'Thủy Môn: “Bảo vệ kinh thành bằng cách đổi dòng nước.” '
          'Chữ “mộ” đã được khắc đè lên chữ “môn”.',
        );
        return const GameAction(
          'Tấm biển khắc “LĂNG MỘ HOÀNG ĐẾ”. Nhưng dưới nét đục mới là ba chữ '
          '“HOÀNG THỦY MÔN”. Đây là cánh cổng điều tiết nước, không phải nơi an táng.',
        );

      case 'side_valve':
        if (did('valve_diverted')) {
          return const GameAction(
            'Bánh van đã khóa theo dòng sông cũ. Tiếng nước rền chuyển dần ra xa thung lũng.',
          );
        }
        if (!has('valve_wheel')) {
          return const GameAction('Trục van trống, thiếu một bánh đồng vừa vặn.');
        }
        if (selectedItem != 'valve_wheel') {
          return const GameAction(
            'Bánh van trong túi có lẽ vừa với trục này. Hãy chọn nó rồi chạm lại.',
          );
        }
        flags.add('valve_diverted');
        journal.add('Đã chuyển van phụ: nước trở về lòng sông cũ, tránh các ngôi làng.');
        return const GameAction(
          'Tôi lắp bánh đồng và xoay hết sức. Cả công trình rung chuyển, rồi '
          'tiếng nước đổi hướng. Dòng lũ đã được dẫn về lòng sông cũ.',
        );

      case 'service_exit':
        if (!has('jade_seal')) {
          return const GameAction('Ổ khóa hình rồng chưa có ngọc ấn.');
        }
        final successful = did('valve_diverted') &&
            has('decree') &&
            has('letter_mai') &&
            did('canal_read');
        ending = successful ? EndingType.trueEnding : EndingType.ordinary;
        return GameAction(
          successful
              ? 'Tôi mang sắc chỉ và thư Mai ra khỏi đường hầm. Nước đã về sông cũ. '
                'Những cái tên từng bị xóa cuối cùng có cơ hội được nhớ đến.'
              : 'Tôi tìm thấy lối đi hẹp và thoát ra. Nhưng tiếng nước vẫn gầm trong '
                'lòng núi; bí mật của triều đình vẫn nằm dưới đó.',
          ending: ending,
        );

      case 'main_gate':
        if (did('valve_diverted')) {
          return const GameAction(
            'Cửa chính không còn áp lực nước. Tôi không cần mạo hiểm mở nó; '
            'đường hầm bên phải đã an toàn.',
          );
        }
        ending = EndingType.bad;
        return const GameAction(
          'Tôi giật cần xả. Cánh cổng mở toang. Từ đường hầm vọng tới tiếng '
          'chuông báo lũ của ba ngôi làng. Lời Mai cảnh báo đã quá muộn.',
          ending: EndingType.bad,
        );

      default:
        return const GameAction('Chỉ có đá lạnh và tiếng gió.');
    }
  }

  bool solveGlyphs(List<String> answer) {
    if (did('glyph_solved')) return true;
    if (!_equal(answer, glyphAnswer)) return false;
    flags.add('glyph_solved');
    _take('bronze_stylus', 'Giải khóa ba biểu tượng; lấy được kim đồng.');
    return true;
  }

  bool solveChest(String answer) {
    if (did('chest_solved')) return true;
    if (answer.trim() != chestAnswer) return false;
    flags.add('chest_solved');
    _take('jade_seal', 'Trong rương có ngọc ấn hình rồng, vừa ổ khóa Thủy Môn.');
    _take(
      'decree',
      'Sắc chỉ: triều đình ra lệnh xả lũ về ba làng để bảo vệ kinh thành. '
      'Sau đó họ xóa tên người chịu nạn.',
    );
    return true;
  }

  bool solveStars(List<String> answer) {
    if (did('stars_solved')) return true;
    if (!has('bronze_stylus') || !_equal(answer, starsAnswer)) return false;
    flags.add('stars_solved');
    _take('valve_wheel', 'Bàn tinh tượng mở ra, để lộ bánh van đồng của hệ thống nước.');
    return true;
  }

  static bool _equal(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  String hint({int tier = 0}) {
    final suggestions = <List<String>>[
      if (!did('glyph_solved'))
        [
          'Hãy đọc bia đá ở Tiền điện. Trên đó có một thứ tự gồm ba hình.',
          'Ấn lần lượt Mặt Trời → Núi → Trăng trên khóa tam tượng.',
        ]
      else if (!did('chest_solved'))
        [
          'Sổ đăng bộ và bia đá nói về cùng ba đoàn thuyền. Hãy đọc cả hai.',
          'Rương ngọc có mật mã 421: bốn, hai, một ngọn đèn.',
        ]
      else if (!did('mural_read') || !has('letter_mai'))
        [
          'Đừng bỏ qua hai chỗ kín trong Tàng thư. Đồ đang mang có thể soi hoặc mở chúng.',
          'Chọn đèn dầu để soi vách; chọn kim đồng để gạt then hộc thư.',
        ]
      else if (!did('stars_solved'))
        [
          'Bàn tinh tượng cần kim đồng. Ký hiệu trên vách Tàng thư là một lộ trình.',
          'Xoay theo Trăng → Sông → Mặt Trời để lấy bánh van.',
        ]
      else if (!did('valve_diverted'))
        [
          'Đọc bản đồ nước ở Tinh điện trước khi mở cổng chính.',
          'Đến Thủy Môn, chọn bánh van đồng rồi chạm van phụ.',
        ]
      else
        [
          'Bạn đã đổi hướng dòng nước. Hãy kiểm tra xem mình đã có đủ bằng chứng chưa.',
          'Mang cả sắc chỉ và thư Mai, đọc bản đồ nước, rồi dùng lối thoát phụ.',
        ],
    ];
    return suggestions.first[tier.clamp(0, 1)];
  }

  Map<String, dynamic> toMap() => {
        'schema': 1,
        'scene': scene,
        'inventory': inventory.toList()..sort(),
        'flags': flags.toList()..sort(),
        'journal': journal,
        'ending': ending?.name,
      };

  String serialize() => jsonEncode(toMap());

  factory GameSession.deserialize(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid save data');
    }
    if (decoded['schema'] != 1) {
      throw const FormatException('Unsupported save schema');
    }
    final session = GameSession();
    final index = decoded['scene'];
    if (index is int && index >= 0 && index <= 3) session.scene = index;
    for (final item in (decoded['inventory'] as List<dynamic>? ?? [])) {
      if (item is String) session.inventory.add(item);
    }
    for (final flag in (decoded['flags'] as List<dynamic>? ?? [])) {
      if (flag is String) session.flags.add(flag);
    }
    for (final entry in (decoded['journal'] as List<dynamic>? ?? [])) {
      if (entry is String) session.journal.add(entry);
    }
    for (final value in EndingType.values) {
      if (value.name == decoded['ending']) session.ending = value;
    }
    return session;
  }
}
