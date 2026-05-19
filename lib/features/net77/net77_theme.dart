import 'dart:math' as math;

import 'package:flutter/material.dart';

class Net77Theme {
  static const primary = Color(0xFF007866);
  static const primaryDark = Color(0xFF005F52);
  static const mint = Color(0xFFBFE8DF);
  static const mintSoft = Color(0xFFE9F7F3);
  static const page = Color(0xFFF6FBF9);
  static const card = Color(0xFFF2F7F5);
  static const line = Color(0xFFD8E3DF);
  static const text = Color(0xFF1D2926);
  static const subText = Color(0xFF687672);
  static const danger = Color(0xFFE64D5B);
  static const online = Color(0xFF3CB960);

  static ThemeData data(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: page,
      colorScheme: base.colorScheme.copyWith(primary: primary, secondary: mint, surface: card, error: danger),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: page,
        foregroundColor: text,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: base.bottomNavigationBarTheme.copyWith(
        backgroundColor: page,
        selectedItemColor: primary,
        unselectedItemColor: text,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: Color(0xFF596763))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: primary, width: 1.4)),
      ),
    );
  }
}

Map<String, dynamic> net77Map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return <String, dynamic>{};
}

List<dynamic> net77List(dynamic value) => value is List ? value : const [];

String net77Text(dynamic value, [String fallback = '-']) {
  if (value == null) return fallback;
  final text = value.toString();
  if (text.isEmpty || text == 'null') return fallback;
  return text;
}

double net77Number(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '')) ?? 0;
  return 0;
}

String net77Money(dynamic value) {
  var n = net77Number(value);
  if (n >= 100 && n % 1 == 0) n = n / 100;
  return n.toStringAsFixed(2);
}

String net77TrafficText(dynamic value) {
  var bytes = net77Number(value);
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var index = 0;
  while (bytes >= 1024 && index < units.length - 1) {
    bytes /= 1024;
    index++;
  }
  var text = bytes.toStringAsFixed(2);
  text = text.replaceFirst(RegExp(r'\.00$'), '').replaceFirst(RegExp(r'0$'), '');
  return '$text ${units[index]}';
}

String net77DateOnly(dynamic value) {
  final text = net77Text(value);
  return text.length >= 10 ? text.substring(0, 10) : text;
}

class Net77Card extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const Net77Card({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Net77Theme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Net77Theme.line),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.025), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: child,
    );
    if (onTap == null) return box;
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: box);
  }
}

class Net77Logo extends StatelessWidget {
  final double size;
  final bool rocket;
  final bool square;
  const Net77Logo({super.key, this.size = 64, this.rocket = false, this.square = false});

  @override
  Widget build(BuildContext context) {
    if (rocket) return Icon(Icons.rocket_launch, size: size, color: Net77Theme.primary);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: const Color(0xFF22324B), borderRadius: BorderRadius.circular(square ? 0 : size / 5)),
      child: Icon(Icons.cloud_outlined, color: const Color(0xFF62D5C8), size: size * 0.66),
    );
  }
}

class Net77OrbitBackground extends StatelessWidget {
  final Widget child;
  const Net77OrbitBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(children: [Positioned.fill(child: CustomPaint(painter: _OrbitPainter())), child]);
  }
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Net77Theme.primary.withOpacity(0.22)
      ..strokeWidth = 1.2;
    final start = Offset(size.width * 0.32, size.height * 0.22);
    final mid = Offset(size.width * 0.56, size.height * 0.53);
    final end = Offset(size.width * 0.78, size.height * 0.84);
    final path = Path()..moveTo(start.dx, start.dy)..quadraticBezierTo(mid.dx - 20, mid.dy - 40, mid.dx, mid.dy)..quadraticBezierTo(mid.dx + 25, mid.dy + 110, end.dx, end.dy);
    canvas.drawPath(path, paint);
    for (final p in [start, mid, end]) {
      final fill = Paint()..color = Net77Theme.mint.withOpacity(0.45);
      final stroke = Paint()
        ..color = Net77Theme.primary.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(p, p == mid ? 4 : 17, fill);
      canvas.drawCircle(p, p == mid ? 3 : 12, stroke);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Net77Donut extends StatelessWidget {
  final double percent;
  const Net77Donut({super.key, required this.percent});
  @override
  Widget build(BuildContext context) => SizedBox(width: 80, height: 80, child: CustomPaint(painter: _DonutPainter(percent.clamp(0, 100).toDouble())));
}

class _DonutPainter extends CustomPainter {
  final double percent;
  _DonutPainter(this.percent);
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = math.min(size.width, size.height) * .14;
    final rect = (Offset.zero & size).deflate(stroke / 2 + 2);
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Net77Theme.mint;
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = Net77Theme.primary;
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2, false, bg);
    canvas.drawArc(rect, -math.pi / 2, math.pi * 2 * percent / 100, false, fg);
  }
  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.percent != percent;
}
