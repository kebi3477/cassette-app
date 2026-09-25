import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 테이프 위 노이즈(`--grain`, `mix-blend-mode: overlay`).
///
/// - [GrainMode.once]: `grainOn 1.4s steps(8) forwards` — 변환 중
/// - [GrainMode.loop]: `grainLoop .4s steps(2) infinite`, 불투명도 .22 — 재생 중
enum GrainMode { once, loop }

class GrainOverlay extends StatefulWidget {
  const GrainOverlay({super.key, required this.mode, this.radius = 10});

  final GrainMode mode;
  final double radius;

  @override
  State<GrainOverlay> createState() => _GrainOverlayState();
}

class _GrainOverlayState extends State<GrainOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.mode == GrainMode.once
        ? const Duration(milliseconds: 1400)
        : const Duration(milliseconds: 400),
  );
  ui.Image? _noise;

  @override
  void initState() {
    super.initState();
    widget.mode == GrainMode.once ? _c.forward() : _c.repeat();
    _GrainTexture.image.then((img) {
      if (mounted) setState(() => _noise = img);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final double opacity;
          final Offset shift;
          if (widget.mode == GrainMode.once) {
            opacity = stepped(
              t,
              const [0, .2, .5, .8, 1],
              const [0, .5, .35, .45, 0],
              8,
            );
            shift = Offset(
              stepped(t, const [0, .5, .8, 1], const [0, -40, 30, 0], 8),
              stepped(t, const [0, .5, .8, 1], const [0, 30, -20, 0], 8),
            );
          } else {
            opacity = .22;
            shift = Offset(
              stepped(t, const [0, .33, .66, 1], const [0, -40, 30, 0], 2),
              stepped(t, const [0, .33, .66, 1], const [0, 20, -30, 0], 2),
            );
          }
          return CustomPaint(
            size: Size.infinite,
            painter: _GrainPainter(
              image: _noise,
              opacity: opacity,
              shift: shift,
              radius: widget.radius,
            ),
          );
        },
      ),
    );
  }
}

/// CSS `steps(n)`가 키프레임 구간마다 적용된 값.
double stepped(double t, List<double> stops, List<double> values, int steps) {
  if (t >= 1) return values.last;
  for (var i = 1; i < stops.length; i++) {
    if (t <= stops[i]) {
      final p = (t - stops[i - 1]) / (stops[i] - stops[i - 1]);
      final k = (p * steps).floor() / steps;
      return values[i - 1] + (values[i] - values[i - 1]) * k;
    }
  }
  return values.last;
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({
    required this.image,
    required this.opacity,
    required this.shift,
    required this.radius,
  });

  final ui.Image? image;
  final double opacity;
  final Offset shift;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final img = image;
    if (img == null || opacity <= 0) return;
    final rect = Offset.zero & size;
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final m = Matrix4.translationValues(shift.dx, shift.dy, 0).storage;
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.overlay
        ..color = Color.fromRGBO(0, 0, 0, opacity)
        ..shader = ImageShader(img, TileMode.repeated, TileMode.repeated, m),
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.image != image || old.opacity != opacity || old.shift != shift;
}

/// 160×160 흰색 노이즈 (원본 SVG feTurbulence + 알파 0.6).
abstract final class _GrainTexture {
  static const int _size = 160;
  static final Future<ui.Image> image = _build();

  static Future<ui.Image> _build() {
    final rnd = math.Random(7);
    final px = Uint8List(_size * _size * 4);
    for (var i = 0; i < _size * _size; i++) {
      px[i * 4] = 255;
      px[i * 4 + 1] = 255;
      px[i * 4 + 2] = 255;
      px[i * 4 + 3] = (255 * .6 * (.2 + .6 * rnd.nextDouble())).round();
    }
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      px,
      _size,
      _size,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }
}
