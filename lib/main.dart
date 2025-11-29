import 'dart:math';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ru')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      child: const CornerTreeApp(),
    ),
  );
}

class CornerTreeApp extends StatelessWidget {
  const CornerTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: tr('appTitle'),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData.light(),
      home: const CornerTreePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CornerTreePage extends StatefulWidget {
  const CornerTreePage({super.key});

  @override
  CornerTreePageState createState() => CornerTreePageState();
}

class CornerTreePageState extends State<CornerTreePage> {
  double _height = 1.5;
  double _baseWidth = 1.2;
  int _hooks = 15;
  bool _mirrorTree = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('appTitle')),
        actions: [
          IconButton(
            icon: Icon(_mirrorTree ? Icons.flip : Icons.flip_outlined),
            tooltip: tr('mirrorTooltip'),
            onPressed: () {
              setState(() {
                _mirrorTree = !_mirrorTree;
              });
            },
          ),
          if (kIsWeb) const _LocaleSwitcher(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: CustomPaint(
                  painter: CornerTreePainter(
                    H: _height,
                    baseWidth: _baseWidth,
                    hooks: _hooks,
                    mirrorTree: _mirrorTree,
                    locale: context.locale,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  _buildInfoPanel(),
                  const SizedBox(height: 10),
                  _buildNumberRow(tr('coneHeight'), (_height * 100).round().toString()),
                  Slider(
                    min: 30,
                    max: 300,
                    divisions: 270,
                    value: _height * 100,
                    label: '${(_height * 100).round()} ${tr('cm')}',
                    onChanged: (v) => setState(() => _height = v / 100),
                  ),
                  _buildNumberRow(tr('baseWidth'), (_baseWidth * 100).round().toString()),
                  Slider(
                    min: 20,
                    max: 300,
                    divisions: 280,
                    value: _baseWidth * 100,
                    label: '${(_baseWidth * 100).round()} ${tr('cm')}',
                    onChanged: (v) => setState(() => _baseWidth = v / 100),
                  ),
                  _buildNumberRow(tr('hooksCount'), '$_hooks'),
                  Slider(
                    min: 2,
                    max: 40,
                    divisions: 38,
                    value: _hooks.toDouble(),
                    label: '$_hooks',
                    onChanged: (v) => setState(() => _hooks = v.round()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberRow(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _buildInfoPanel() {
    final int segments = _hooks - 1;
    if (segments < 1) return const SizedBox.shrink();

    final double h = _height / segments;
    final double rMax = _baseWidth / 2;

    double totalGarlandLength = 0.0;
    for (int i = 0; i < segments; i++) {
      final double y1 = i * h;
      final double y2 = (i + 1) * h;
      final double r1 = rMax * (y1 / _height);
      final double r2 = rMax * (y2 / _height);
      final double horizontalDist = i == 0 ? r2 : (r1 + r2);
      final double segmentLength = sqrt(horizontalDist * horizontalDist + h * h);
      totalGarlandLength += segmentLength;
    }

    final double coneAngle = atan(rMax / _height) * 180 / pi;
    final int hCm = (h * 100).round();
    final int totalLengthCm = (totalGarlandLength * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            TextSpan(text: '${tr('segments')}: $segments (${tr('per')} $hCm ${tr('cm')}) • '),
            TextSpan(
              text: '${tr('garlandLength')}: $totalLengthCm ${tr('cm')}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' • ${tr('angle')}: ${coneAngle.toStringAsFixed(1)}°'),
          ],
        ),
      ),
    );
  }
}

class _LocaleSwitcher extends StatelessWidget {
  const _LocaleSwitcher();

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Locale>(
        value: context.locale,
        icon: const Icon(Icons.language),
        dropdownColor: Theme.of(context).colorScheme.surface,
        onChanged: (locale) {
          if (locale != null) {
            context.setLocale(locale);
          }
        },
        items: const [
          DropdownMenuItem(value: Locale('en'), child: Text('EN')),
          DropdownMenuItem(value: Locale('ru'), child: Text('RU')),
        ],
      ),
    );
  }
}

class CornerTreePainter extends CustomPainter {
  final double H;
  final double baseWidth;
  final int hooks;
  final bool mirrorTree;
  final Locale locale;

  CornerTreePainter({
    required this.H,
    required this.baseWidth,
    required this.hooks,
    required this.mirrorTree,
    required this.locale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintCone = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final paintLine = Paint()
      ..color = Colors.green.shade700
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final paintPoint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final paintWire = Paint()
      ..color = Colors.grey.shade700
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final int segments = hooks - 1;
    final double h = H / segments;
    final double rMax = baseWidth / 2;

    final double padding = size.width * 0.05;
    final double bottomPadding = size.height * 0.15;
    final Offset topCenter = Offset(size.width / 2, padding);
    final double maxVisualWidth = size.width - padding * 2;
    final double maxVisualHeight = size.height - padding - bottomPadding;

    final double widthInMeters = baseWidth;
    double scaleX = widthInMeters > 0 ? maxVisualWidth / (widthInMeters * 1.2) : maxVisualWidth / 1.0;
    double scaleY = H > 0 ? maxVisualHeight / (H * 1.1) : maxVisualHeight / 1.0;
    final double scale = min(scaleX, scaleY);

    // Draw cone outline
    final double rMaxPx = rMax * scale;
    final Offset bottomLeft = Offset(topCenter.dx - rMaxPx, topCenter.dy + H * scale);
    final Offset bottomRight = Offset(topCenter.dx + rMaxPx, topCenter.dy + H * scale);
    final Path conePath = Path();
    conePath.moveTo(topCenter.dx, topCenter.dy);
    conePath.lineTo(bottomLeft.dx, bottomLeft.dy);
    conePath.lineTo(bottomRight.dx, bottomRight.dy);
    conePath.close();
    canvas.drawPath(conePath, paintCone);

    // Build hook points
    final List<Offset> points = [topCenter];
    double accumulatedY = 0.0;
    bool toLeft = mirrorTree ? false : true;

    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      final double currentRadius = rMax * (accumulatedY / H);
      final double xOffsetMeters = (toLeft ? -currentRadius : currentRadius);
      final Offset next = Offset(topCenter.dx + xOffsetMeters * scale, topCenter.dy + accumulatedY * scale);
      points.add(next);
      toLeft = !toLeft;
    }

    // Draw hooks
    for (final p in points) {
      canvas.drawCircle(p, 4, paintPoint);
    }

    // Draw garland zigzag
    final Path garlandPath = Path();
    garlandPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      garlandPath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(garlandPath, paintLine);

    // Draw hanging wire from bottom hook
    final Offset lastHook = points[points.length - 1];
    final double wireLength = 80;
    final double wireEndX = lastHook.dx < topCenter.dx ? 0 : size.width;
    final double wireEndY = lastHook.dy + wireLength;

    final Path wirePath = Path();
    wirePath.moveTo(lastHook.dx, lastHook.dy);
    wirePath.quadraticBezierTo(lastHook.dx, wireEndY, wireEndX, wireEndY);
    canvas.drawPath(wirePath, paintWire);

    // Draw horizontal level lines with labels
    final levelPaint = Paint()
      ..color = Colors.blueGrey.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final cmUnit = tr('cm');
    final fromCornerText = tr('fromCorner');

    accumulatedY = 0.0;
    toLeft = mirrorTree ? false : true;
    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      final double currentRadius = rMax * (accumulatedY / H);
      final double y = topCenter.dy + accumulatedY * scale;
      final double rPx = currentRadius * scale;

      canvas.drawLine(Offset(topCenter.dx - rPx, y), Offset(topCenter.dx + rPx, y), levelPaint);

      final Offset hookPoint = points[i + 1];
      final int aCm = (currentRadius * 100).round();
      final int cornerDistCm = (currentRadius * sqrt(2) * 100).round();

      final bool isLastSegment = (i == segments - 1);
      final String labelText = isLastSegment
          ? '$aCm $cmUnit ($cornerDistCm $fromCornerText)'
          : '$aCm $cmUnit ($cornerDistCm)';

      final double labelX = (topCenter.dx + hookPoint.dx) / 2;
      final double labelY = y + 14;

      _drawLengthLabel(canvas, labelText, Offset(labelX, labelY), Colors.blueGrey.shade700);

      toLeft = !toLeft;
    }

    // Draw axis tick marks
    final tickPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    accumulatedY = 0.0;
    for (int i = 0; i <= segments; i++) {
      final double y = topCenter.dy + accumulatedY * scale;
      canvas.drawLine(Offset(topCenter.dx - 5, y), Offset(topCenter.dx + 5, y), tickPaint);
      if (i < segments) accumulatedY += h;
    }

    _drawScaleCube(canvas, size, scale, cmUnit);
  }

  void _drawScaleCube(Canvas canvas, Size size, double scale, String cmUnit) {
    final double cubeSize = 0.1;
    final double cubeSizePx = cubeSize * scale;

    final double cubeX = size.width - 80;
    final double cubeY = size.height - 80;

    final double angle = 30 * pi / 180;
    final double xOffset = cubeSizePx * cos(angle);
    final double yOffset = cubeSizePx * sin(angle);

    final cubePaint = Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.fill;
    final cubeEdgePaint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final p0 = Offset(cubeX, cubeY);
    final p1 = p0 + Offset(0, 2 * yOffset);
    final p2 = p0 + Offset(-xOffset, yOffset);
    final p3 = p0 + Offset(-xOffset, -yOffset);
    final p4 = p0 + Offset(0, -2 * yOffset);
    final p5 = p0 + Offset(xOffset, -yOffset);
    final p6 = p0 + Offset(xOffset, yOffset);

    // Front face
    final frontPath = Path();
    frontPath.moveTo(p0.dx, p0.dy);
    frontPath.lineTo(p1.dx, p1.dy);
    frontPath.lineTo(p2.dx, p2.dy);
    frontPath.lineTo(p3.dx, p3.dy);
    frontPath.close();
    canvas.drawPath(frontPath, cubePaint);
    canvas.drawPath(frontPath, cubeEdgePaint);

    // Right face
    final rightPaint = Paint()
      ..color = Colors.orange.shade400
      ..style = PaintingStyle.fill;
    final rightPath = Path();
    rightPath.moveTo(p3.dx, p3.dy);
    rightPath.lineTo(p4.dx, p4.dy);
    rightPath.lineTo(p5.dx, p5.dy);
    rightPath.lineTo(p0.dx, p0.dy);
    rightPath.close();
    canvas.drawPath(rightPath, rightPaint);
    canvas.drawPath(rightPath, cubeEdgePaint);

    // Top face
    final topPaint = Paint()
      ..color = Colors.orange.shade200
      ..style = PaintingStyle.fill;
    final topPath = Path();
    topPath.moveTo(p5.dx, p5.dy);
    topPath.lineTo(p6.dx, p6.dy);
    topPath.lineTo(p1.dx, p1.dy);
    topPath.lineTo(p0.dx, p0.dy);
    topPath.close();
    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(topPath, cubeEdgePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '10 $cmUnit',
        style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cubeX - 10, cubeY - 20));
  }

  void _drawLengthLabel(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.white.withAlpha(220),
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CornerTreePainter oldDelegate) {
    return oldDelegate.H != H ||
        oldDelegate.baseWidth != baseWidth ||
        oldDelegate.hooks != hooks ||
        oldDelegate.mirrorTree != mirrorTree ||
        oldDelegate.locale != locale;
  }
}
