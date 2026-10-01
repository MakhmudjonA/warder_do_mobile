import 'package:flutter/material.dart';

import '../constants/habit_icons.dart';
import '../constants/habit_visuals.dart';

/// Odat ikonkasi iOS uslubida: odat rangidagi yumaloq kvadrat, ichida glif.
///
/// Bitta vidjet butun ilovada — karta, ro'yxat, shablon, tanlagich — shunda
/// ikonka hamma joyda bir xil ko'rinadi.
class HabitIconTile extends StatelessWidget {
  const HabitIconTile({
    required this.iconKey,
    this.color,
    this.size = 40,
    this.onColor = false,
    super.key,
  });

  final String? iconKey;

  /// Hex (`"#4FA8E8"`). `null` — standart rang.
  final String? color;

  final double size;

  /// Rangli fon ustida (masalan tanlangan karta): fon oq-shaffof bo'ladi.
  final bool onColor;

  @override
  Widget build(BuildContext context) {
    final background = onColor
        ? Colors.white.withValues(alpha: 0.22)
        : HabitColors.parse(color);
    // Och rang (oq, sariq) ustida oq glif ko'rinmaydi — to'q qilamiz.
    final glyphColor = !onColor && background.computeLuminance() > 0.6
        ? const Color(0xFF1C1C1E)
        : Colors.white;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: background,
        // iOS ikonkalaridagi "squircle"ga yaqin shakl.
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
      ),
      child: Icon(
        HabitIcons.resolve(iconKey),
        size: size * 0.56,
        color: glyphColor,
      ),
    );
  }
}
