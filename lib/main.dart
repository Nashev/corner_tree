import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(CornerTreeApp());

class CornerTreeApp extends StatelessWidget {
  const CornerTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corner Garland Designer',
      theme: ThemeData.light(),
      home: CornerTreePage(),
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
  double _length = 5.5; // meters
  double _height = 1.5; // meters
  int _zigzags = 7;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Схема крепления гирлянды (угловая)')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = min(constraints.maxWidth, constraints.maxHeight) * 0.9;
                      return Container(
                        width: canvasSize,
                        height: canvasSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: CustomPaint(
                          painter: CornerTreePainter(L: _length, H: _height, N: _zigzags),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Controls
              const SizedBox(height: 10),
              _buildNumberRow('Длина гирлянды L (м)', _length.toStringAsFixed(1)),
              Slider(
                min: 1.0,
                max: 20.0,
                divisions: 190,
                value: _length,
                label: '${_length.toStringAsFixed(2)} m',
                onChanged: (v) => setState(() => _length = double.parse(v.toStringAsFixed(2))),
              ),

              _buildNumberRow('Высота H (м)', _height.toStringAsFixed(2)),
              Slider(
                min: 0.3,
                max: 3.0,
                divisions: 270,
                value: _height,
                label: '${_height.toStringAsFixed(2)} m',
                onChanged: (v) => setState(() => _height = double.parse(v.toStringAsFixed(2))),
              ),

              _buildNumberRow('Число зигзагов N', '$_zigzags'),
              Slider(
                min: 1,
                max: 20,
                divisions: 19,
                value: _zigzags.toDouble(),
                label: '$_zigzags',
                onChanged: (v) => setState(() => _zigzags = v.round()),
              ),

              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Советы: проверь, чтобы s ≥ h; если s < h — параметры несовместимы.'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // quick example preset
                        _length = 5.5;
                        _height = 1.5;
                        _zigzags = 7;
                      });
                    },
                    child: const Text('Сбросить в пример'),
                  ),
                ],
              ),
            ],
          ),
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
}

class CornerTreePainter extends CustomPainter {
  final double L; // meters
  final double H; // meters
  final int N; // zigzags

  CornerTreePainter({required this.L, required this.H, required this.N});

  @override
  void paint(Canvas canvas, Size size) {
    final paintWall = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;
    final paintLine = Paint()
      ..color = Colors.green.shade700
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final paintPoint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    final paintText = TextPainter(textDirection: TextDirection.ltr);

    // compute geometry in meters (model)
    final int diagonals = 2 * N;
    final double h = H / diagonals; // vertical projection per diagonal (m)
    final double s = L / diagonals; // length per diagonal (m)
    double d = 0.0; // horizontal half-width per diagonal (m)
    bool impossible = false;
    if (s <= h) {
      impossible = true;
    } else {
      d = sqrt(max(0.0, s * s - h * h));
    }

    // visualize corner as center-top and zigzag left-right around center
    final double padding = size.width * 0.08;
    final Offset topCenter = Offset(size.width / 2, padding);
    final double maxVisualWidth = size.width - padding * 2; // pixels
    final double maxVisualHeight = size.height - padding * 2;

    // determine scale: meters -> pixels
    final double widthInMeters = 2 * d; // total width in meters
    double scaleX = widthInMeters > 0 ? maxVisualWidth / (widthInMeters * 1.2) : maxVisualWidth / 1.0;
    double scaleY = H > 0 ? maxVisualHeight / (H * 1.05) : maxVisualHeight / 1.0;
    final double scale = min(scaleX, scaleY);

    // draw walls (stylized)
    final wallLen = maxVisualHeight;
    canvas.drawLine(Offset(size.width / 2, padding), Offset(size.width / 2, padding + wallLen), paintWall);

    // if impossible, draw warning text
    if (impossible) {
      paintText.text = TextSpan(
        text:
            'Параметры несовместимы: длина сегмента s ≤ h (недостаточно гирлянды для заданной высоты/числа зигзагов).',
        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
      );
      paintText.layout(maxWidth: size.width - 20);
      paintText.paint(canvas, Offset(10, size.height / 2 - 10));
      return;
    }

    // build points
    final List<Offset> points = [];
    Offset current = topCenter;
    double accumulatedY = 0.0;
    bool toLeft = true;
    for (int i = 0; i < diagonals; i++) {
      accumulatedY += h;
      final double xOffsetMeters = (toLeft ? -d : d);
      final Offset next = Offset(topCenter.dx + xOffsetMeters * scale, topCenter.dy + accumulatedY * scale);
      points.add(next);
      toLeft = !toLeft;
    }

    // Draw attachment points and labels
    for (final p in points) {
      canvas.drawCircle(p, 4, paintPoint);
    }

    // Draw the garland zigzag polyline: start at topCenter
    final Path path = Path();
    path.moveTo(topCenter.dx, topCenter.dy);
    for (final p in points) {
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(path, paintLine);

    // Draw a faint guideline from center to bottom corners representing width
    final double halfWpx = d * scale;
    final Offset bottomLeft = Offset(topCenter.dx - halfWpx, topCenter.dy + H * scale);
    final Offset bottomRight = Offset(topCenter.dx + halfWpx, topCenter.dy + H * scale);
    final guidePaint = Paint()
      ..color = Colors.blueGrey.withAlpha(64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(bottomLeft, bottomRight, guidePaint);

    // Draw summary text (s, h, W, angle)
    final double w = 2 * d;
    final double angleDeg = atan(h / d) * 180 / pi;
    final summary =
        'L=${L.toStringAsFixed(2)}m  H=${H.toStringAsFixed(2)}m  N=$N\n  s=${s.toStringAsFixed(3)}m  h=${h.toStringAsFixed(3)}m  W≈${w.toStringAsFixed(3)}m  α≈${angleDeg.toStringAsFixed(1)}°';
    paintText.text = TextSpan(
      text: summary,
      style: TextStyle(color: Colors.black87, fontSize: 12),
    );
    paintText.layout(maxWidth: size.width - 20);
    paintText.paint(canvas, Offset(10, 6));

    // Draw small tick marks at left/right attachments per level to help mark positions
    final tickPaint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;
    toLeft = true;
    accumulatedY = 0.0;
    for (int i = 0; i < diagonals; i++) {
      accumulatedY += h;
      final double xOffsetMeters = (toLeft ? -d : d);
      final Offset p = Offset(topCenter.dx + xOffsetMeters * scale, topCenter.dy + accumulatedY * scale);
      // small tick on the wall (projected)
      canvas.drawLine(Offset(topCenter.dx - 6, p.dy), Offset(topCenter.dx + 6, p.dy), tickPaint);
      toLeft = !toLeft;
    }
  }

  @override
  bool shouldRepaint(covariant CornerTreePainter oldDelegate) {
    return oldDelegate.L != L || oldDelegate.H != H || oldDelegate.N != N;
  }
}
