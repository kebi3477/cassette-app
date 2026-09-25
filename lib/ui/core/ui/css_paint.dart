import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// CSS 도형을 CustomPainter로 옮길 때 쓰는 도우미.
abstract final class CssPaint {
  /// `linear-gradient(<angle>deg, …)`를 [rect]에 맞춘 셰이더.
  ///
  /// CSS 각도: 0deg = 위쪽, 90deg = 오른쪽, 180deg = 아래쪽.
  static Shader linearGradient(
    Rect rect,
    double angleDeg,
    List<Color> colors, [
    List<double>? stops,
  ]) {
    final a = angleDeg * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final half =
        ((rect.width * math.sin(a)).abs() + (rect.height * math.cos(a)).abs()) /
        2;
    final c = rect.center;
    return ui.Gradient.linear(c - dir * half, c + dir * half, colors, stops);
  }

  /// `box-shadow: inset <dx> <dy> <blur> <spread> <color>`.
  static void insetShadow(
    Canvas canvas,
    RRect shape, {
    Offset offset = Offset.zero,
    double blur = 0,
    double spread = 0,
    required Color color,
  }) {
    canvas.save();
    canvas.clipRRect(shape);
    final hole = shape.deflate(spread).shift(offset);
    final outer = Path()..addRect(shape.outerRect.inflate(blur * 2 + 20));
    final path = Path.combine(
      PathOperation.difference,
      outer,
      Path()..addRRect(hole),
    );
    final paint = Paint()..color = color;
    if (blur > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur / 2);
    }
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  /// `box-shadow: 0 0 0 <width> <color>` (바깥 테두리 링).
  static void ring(Canvas canvas, RRect shape, double width, Color color) {
    final path = Path.combine(
      PathOperation.difference,
      Path()..addRRect(shape.inflate(width)),
      Path()..addRRect(shape),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  /// `repeating-linear-gradient`로 만든 줄무늬.
  /// [vertical]이 참이면 가로줄이 위에서 아래로 반복된다.
  static void stripes(
    Canvas canvas,
    Rect rect, {
    required double line,
    required double period,
    required Color color,
    bool vertical = false,
  }) {
    final paint = Paint()..color = color;
    canvas.save();
    canvas.clipRect(rect);
    if (vertical) {
      for (var y = rect.top; y < rect.bottom; y += period) {
        canvas.drawRect(Rect.fromLTWH(rect.left, y, rect.width, line), paint);
      }
    } else {
      for (var x = rect.left; x < rect.right; x += period) {
        canvas.drawRect(Rect.fromLTWH(x, rect.top, line, rect.height), paint);
      }
    }
    canvas.restore();
  }
}
