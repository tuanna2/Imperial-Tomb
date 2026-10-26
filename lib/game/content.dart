import 'package:flutter/material.dart';

class TombHotspot {
  const TombHotspot(this.id, this.label, this.x, this.y, this.icon);
  final String id;
  final String label;

  /// Center in the source artwork, normalized independently of screen size.
  final double x;
  final double y;
  final IconData icon;
}

class TombScene {
  const TombScene(this.title, this.subtitle, this.asset, this.hotspots);
  final String title;
  final String subtitle;
  final String asset;
  final List<TombHotspot> hotspots;
}

const scenes = <TombScene>[
  TombScene('TIỀN ĐIỆN', '01 / Lời thề khắc trong đá', 'vestibule', [
    TombHotspot('stele', 'Bia đá', .22, .43, Icons.article_outlined),
    TombHotspot('lantern', 'Đèn dầu', .15, .62, Icons.lightbulb_outline),
    TombHotspot('glyph_lock', 'Khóa tam tượng', .83, .60, Icons.lock_outline),
    TombHotspot('vent', 'Khe thông gió', .82, .20, Icons.air),
  ]),
  TombScene('TÀNG THƯ', '02 / Những tên người bị xóa', 'archive', [
    TombHotspot(
      'dark_mural',
      'Vách ám đen',
      .48,
      .28,
      Icons.visibility_outlined,
    ),
    TombHotspot('ledger', 'Sổ đăng bộ', .20, .65, Icons.menu_book_outlined),
    TombHotspot('alcove', 'Hộc thư', .83, .37, Icons.mail_outline),
    TombHotspot('jade_chest', 'Rương ngọc', .67, .62, Icons.lock_outline),
    TombHotspot('supplies', 'Bàn bảo tồn', .30, .70, Icons.brush_outlined),
  ]),
  TombScene('TINH ĐIỆN', '04 / Ánh sáng đọc ký ức', 'observatory', [
    TombHotspot('canal_map', 'Bản đồ nước', .20, .30, Icons.map_outlined),
    TombHotspot('mirror', 'Gương đồng', .87, .30, Icons.brightness_2_outlined),
    TombHotspot('orrery', 'Bàn tinh tượng', .65, .57, Icons.settings_outlined),
    TombHotspot(
      'mirror_stand',
      'Giá phản quang',
      .17,
      .80,
      Icons.wb_sunny_outlined,
    ),
  ]),
  TombScene('THỦY MÔN', '06 / Dòng sông trở về', 'floodgate', [
    TombHotspot(
      'inscription',
      'Bia phong ấn',
      .14,
      .33,
      Icons.article_outlined,
    ),
    TombHotspot(
      'main_gate',
      'Cần xả chính',
      .25,
      .46,
      Icons.warning_amber_outlined,
    ),
    TombHotspot('side_valve', 'Van phụ', .17, .66, Icons.settings_outlined),
    TombHotspot('service_exit', 'Đường hầm', .90, .55, Icons.logout_outlined),
  ]),
  TombScene('GIẾNG TRỜI', '03 / Dấu tay của Mai', 'courtyard', [
    TombHotspot('well', 'Giếng sâu', .49, .62, Icons.water_outlined),
    TombHotspot(
      'lotus_relief',
      'Phù điêu sen',
      .29,
      .29,
      Icons.local_florist_outlined,
    ),
    TombHotspot('rope', 'Dây thừng', .15, .72, Icons.gesture),
    TombHotspot('basin', 'Máng nước', .88, .52, Icons.waves),
  ]),
  TombScene('CÔNG PHÒNG', '05 / Người chế tạo', 'workshop', [
    TombHotspot('engineer_plan', 'Bản thiết kế', .32, .23, Icons.architecture),
    TombHotspot('balance_cabinet', 'Tủ đối trọng', .83, .30, Icons.balance),
    TombHotspot('pump', 'Máy bơm', .86, .65, Icons.plumbing),
    TombHotspot('drawer', 'Sơ đồ đường ống', .12, .68, Icons.grid_on),
  ]),
];
const roomOrder = [0, 1, 4, 2, 5, 3];
const itemLabels = <String, String>{
  'oil_lamp': 'Đèn dầu',
  'bronze_stylus': 'Kim đồng',
  'jade_seal': 'Ngọc ấn',
  'decree': 'Sắc chỉ',
  'letter_mai': 'Thư Mai',
  'brush': 'Chổi mềm',
  'rubbing_paper': 'Giấy và than',
  'rope': 'Dây thừng',
  'hook': 'Móc sắt',
  'hooked_rope': 'Dây có móc',
  'sealed_tin': 'Hộp thiếc',
  'brass_key': 'Chìa đồng',
  'cloth': 'Vải khô',
  'oiled_cloth': 'Vải thấm dầu',
  'mirror_disk': 'Gương xỉn',
  'polished_mirror': 'Gương sạch',
  'wheel_core': 'Lõi bánh van',
  'wheel_handle': 'Tay quay',
  'valve_wheel': 'Bánh van',
  'wrench': 'Cờ lê',
  'village_rubbing': 'Bản dập tên làng',
};
const itemDescriptions = <String, String>{
  'oil_lamp':
      'Nguồn sáng cầm tay. Dầu trong bầu cũng có thể thấm lên vải khô để lau đồng.',
  'bronze_stylus':
      'Kim đồng đầu nhọn. Nạy mép hộp, gạt then hộc thư, tháo chốt gương và lắp trục tinh tượng.',
  'jade_seal': 'Ấn hình rồng của người quản thủy. Có thể mở cửa Tinh điện.',
  'decree':
      'Mệnh lệnh chuyển dòng lũ cứu kinh thành. Cần đối chiếu với tên các làng đã bị xóa.',
  'letter_mai':
      '“An, chị còn sống. Sông cũ 3 – Bể lắng 1 – Đối lưu 2. Đừng quên sao lại tên làng.”',
  'brush':
      'Chổi mềm để phủi muội than mà không xước nét khắc. Không đủ để tẩy gỉ trên gương.',
  'rubbing_paper':
      'Giấy dó và than. Đặt lên nét khắc đã nhìn rõ để giữ lại một bản sao.',
  'rope': 'Dây thừng còn chắc, đầu dây chưa có móc.',
  'hook': 'Móc sắt có lỗ buộc dây, vừa với quai hộp dưới giếng.',
  'hooked_rope': 'Dây đã buộc móc chắc chắn, có thể kéo vật ngoài tầm với.',
  'sealed_tin': 'Hộp thiếc kín nước. Nắp có mép gấp, cần vật nhọn để nạy.',
  'brass_key': 'Chìa khóa Mai để lại; hình răng khớp cửa Công phòng.',
  'cloth': 'Vải mềm khô. Có thể thấm một chút dầu để lau kim loại.',
  'oiled_cloth': 'Vải đã thấm dầu, có thể lau mặt gương bị ôxi hóa.',
  'mirror_disk':
      'Gương đồng xỉn. Không nên cào bằng đầu kim; cần vải thấm dầu.',
  'polished_mirror': 'Gương đã sạch, vừa giá phản quang trong Tinh điện.',
  'wheel_core': 'Lõi bánh đồng. Còn thiếu tay quay chịu lực.',
  'wheel_handle': 'Tay quay có đầu vuông, khớp với lõi bánh đồng.',
  'valve_wheel': 'Bánh van hoàn chỉnh, dùng cho trục vuông ở Thủy môn.',
  'wrench': 'Cờ lê vuông vừa đai ốc tấm che máy bơm.',
  'village_rubbing':
      'Đông Lâm, Vạn Khê, Hạ Thủy. Những tên làng bị xóa đã có bản sao.',
};
const itemIcons = <String, IconData>{
  'oil_lamp': Icons.lightbulb_outline,
  'bronze_stylus': Icons.edit_outlined,
  'jade_seal': Icons.diamond_outlined,
  'decree': Icons.description_outlined,
  'letter_mai': Icons.mail_outline,
  'brush': Icons.brush_outlined,
  'rubbing_paper': Icons.note_outlined,
  'rope': Icons.gesture,
  'hook': Icons.anchor,
  'hooked_rope': Icons.anchor,
  'sealed_tin': Icons.inventory_2_outlined,
  'brass_key': Icons.key,
  'cloth': Icons.check_box_outline_blank,
  'oiled_cloth': Icons.water_drop_outlined,
  'mirror_disk': Icons.circle_outlined,
  'polished_mirror': Icons.brightness_5_outlined,
  'wheel_core': Icons.trip_origin,
  'wheel_handle': Icons.handyman_outlined,
  'valve_wheel': Icons.settings_outlined,
  'wrench': Icons.build_outlined,
  'village_rubbing': Icons.receipt_long_outlined,
};
const symbolLabels = {
  'sun': 'Mặt Trời',
  'mountain': 'Núi',
  'moon': 'Trăng',
  'river': 'Sông',
  'north': 'Bắc',
  'east': 'Đông',
  'south': 'Nam',
  'west': 'Tây',
};
const symbolIcons = <String, IconData>{
  'sun': Icons.wb_sunny_outlined,
  'mountain': Icons.terrain_outlined,
  'moon': Icons.nightlight_round,
  'river': Icons.water_outlined,
  'north': Icons.arrow_upward,
  'east': Icons.arrow_forward,
  'south': Icons.arrow_downward,
  'west': Icons.arrow_back,
};
