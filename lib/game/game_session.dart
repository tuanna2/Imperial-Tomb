import 'dart:convert';

/// Rules are independent of rendering. Every reward has a single source.
enum PuzzleType {
  glyphs,
  ledgerCode,
  lotus,
  mirror,
  stars,
  balance,
  pipes,
  pressure,
}

enum EndingType { bad, ordinary, trueEnding }

class GameAction {
  const GameAction(this.message, {this.puzzle, this.ending});
  final String message;
  final PuzzleType? puzzle;
  final EndingType? ending;
}

class GameSession {
  GameSession();
  int scene = 0;
  EndingType? ending;
  final Set<String> inventory = {};
  final Set<String> flags = {};
  final List<String> journal = [];
  final Map<String, List<int>> mechanisms = {};
  String? selectedItem;

  static const glyphAnswer = ['sun', 'mountain', 'moon'];
  static const starsAnswer = ['moon', 'river', 'sun'];
  static const lotusAnswer = ['south', 'east', 'north', 'west'];
  static const chestAnswer = '421';
  static const hotspotRooms = <String, int>{
    'stele': 0,
    'lantern': 0,
    'glyph_lock': 0,
    'vent': 0,
    'ledger': 1,
    'dark_mural': 1,
    'alcove': 1,
    'jade_chest': 1,
    'supplies': 1,
    'canal_map': 2,
    'mirror': 2,
    'orrery': 2,
    'mirror_stand': 2,
    'inscription': 3,
    'main_gate': 3,
    'side_valve': 3,
    'service_exit': 3,
    'well': 4,
    'lotus_relief': 4,
    'rope': 4,
    'basin': 4,
    'engineer_plan': 5,
    'balance_cabinet': 5,
    'pump': 5,
    'drawer': 5,
  };
  static const puzzleRooms = <PuzzleType, int>{
    PuzzleType.glyphs: 0,
    PuzzleType.ledgerCode: 1,
    PuzzleType.lotus: 4,
    PuzzleType.mirror: 2,
    PuzzleType.stars: 2,
    PuzzleType.balance: 5,
    PuzzleType.pipes: 5,
    PuzzleType.pressure: 3,
  };

  bool has(String id) => inventory.contains(id);
  bool did(String id) => flags.contains(id);
  bool canEnter(int target) =>
      target >= 0 &&
      target < 6 &&
      (target != 2 || has('jade_seal')) &&
      (target != 3 || (has('jade_seal') && did('pump_fixed'))) &&
      (target != 5 || has('brass_key'));
  bool _at(int room) => ending == null && scene == room;
  void chooseItem(String item) {
    if (has(item) && ending == null) {
      selectedItem = selectedItem == item ? null : item;
    }
  }

  void _record(String flag, String text) {
    if (flags.add(flag)) journal.add(text);
  }

  void _take(String item, String text) {
    if (inventory.add(item)) journal.add(text);
  }

  void _consume(String item) {
    inventory.remove(item);
    if (selectedItem == item) selectedItem = null;
  }

  GameAction navigate(int target) {
    if (ending != null) return const GameAction('Câu chuyện đã kết thúc.');
    if (!canEnter(target)) {
      return GameAction(switch (target) {
        2 =>
          'Cửa Tinh điện có hốc hình rồng. Ngọc ấn trong rương có thể mở nó.',
        3 =>
          'Cầu đá xuống Thủy môn đang ngập. Cần sửa máy bơm trong Công phòng trước.',
        5 => 'Công phòng bị khóa. Mai đánh dấu một chiếc hộp dưới giếng trời.',
        _ => 'Không có lối đi ở đây.',
      });
    }
    scene = target;
    selectedItem = null;
    return GameAction(
      const [
        'Tiền điện vắng quan tài. Tiếng nước vẫn vọng qua lớp đá dưới chân.',
        'Những thẻ tre ở đây ghi lượng nước và dân cư, không ghi lễ an táng.',
        'Một vệt sáng từ khe núi rơi xuống cỗ máy thiên văn bằng đồng.',
        'Cầu đá vừa lộ khỏi mặt nước. Phía sau cổng, cả một hồ nước đang chờ.',
        'Giếng trời đưa xuống chút ánh sáng. Có vết dây mới cọ trên thành giếng.',
        'Công phòng của người chế tạo. Trên bàn còn một công trình chưa hoàn tất.',
      ][target],
    );
  }

  GameAction combine(String first, String second) {
    if (ending != null || first == second || !has(first) || !has(second)) {
      return const GameAction('Cần hai vật phẩm khác nhau đang có trong túi.');
    }
    final pair = {first, second};
    bool isPair(String a, String b) => pair.contains(a) && pair.contains(b);
    if (isPair('rope', 'hook')) {
      _consume('rope');
      _consume('hook');
      _take(
        'hooked_rope',
        'Buộc móc sắt vào dây thừng; có thể kéo một vật dưới giếng.',
      );
      return const GameAction(
        'Tôi thắt nút hai vòng, kéo thử móc sắt. Sợi dây đã đủ chắc.',
      );
    }
    if (isPair('sealed_tin', 'bronze_stylus')) {
      _consume('sealed_tin');
      _take(
        'brass_key',
        'Hộp thiếc của Mai: chìa Công phòng và một mảnh vải khô.',
      );
      _take('cloth', 'Mảnh vải được Mai gói trong hộp kín để tránh ẩm.');
      _record(
        'tin_note',
        'Mảnh ghi chú trong hộp: “Bản thiết kế trong Công phòng chỉ cách đặt gương. Đừng lấy số trên vòng sao làm góc gương.”',
      );
      return const GameAction(
        'Kim đồng nạy bật mép hộp. Bên trong có chìa khóa, vải khô và ghi chú của Mai.',
      );
    }
    if (isPair('cloth', 'oil_lamp')) {
      _consume('cloth');
      _take(
        'oiled_cloth',
        'Thấm một ít dầu lên vải. Đèn vẫn còn đủ dầu để soi vách.',
      );
      return const GameAction(
        'Một ít dầu làm mềm lớp ôxi hóa mà không cào xước mặt đồng.',
      );
    }
    if (isPair('mirror_disk', 'oiled_cloth')) {
      _consume('mirror_disk');
      _consume('oiled_cloth');
      _take(
        'polished_mirror',
        'Đánh sạch gương đồng. Mặt gương có ba vòng chia tám vạch.',
      );
      return const GameAction(
        'Lớp xanh bong ra trên vải. Gương đủ sáng để hắt ánh trời lên bản đồ.',
      );
    }
    if (isPair('wheel_core', 'wheel_handle')) {
      _consume('wheel_core');
      _consume('wheel_handle');
      _take(
        'valve_wheel',
        'Lắp tay quay vào lõi bánh đồng; khớp vuông khóa chặt.',
      );
      return const GameAction(
        'Tay quay khớp vào lõi. Bánh van đã hoàn chỉnh và chịu được lực.',
      );
    }
    return const GameAction(
      'Hai vật này không khớp. Tôi giữ nguyên chúng trong túi.',
    );
  }

  GameAction inspect(String id) {
    if (ending != null) return const GameAction('Câu chuyện đã kết thúc.');
    if (hotspotRooms[id] != scene) {
      return const GameAction('Vật đó không ở trong phòng này.');
    }
    switch (id) {
      case 'lantern':
        _take(
          'oil_lamp',
          'Lấy đèn dầu ở Tiền điện. Bấc vẫn cháy được, dầu còn khoảng nửa bầu.',
        );
        return const GameAction(
          'Đèn dầu đủ sáng để soi chữ chìm. Dầu cũng có thể dùng để làm sạch đồng.',
        );
      case 'stele':
        _record(
          'stele_read',
          'Lời thề: Mặt Trời → Núi → Trăng. Đoàn thuyền II có HAI ngọn đuốc.',
        );
        return const GameAction(
          '“Mặt Trời dẫn đường, Núi che lưng, Trăng giữ lời thề.” Dưới bia, đoàn thuyền II mang hai ngọn đuốc.',
        );
      case 'vent':
        return const GameAction(
          'Gió từ giếng trời luồn vào đây. Vết dây thừng còn mới; Mai đã đi xa hơn Tiền điện.',
        );
      case 'glyph_lock':
        return GameAction(
          did('glyph_solved')
              ? 'Hộc đá đã mở. Kim đồng được cất trong túi.'
              : 'Ba đĩa đá có thể ấn theo thứ tự lời thề.',
          puzzle: did('glyph_solved') ? null : PuzzleType.glyphs,
        );
      case 'supplies':
        _take('brush', 'Lấy chổi mềm trên bàn Tàng thư, dùng phủi muội than.');
        _take('rubbing_paper', 'Lấy giấy dó và thỏi than để sao lại chữ khắc.');
        return const GameAction(
          'Chổi mềm, giấy dó và than. Người làm công tác bảo tồn đã để chúng ở đây.',
        );
      case 'ledger':
        _record(
          'ledger_read',
          'Đăng bộ: đoàn I BỐN đèn, đoàn III MỘT đèn. Ô khóa đánh dấu I – II – III.',
        );
        return const GameAction(
          'Đoàn I: bốn đèn. Đoàn III: một đèn. Dòng về đoàn II bị cắt khỏi sổ, nhưng hình thuyền ấy còn trên bia Tiền điện.',
        );
      case 'jade_chest':
        return GameAction(
          did('chest_solved')
              ? 'Rương chỉ còn vải lót. Sắc chỉ và ngọc ấn đã được lấy.'
              : 'Ba bánh số trên rương đi theo thứ tự đoàn I, II, III.',
          puzzle: did('chest_solved') ? null : PuzzleType.ledgerCode,
        );
      case 'dark_mural':
        if (did('mural_read')) {
          return const GameAction(
            'Dưới muội than: Trăng → Sông → Mặt Trời. Đó là đường nước, không phải bầu trời.',
          );
        }
        if (!did('mural_clean')) {
          if (selectedItem != 'brush') {
            return const GameAction(
              'Muội than che kín nét khắc. Cần phủi bằng chổi mềm trước khi soi sáng.',
            );
          }
          _record(
            'mural_clean',
            'Phủi muội khỏi vách. Nét khắc quá nông, cần ánh sáng xiên để đọc.',
          );
          return const GameAction(
            'Chổi gạt lớp muội xuống. Giờ cần một nguồn sáng đặt sát vách.',
          );
        }
        if (selectedItem != 'oil_lamp') {
          return const GameAction(
            'Nét khắc đã sạch nhưng chìm trong bóng tối. Đưa đèn dầu sát mặt đá.',
          );
        }
        _record(
          'mural_read',
          'Vách Tàng thư: Trăng → Sông → Mặt Trời. Thứ tự đặt ba vòng tinh tượng.',
        );
        return const GameAction(
          'Ánh đèn xiên làm hiện ba nét khắc: Trăng soi Sông, Sông đưa Mặt Trời trở về.',
        );
      case 'alcove':
        if (has('letter_mai')) {
          return const GameAction(
            '“Chị còn sống khi viết những dòng này.” Nét bút của Mai không hề run.',
          );
        }
        if (selectedItem != 'bronze_stylus') {
          return const GameAction(
            'Then hộc quá mảnh. Một đầu kim đồng có thể gạt nó ra.',
          );
        }
        _take(
          'letter_mai',
          'Thư Mai: “Cửa lớn xả nước xuống làng. Lắp bánh van, đặt SÔNG CŨ 3 – BỂ LẮNG 1 – ĐỐI LƯU 2, rồi mới mở đường hầm. Hãy sao lại tên làng.”',
        );
        return const GameAction(
          'Thư Mai còn khô: “Chị còn sống. Van phụ: sông cũ 3, bể lắng 1, đối lưu 2. Mang sắc chỉ và tên ba làng ra ngoài.”',
        );
      case 'rope':
        if (!has('hooked_rope') && !did('well_retrieved')) {
          _take('rope', 'Nhặt sợi dây còn tốt trên ghế đá ở Giếng trời.');
        }
        return const GameAction(
          'Dây chịu lực tốt, nhưng đầu dây cần một chiếc móc để bắt được quai hộp.',
        );
      case 'lotus_relief':
        _record(
          'lotus_read',
          'Phù điêu sen: “Rễ xuống Nam, nụ đón Đông, thân vươn Bắc, lá ngả Tây.” Bốn nút theo phương hướng.',
        );
        return GameAction(
          did('lotus_solved')
              ? 'Hộc sau phù điêu đã mở, móc sắt đã được lấy.'
              : 'Rễ xuống Nam, nụ đón Đông, thân vươn Bắc, lá ngả Tây.',
          puzzle: did('lotus_solved') ? null : PuzzleType.lotus,
        );
      case 'well':
        if (did('well_retrieved')) {
          return const GameAction(
            'Quai hộp để lại một vòng gỉ trên thành giếng. Dưới đáy chỉ còn nước.',
          );
        }
        if (selectedItem != 'hooked_rope') {
          return const GameAction(
            'Một hộp thiếc mắc ở gờ bên trong, ngoài tầm tay. Cần dây dài có móc.',
          );
        }
        _record(
          'well_retrieved',
          'Kéo hộp thiếc kín khỏi giếng trời. Nắp hộp có mép gấp rất hẹp.',
        );
        _take(
          'sealed_tin',
          'Hộp thiếc kín nước, mép nắp đủ mảnh để nạy bằng kim.',
        );
        return const GameAction(
          'Móc bám vào quai. Tôi kéo lên một hộp kín; bên ngoài có dấu tay của Mai.',
        );
      case 'basin':
        return const GameAction(
          'Máng nước chạy về Công phòng. Máy bơm ở đó đang dừng, khiến cầu xuống Thủy môn ngập nước.',
        );
      case 'engineer_plan':
        _record(
          'plan_read',
          'Bản thiết kế: vòng gương ngoài 2, giữa 4, trong 1 (đếm tám vạch theo chiều kim đồng hồ từ đỉnh). Đối trọng: giữa = trái + phải; phải = trái + 1; tổng = 10.',
        );
        return const GameAction(
          'Gương: ngoài 2, giữa 4, trong 1. Tủ đối trọng: giữa bằng hai bên cộng lại; phải nặng hơn trái một; tổng ba quả là mười.',
        );
      case 'drawer':
        return const GameAction(
          'Ngăn kéo có bản vẽ đường ống: từ góc TRÊN TRÁI đi hết hàng trên, vòng xuống hàng dưới rồi ra ở DƯỚI TRÁI. Mỗi ống phải nối kín, không có nhánh cụt.',
        );
      case 'balance_cabinet':
        return GameAction(
          did('balance_solved')
              ? 'Tủ đã nhả tay quay và cờ lê. Cả ba đòn cân nằm ngang.'
              : 'Ba đối trọng có thể đổi khối lượng từ 1 đến 6. Quy tắc cân nằm trên bản thiết kế.',
          puzzle: did('balance_solved') ? null : PuzzleType.balance,
        );
      case 'pump':
        if (did('pump_fixed')) {
          return const GameAction(
            'Máy bơm đã chạy. Cầu xuống Thủy môn đã rút hết nước.',
          );
        }
        if (!did('pump_open')) {
          if (selectedItem != 'wrench') {
            return const GameAction(
              'Tấm che máy bơm bị giữ bởi đai ốc vuông. Cần cờ lê trong tủ đối trọng.',
            );
          }
          _record(
            'pump_open',
            'Tháo tấm che máy bơm bằng cờ lê. Sáu đoạn ống đang xoay sai hướng.',
          );
        }
        return const GameAction(
          'Xoay các đoạn ống, nối từ đầu vào trên trái đến đầu ra dưới trái. Không được rò nước.',
          puzzle: PuzzleType.pipes,
        );
      case 'mirror':
        if (has('polished_mirror') || did('mirror_installed')) {
          return const GameAction('Giá treo gương chỉ còn một vòng bụi.');
        }
        if (selectedItem != 'bronze_stylus') {
          return const GameAction(
            'Gương đồng ôxi hóa treo trên chốt nhỏ. Kim đồng có thể gỡ chốt.',
          );
        }
        flags.add('mirror_taken');
        _take(
          'mirror_disk',
          'Gỡ gương đồng khỏi chốt. Lớp ôxi hóa cần vải thấm dầu, không dùng chổi khô.',
        );
        return const GameAction(
          'Tấm gương đã rời giá. Cần đánh sạch mặt gương trước khi phản chiếu ánh trời.',
        );
      case 'mirror_stand':
        if (did('mirror_aligned')) {
          return const GameAction(
            'Ba tia sáng cùng rơi lên những dòng tên bị xóa trên bản đồ.',
          );
        }
        if (!did('mirror_installed')) {
          if (selectedItem != 'polished_mirror') {
            return const GameAction(
              'Giá phản quang trống. Một tấm gương đã đánh sạch sẽ vừa khít.',
            );
          }
          _consume('polished_mirror');
          _record(
            'mirror_installed',
            'Lắp gương lên giá phản quang; ba vòng chỉnh có tám vạch mỗi vòng.',
          );
        }
        return const GameAction(
          'Chỉnh ba vòng theo bản thiết kế trong Công phòng. Vạch 0 ở đỉnh, đếm theo chiều kim đồng hồ.',
          puzzle: PuzzleType.mirror,
        );
      case 'canal_map':
        if (!did('mirror_aligned')) {
          return const GameAction(
            'Bản đồ bị cạo mất một dải. Ánh sáng thẳng không làm hiện được nét đục cũ. Thử giá phản quang bên dưới.',
          );
        }
        _record(
          'canal_read',
          'Bản đồ dưới ánh sáng xiên: cửa chính → ba làng; van phụ → sông cũ. Ba tên bị xóa: Đông Lâm, Vạn Khê, Hạ Thủy.',
        );
        if (selectedItem == 'rubbing_paper' && !has('village_rubbing')) {
          _consume('rubbing_paper');
          _take(
            'village_rubbing',
            'Bản dập tên Đông Lâm, Vạn Khê, Hạ Thủy; chứng cứ đối chiếu với sắc chỉ.',
          );
          return const GameAction(
            'Tôi trải giấy dó, miết than lên những nét chìm. Tên ba làng hiện rõ trên bản dập.',
          );
        }
        return const GameAction(
          'Đông Lâm, Vạn Khê, Hạ Thủy. Cửa lớn xả về họ; nhánh phụ đưa nước về sông cũ. Cần giấy dó và than để lưu lại tên.',
        );
      case 'orrery':
        if (did('stars_solved')) {
          return const GameAction(
            'Hộc dưới vòng sao đã mở. Lõi bánh đồng cần thêm một tay quay.',
          );
        }
        if (!did('star_axis')) {
          if (selectedItem != 'bronze_stylus') {
            return const GameAction(
              'Trục giữa thiếu chốt. Chọn kim đồng rồi lắp vào trục.',
            );
          }
          _record(
            'star_axis',
            'Lắp kim đồng vào trục tinh tượng. Các vòng đã có thể xoay.',
          );
        }
        if (!did('mural_read')) {
          return const GameAction(
            'Vòng đã xoay được, nhưng tôi chưa đọc ra lộ trình trên vách Tàng thư.',
          );
        }
        if (!did('mirror_aligned')) {
          return const GameAction(
            'Chốt an toàn chưa nhả. Ánh phản quang cần được chỉnh vào bản đồ trước.',
          );
        }
        return const GameAction(
          'Đặt ba vòng theo lộ trình từ vách Tàng thư.',
          puzzle: PuzzleType.stars,
        );
      case 'inscription':
        _record(
          'gate_read',
          'Chữ MỘ khắc đè lên chữ MÔN. Ba nhánh van: sông cũ, bể lắng, đối lưu; không phải cửa thoát hiểm.',
        );
        return const GameAction(
          'Dưới chữ “lăng mộ” là chữ “thủy môn”. Biển “THOÁT” trên cổng lớn chỉ hướng nước thoát ra ngoài.',
        );
      case 'side_valve':
        if (did('valve_diverted')) {
          return const GameAction(
            'Áp lực đã ổn định. Dòng lũ chuyển về sông cũ.',
          );
        }
        if (!did('wheel_installed')) {
          if (selectedItem != 'valve_wheel') {
            return const GameAction(
              'Trục vuông thiếu bánh van hoàn chỉnh. Lõi đồng và tay quay phải ghép lại trước.',
            );
          }
          _consume('valve_wheel');
          _record(
            'wheel_installed',
            'Lắp bánh van vào trục. Ba nhánh điều áp vẫn chưa đúng mức.',
          );
        }
        return const GameAction(
          'Ba nhánh điều áp đánh dấu: sông cũ, bể lắng, đối lưu. Mai đã ghi mức an toàn trong thư.',
          puzzle: PuzzleType.pressure,
        );
      case 'main_gate':
        if (did('valve_diverted')) {
          return const GameAction(
            'Nước đã đi qua nhánh phụ. Tôi có thể rời bằng đường hầm bảo trì.',
          );
        }
        ending = EndingType.bad;
        return const GameAction(
          'Tôi kéo cần. Dòng lũ rời lòng núi; tiếng chuông báo động vọng lên từ ba làng.',
          ending: EndingType.bad,
        );
      case 'service_exit':
        final complete = did('valve_diverted') &&
            has('decree') &&
            has('letter_mai') &&
            has('village_rubbing') &&
            did('canal_read');
        ending = complete ? EndingType.trueEnding : EndingType.ordinary;
        return GameAction(
          complete
              ? 'Dòng nước đã về sông cũ. Tôi ra ngoài với sắc chỉ, thư Mai và tên ba làng.'
              : 'Tôi thoát qua hầm bảo trì. Nhưng vẫn còn những việc chưa hoàn tất dưới lăng mộ.',
          ending: ending,
        );
      default:
        return const GameAction('Chỉ có tiếng nước sau lớp đá.');
    }
  }

  bool solveGlyphs(List<String> values) {
    if (!_at(0)) return false;
    if (did('glyph_solved')) return true;
    if (!_equal(values, glyphAnswer)) return false;
    _record('glyph_solved', 'Giải khóa tam tượng theo lời thề.');
    _take(
      'bronze_stylus',
      'Trong hộc đá có kim đồng, đủ cứng để gạt then và lắp chốt.',
    );
    return true;
  }

  bool solveChest(String value) {
    if (!_at(1)) return false;
    if (did('chest_solved')) return true;
    if (value.trim() != chestAnswer) return false;
    _record('chest_solved', 'Mở rương bằng số đèn ba đoàn thuyền: 421.');
    _take(
      'jade_seal',
      'Ngọc ấn mở cửa Tinh điện, mang ký hiệu của người quản thủy.',
    );
    _take(
      'decree',
      'Sắc chỉ ra lệnh đổi dòng lũ để cứu kinh thành, xóa tên ba làng khỏi đăng bộ.',
    );
    return true;
  }

  bool solveLotus(List<String> values) {
    if (!_at(4)) return false;
    if (did('lotus_solved')) return true;
    if (!_equal(values, lotusAnswer)) return false;
    _record('lotus_solved', 'Ấn Nam → Đông → Bắc → Tây. Hộc sen mở.');
    _take('hook', 'Một móc sắt trong hộc sen, đủ nhỏ để lọt qua miệng giếng.');
    return true;
  }

  bool solveMirror(List<int> values) {
    if (!_at(2) || !did('mirror_installed')) return false;
    if (!_equal(values, [2, 4, 1])) return false;
    _record(
      'mirror_aligned',
      'Ba vòng gương 2 – 4 – 1 hắt ánh sáng lên nét khắc bị xóa. Chốt tinh tượng nhả ra.',
    );
    return true;
  }

  bool solveStars(List<String> values) {
    if (!_at(2) ||
        !did('star_axis') ||
        !did('mirror_aligned') ||
        !did('mural_read')) {
      return false;
    }
    if (did('stars_solved')) return true;
    if (!_equal(values, starsAnswer)) return false;
    _record(
      'stars_solved',
      'Ba vòng tinh tượng đi theo Trăng → Sông → Mặt Trời.',
    );
    _take(
      'wheel_core',
      'Lõi bánh van đồng nằm dưới cỗ máy; còn thiếu tay quay chịu lực.',
    );
    return true;
  }

  bool solveBalance(List<int> values) {
    if (!_at(5) || values.length != 3 || values.any((n) => n < 1 || n > 6)) {
      return false;
    }
    if (values[1] != values[0] + values[2] ||
        values[2] != values[0] + 1 ||
        values.fold(0, (a, b) => a + b) != 10) {
      return false;
    }
    if (did('balance_solved')) return true;
    _record('balance_solved', 'Đối trọng 2 – 5 – 3 cân đúng các đòn. Tủ mở.');
    _take('wheel_handle', 'Tay quay đồng vừa khớp vuông trên lõi bánh van.');
    _take('wrench', 'Cờ lê vuông dùng tháo nắp máy bơm.');
    return true;
  }

  // Pipe bits: north=1, east=2, south=4, west=8. Rotation is clockwise.
  static int pipeMask(int tile, int rotation) {
    var mask = const [10, 10, 3, 3, 10, 3][tile];
    for (var i = 0; i < rotation % 4; i++) {
      mask = ((mask << 1) & 15) | (mask >> 3);
    }
    return mask;
  }

  static bool pipesConnected(List<int> values) {
    if (values.length != 6 || values.any((n) => n < 0 || n > 3)) return false;
    final masks = List.generate(6, (i) => pipeMask(i, values[i]));
    if ((masks[0] & 8) == 0 || (masks[3] & 4) == 0) return false;
    final seen = <int>{};
    final queue = <int>[0];
    while (queue.isNotEmpty) {
      final i = queue.removeLast();
      if (!seen.add(i)) continue;
      for (var d = 0; d < 4; d++) {
        if ((masks[i] & (1 << d)) == 0) continue;
        if ((i == 0 && d == 3) || (i == 3 && d == 2)) continue;
        final row = i ~/ 3 + const [-1, 0, 1, 0][d];
        final col = i % 3 + const [0, 1, 0, -1][d];
        if (row < 0 || row > 1 || col < 0 || col > 2) return false;
        final next = row * 3 + col;
        if ((masks[next] & (1 << ((d + 2) % 4))) == 0) return false;
        queue.add(next);
      }
    }
    return seen.length == 6;
  }

  bool solvePipes(List<int> values) {
    if (!_at(5) || !did('pump_open') || !pipesConnected(values)) return false;
    _record(
      'pump_fixed',
      'Nối kín sáu đoạn ống. Máy bơm rút nước khỏi cầu Thủy môn.',
    );
    return true;
  }

  bool solvePressure(List<int> values) {
    if (!_at(3) || !did('wheel_installed') || !_equal(values, [3, 1, 2])) {
      return false;
    }
    _record(
      'valve_diverted',
      'Đặt điều áp 3 – 1 – 2. Dòng lũ rời ba làng, trở về sông cũ.',
    );
    return true;
  }

  void saveMechanism(PuzzleType type, List<int> values) {
    mechanisms[type.name] = List<int>.of(values);
  }

  static bool _equal<T>(List<T> a, List<T> b) =>
      a.length == b.length &&
      List.generate(a.length, (i) => a[i] == b[i]).every((v) => v);

  String hint({int tier = 0}) {
    final pair = switch (0) {
      _ when !did('glyph_solved') => [
          'Bia Tiền điện mô tả thứ tự ba biểu tượng.',
          'Khóa tam tượng: Mặt Trời → Núi → Trăng.',
        ],
      _ when !did('chest_solved') => [
          'Ghép thông tin đèn trong sổ và hình thuyền trên bia.',
          'Rương Tàng thư: 421. Lấy cả đồ trên bàn.',
        ],
      _ when !has('brass_key') => [
          'Dấu vết Mai dẫn ra giếng trời. Cần lấy chiếc hộp mắc dưới giếng.',
          'Phù điêu: Nam → Đông → Bắc → Tây. Ghép dây + móc; dùng ở giếng. Ghép hộp thiếc + kim đồng.',
        ],
      _ when !did('plan_read') => [
          'Chìa của Mai mở Công phòng. Bản thiết kế có hai quy tắc quan trọng.',
          'Vào Công phòng, đọc bản thiết kế: gương 2–4–1 và quy tắc đối trọng.',
        ],
      _ when !did('mirror_aligned') => [
          'Gương ở Tinh điện cần được tháo, làm sạch và lắp đúng vị trí.',
          'Dùng kim lấy gương. Ghép vải + đèn dầu, rồi vải dầu + gương. Dùng gương sạch ở giá. Chỉnh 2–4–1.',
        ],
      _ when !did('mural_read') => [
          'Lớp muội và bóng tối là hai trở ngại khác nhau.',
          'Ở Tàng thư: lấy đồ trên bàn; dùng chổi trên vách rồi dùng đèn dầu.',
        ],
      _ when !did('stars_solved') => [
          'Bàn tinh tượng thiếu chốt; lộ trình nằm trên vách đã soi.',
          'Dùng kim đồng vào tinh tượng, đặt Trăng → Sông → Mặt Trời.',
        ],
      _ when !did('balance_solved') => [
          'Tủ Công phòng có ba đối trọng. Giữa bằng hai bên cộng lại.',
          'Trái 2, giữa 5, phải 3. Tủ có tay quay và cờ lê.',
        ],
      _ when !did('pump_fixed') => [
          'Cờ lê tháo nắp bơm. Đường ống phải đi qua đủ sáu đoạn.',
          'Dùng cờ lê lên bơm. Nối ngang hàng trên → xuống bên phải → ngang về trái → ra dưới trái.',
        ],
      _ when !has('letter_mai') => [
          'Còn một hộc thư chưa mở trong Tàng thư.',
          'Dùng kim đồng gạt then hộc thư để lấy thư Mai.',
        ],
      _ when !has('village_rubbing') => [
          'Những cái tên trên bản đồ cần được lưu lại làm bằng chứng.',
          'Đọc bản đồ Tinh điện sau khi chỉnh gương. Chọn giấy dó rồi dùng lên bản đồ để dập tên.',
        ],
      _ when !did('valve_diverted') => [
          'Bánh van cần một lõi và một tay quay. Thư Mai ghi mức điều áp.',
          'Ghép lõi + tay quay. Ở Thủy môn, dùng bánh van rồi đặt sông cũ 3, bể lắng 1, đối lưu 2.',
        ],
      _ => [
          'Mọi bằng chứng đã đủ. Đường hầm bảo trì là lối ra.',
          'Dùng đường hầm hẹp ở Thủy môn để kết thúc.',
        ],
    };
    return pair[tier > 0 ? 1 : 0];
  }

  String get objective => hint();
  Map<String, dynamic> toMap() => {
        'schema': 2,
        'scene': scene,
        'inventory': inventory.toList()..sort(),
        'flags': flags.toList()..sort(),
        'journal': journal,
        'ending': ending?.name,
        'mechanisms': mechanisms,
      };
  String serialize() => jsonEncode(toMap());
  factory GameSession.deserialize(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic> || ![1, 2].contains(data['schema'])) {
      throw const FormatException('Unsupported save');
    }
    final game = GameSession();
    final index = data['scene'];
    if (index is int && index >= 0 && index < 6) game.scene = index;
    for (final key in ['inventory', 'flags', 'journal']) {
      final list = data[key];
      if (list is! List) continue;
      for (final value in list.whereType<String>()) {
        if (key == 'inventory') game.inventory.add(value);
        if (key == 'flags') game.flags.add(value);
        if (key == 'journal') game.journal.add(value);
      }
    }
    if (data['mechanisms'] case final Map values) {
      for (final key in PuzzleType.values.map((e) => e.name)) {
        final value = values[key];
        if (value is List && value.every((n) => n is int)) {
          game.mechanisms[key] = value.cast<int>().toList();
        }
      }
    }
    for (final e in EndingType.values) {
      if (e.name == data['ending']) game.ending = e;
    }
    // Preserve a v1 journey, but require the new evidence and machinery for a true ending.
    if (data['schema'] == 1 && game.did('stars_solved')) {
      game.flags.addAll(['star_axis', 'mirror_aligned', 'mirror_installed']);
    }
    if (!game.canEnter(game.scene) && game.ending == null) game.scene = 0;
    return game;
  }
}
