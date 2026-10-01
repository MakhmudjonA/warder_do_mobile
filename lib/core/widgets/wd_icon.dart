import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../constants/app_icons.dart';
import '../theme/app_colors.dart';

/// HugeIcons ikonkasini chizadigan yagona wrapper — Flutterning `Icon` widgeti
/// o'rniga ishlatiladi.
///
/// Rang berilmasa `IconTheme` dan oladi, shuning uchun `IconButton`,
/// `ListTile` kabi rangni o'zi uzatadigan joylarda avvalgidek ishlaydi.
class WdIcon extends StatelessWidget {
  const WdIcon(this.icon, {this.size = 24, this.color, super.key});

  final AppIconData icon;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // `UnconstrainedBox` — ota-widget tight cheklov bergan bo'lsa ham (masalan
    // 44x44 yumaloq tugma) SVG rasm o'sha katakni to'ldirib cho'zilib ketmaydi.
    // Ikonka aynan [size] da qoladi va markazga joylashadi.
    return UnconstrainedBox(
      child: HugeIcon(
        icon: icon,
        size: size,
        color: color ?? IconTheme.of(context).color ?? AppColors.textPrimary,
      ),
    );
  }
}
