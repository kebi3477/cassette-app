import 'package:flutter/material.dart';

import '../../../domain/models/tape_type.dart';
import '../../core/ui/tab_placeholder.dart';

/// 상점 탭 — 다음 단계에서 만든다.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, this.highlight});

  /// 녹음 탭에서 0개인 테이프를 눌러 들어왔을 때 강조할 테이프 (`hl`)
  final TapeType? highlight;

  @override
  Widget build(BuildContext context) => const TabPlaceholder(title: '상점');
}
