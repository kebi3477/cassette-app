import 'dart:io';

import 'package:flutter/services.dart';

/// 위젯 시험에서도 실제 SUIT 글꼴로 레이아웃을 재도록 불러온다.
Future<void> loadAppFonts() async {
  final loader = FontLoader('SUIT');
  for (final w in const [
    'Light',
    'Regular',
    'Medium',
    'SemiBold',
    'Bold',
    'ExtraBold',
  ]) {
    final bytes = File('assets/fonts/SUIT-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
