import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(CornerTreeApp());

class CornerTreeApp extends StatelessWidget {
  const CornerTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конусная ёлка с гирляндой',
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
  double _height = 1.5; // meters (высота конуса)
  double _baseWidth = 1.2; // meters (ширина основания конуса)
  int _hooks = 15; // количество крючков (включая верхний)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Конусная ёлка с гирляндой')),
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
                          painter: CornerTreePainter(H: _height, baseWidth: _baseWidth, hooks: _hooks),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Controls
              const SizedBox(height: 10),
              _buildNumberRow('Высота конуса H (м)', _height.toStringAsFixed(2)),
              Slider(
                min: 0.3,
                max: 3.0,
                divisions: 270,
                value: _height,
                label: '${_height.toStringAsFixed(2)} м',
                onChanged: (v) => setState(() => _height = double.parse(v.toStringAsFixed(2))),
              ),

              _buildNumberRow('Ширина основания (м)', _baseWidth.toStringAsFixed(2)),
              Slider(
                min: 0.2,
                max: 3.0,
                divisions: 280,
                value: _baseWidth,
                label: '${_baseWidth.toStringAsFixed(2)} м',
                onChanged: (v) => setState(() => _baseWidth = double.parse(v.toStringAsFixed(2))),
              ),

              _buildNumberRow('Число крючков (hooks)', '$_hooks'),
              Slider(
                min: 2,
                max: 40,
                divisions: 38,
                value: _hooks.toDouble(),
                label: '$_hooks',
                onChanged: (v) => setState(() => _hooks = v.round()),
              ),

              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Длина гирлянды рассчитывается автоматически',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _height = 1.5;
                        _baseWidth = 1.2;
                        _hooks = 15;
                      });
                    },
                    child: const Text('Сбросить'),
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
  final double H; // meters (высота конуса)
  final double baseWidth; // meters (ширина основания конуса)
  final int hooks; // количество крючков (включая верхний)

  CornerTreePainter({required this.H, required this.baseWidth, required this.hooks});

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
    final paintText = TextPainter(textDirection: TextDirection.ltr);

    // Конусная геометрия: вершина вверху, расширение книзу
    // hooks - общее количество крючков (включая верхний в вершине)
    // segments - количество сегментов гирлянды между крючками
    final int segments = hooks - 1; // сегментов на 1 меньше, чем крючков

    if (segments < 1) {
      paintText.text = TextSpan(
        text: 'Требуется минимум 2 крючка',
        style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
      );
      paintText.layout(maxWidth: size.width - 20);
      paintText.paint(canvas, Offset(10, size.height / 2 - 10));
      return;
    }

    final double h = H / segments; // вертикальный шаг на один сегмент (м)

    // Радиус конуса в основании (задан пользователем)
    final double rMax = baseWidth / 2; // радиус = половина ширины

    // Настройка визуализации
    final double padding = size.width * 0.08;
    final Offset topCenter = Offset(size.width / 2, padding);
    final double maxVisualWidth = size.width - padding * 2;
    final double maxVisualHeight = size.height - padding * 2;

    // Масштаб: метры -> пиксели
    final double widthInMeters = baseWidth;
    double scaleX = widthInMeters > 0 ? maxVisualWidth / (widthInMeters * 1.2) : maxVisualWidth / 1.0;
    double scaleY = H > 0 ? maxVisualHeight / (H * 1.1) : maxVisualHeight / 1.0;
    final double scale = min(scaleX, scaleY);

    // Рисуем контур конуса (треугольник)
    final double rMaxPx = rMax * scale;
    final Offset bottomLeft = Offset(topCenter.dx - rMaxPx, topCenter.dy + H * scale);
    final Offset bottomRight = Offset(topCenter.dx + rMaxPx, topCenter.dy + H * scale);
    final Path conePath = Path();
    conePath.moveTo(topCenter.dx, topCenter.dy);
    conePath.lineTo(bottomLeft.dx, bottomLeft.dy);
    conePath.lineTo(bottomRight.dx, bottomRight.dy);
    conePath.close();
    canvas.drawPath(conePath, paintCone);

    // Строим крючки (hooks) с постепенным расширением
    // Первый крючок - в вершине (0, 0)
    final List<Offset> points = [topCenter]; // начинаем с вершины
    double accumulatedY = 0.0;
    bool toLeft = true;

    // Рассчитываем длину гирлянды по факту
    double totalGarlandLength = 0.0;

    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      // Радиус на текущей высоте (линейное расширение от 0 до rMax)
      final double currentRadius = rMax * (accumulatedY / H);

      // Горизонтальное смещение для текущего уровня
      final double xOffsetMeters = (toLeft ? -currentRadius : currentRadius);
      final Offset next = Offset(topCenter.dx + xOffsetMeters * scale, topCenter.dy + accumulatedY * scale);
      points.add(next);

      // Вычисляем длину сегмента в метрах
      final double dx =
          xOffsetMeters - (points.length == 2 ? 0 : (toLeft ? currentRadius : -currentRadius) * (accumulatedY - h) / H);
      final double segmentLength = sqrt(dx * dx + h * h);
      totalGarlandLength += segmentLength;

      toLeft = !toLeft;
    }

    // Рисуем крючки (hooks)
    for (final p in points) {
      canvas.drawCircle(p, 4, paintPoint);
    }

    // Рисуем гирлянду (зигзаг от вершины)
    final Path garlandPath = Path();
    garlandPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      garlandPath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(garlandPath, paintLine);

    // Рисуем горизонтальные линии уровней (для наглядности)
    final levelPaint = Paint()
      ..color = Colors.blueGrey.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    accumulatedY = 0.0;
    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      final double currentRadius = rMax * (accumulatedY / H);
      final double y = topCenter.dy + accumulatedY * scale;
      final double rPx = currentRadius * scale;
      canvas.drawLine(Offset(topCenter.dx - rPx, y), Offset(topCenter.dx + rPx, y), levelPaint);
    }

    // Пересчитываем длину гирлянды более точно
    totalGarlandLength = 0.0;
    for (int i = 0; i < segments; i++) {
      final double y1 = i * h;
      final double y2 = (i + 1) * h;
      final double r1 = rMax * (y1 / H);
      final double r2 = rMax * (y2 / H);

      // Горизонтальное расстояние: от одного края до другого (или от центра до края для первого)
      final double horizontalDist = i == 0 ? r2 : (r1 + r2);
      final double segmentLength = sqrt(horizontalDist * horizontalDist + h * h);
      totalGarlandLength += segmentLength;
    }

    // Выводим сводную информацию
    final double coneAngle = atan(rMax / H) * 180 / pi;
    final double avgSegmentLength = totalGarlandLength / segments;
    final summary =
        'H=${H.toStringAsFixed(2)}м  '
        'Основание=${baseWidth.toStringAsFixed(2)}м  '
        'Hooks=$hooks (сегментов: $segments)\n'
        'Длина гирлянды: ${totalGarlandLength.toStringAsFixed(2)}м  '
        'Угол конуса: ${coneAngle.toStringAsFixed(1)}°  '
        'Ср. сегмент: ${avgSegmentLength.toStringAsFixed(3)}м';
    paintText.text = TextSpan(
      text: summary,
      style: TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w500),
    );
    paintText.layout(maxWidth: size.width - 20);
    paintText.paint(canvas, Offset(10, 6));

    // Рисуем маленькие метки на центральной оси
    final tickPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    accumulatedY = 0.0;
    for (int i = 0; i <= segments; i++) {
      final double y = topCenter.dy + accumulatedY * scale;
      canvas.drawLine(Offset(topCenter.dx - 5, y), Offset(topCenter.dx + 5, y), tickPaint);
      if (i < segments) accumulatedY += h;
    }
  }

  @override
  bool shouldRepaint(covariant CornerTreePainter oldDelegate) {
    return oldDelegate.H != H || oldDelegate.baseWidth != baseWidth || oldDelegate.hooks != hooks;
  }
}
