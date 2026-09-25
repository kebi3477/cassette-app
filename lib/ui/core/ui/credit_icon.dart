import 'package:flutter/widgets.dart';

import 'app_icons.dart';

/// 크레딧 아이콘 (핸드오프 `icon-credit.svg`)
class CreditIcon extends StatelessWidget {
  const CreditIcon({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) =>
      SvgIcon(AppIcons.credit, width: size, height: size);
}
