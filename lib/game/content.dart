import 'package:flutter/material.dart';

class TombHotspot {
  const TombHotspot(this.id, this.label, this.x, this.y, this.icon);

  final String id;
  final String label;
  final double x;
  final double y;
  final IconData icon;
}

class TombScene {
  const TombScene(this.title, this.subtitle, this.hotspots);

  final String title;
  final String subtitle;
  final List<TombHotspot> hotspots;
}

const scenes = <TombScene>[
  TombScene('TIỀN ĐIỆN', 'Lời thề khắc trong đá', [
    TombHotspot('stele', 'Bia đá', .11, .22, Icons.article_outlined),
    TombHotspot('lantern', 'Đèn dầu', .06, .66, Icons.lightbulb_outline),
    TombHotspot('glyph_lock', 'Khóa tam tượng', .53, .66, Icons.lock_outline),
  ]),
  TombScene('TÀNG THƯ', 'Những tên người bị xóa', [
    TombHotspot('dark_mural', 'Vách ám đen', .34, .24, Icons.visibility_outlined),
    TombHotspot('ledger', 'Sổ đăng bộ', .06, .43, Icons.menu_book_outlined),
    TombHotspot('alcove', 'Hộc thư', .62, .49, Icons.mark_email_unread_outlined),
    TombHotspot('jade_chest', 'Rương ngọc', .49, .75, Icons.lock_outline),
  ]),
  TombScene('TINH ĐIỆN', 'Bầu trời dưới lòng đất', [
    TombHotspot('canal_map', 'Bản đồ nước', .07, .22, Icons.map_outlined),
    TombHotspot('mirror', 'Gương đồng', .62, .29, Icons.brightness_2_outlined),
    TombHotspot('orrery', 'Bàn tinh tượng', .37, .66, Icons.settings_outlined),
  ]),
  TombScene('THỦY MÔN', 'Sự thật sau cánh cổng', [
    TombHotspot('inscription', 'Bia phong ấn', .05, .22, Icons.article_outlined),
    TombHotspot('main_gate', 'Cửa xả chính', .34, .36, Icons.warning_amber_outlined),
    TombHotspot('side_valve', 'Van phụ', .07, .70, Icons.settings_outlined),
    TombHotspot('service_exit', 'Đường hầm', .61, .71, Icons.logout_outlined),
  ]),
];

const itemLabels = <String, String>{
  'oil_lamp': 'Đèn dầu',
  'bronze_stylus': 'Kim đồng',
  'jade_seal': 'Ngọc ấn',
  'decree': 'Sắc chỉ',
  'letter_mai': 'Thư Mai',
  'valve_wheel': 'Bánh van',
};

const itemIcons = <String, IconData>{
  'oil_lamp': Icons.lightbulb,
  'bronze_stylus': Icons.edit_outlined,
  'jade_seal': Icons.diamond_outlined,
  'decree': Icons.description_outlined,
  'letter_mai': Icons.mail_outline,
  'valve_wheel': Icons.settings_outlined,
};

const symbolLabels = <String, String>{
  'sun': 'Mặt Trời',
  'mountain': 'Núi',
  'moon': 'Trăng',
  'river': 'Sông',
};

const symbolIcons = <String, IconData>{
  'sun': Icons.wb_sunny_outlined,
  'mountain': Icons.terrain_outlined,
  'moon': Icons.nightlight_round,
  'river': Icons.water_outlined,
};
