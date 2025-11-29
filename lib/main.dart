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
        child: Column(
          children: [
            // Область визуализации на всю ширину
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: CustomPaint(
                  painter: CornerTreePainter(H: _height, baseWidth: _baseWidth, hooks: _hooks),
                ),
              ),
            ),

            // Компактное описание и слайдеры
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  // Компактная информация в одну строку
                  _buildInfoPanel(),
                  const SizedBox(height: 10),

                  // Controls
                  _buildNumberRow('Высота конуса (м)', _height.toStringAsFixed(2)),
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

                  _buildNumberRow('Число крючков', '$_hooks'),
                  Slider(
                    min: 2,
                    max: 40,
                    divisions: 38,
                    value: _hooks.toDouble(),
                    label: '$_hooks',
                    onChanged: (v) => setState(() => _hooks = v.round()),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
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
    // Расчёты для отображения информации
    final int segments = _hooks - 1;
    if (segments < 1) return const SizedBox.shrink();

    final double h = _height / segments;
    final double rMax = _baseWidth / 2;

    // Рассчитываем длину гирлянды
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Text(
        'Сегментов: $segments (по ${h.toStringAsFixed(3)}м) • '
        'Длина гирлянды: ${totalGarlandLength.toStringAsFixed(2)}м • '
        'Угол: ${coneAngle.toStringAsFixed(1)}°',
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
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

    // Конусная геометрия: вершина вверху, расширение книзу
    final int segments = hooks - 1; // сегментов на 1 меньше, чем крючков

    if (segments < 1) {
      final paintText = TextPainter(textDirection: TextDirection.ltr);
      paintText.text = TextSpan(
        text: 'Требуется минимум 2 крючка',
        style: TextStyle(color: Colors.red.shade700, fontSize: 12, fontWeight: FontWeight.w500),
      );
      paintText.layout(maxWidth: size.width - 20);
      paintText.paint(canvas, Offset(10, size.height / 2 - 10));
      return;
    }

    final double h = H / segments; // вертикальный шаг на один сегмент (м)
    final double rMax = baseWidth / 2; // радиус = половина ширины

    // Настройка визуализации
    final double padding = size.width * 0.05;
    final double bottomPadding = size.height * 0.15; // Больше места снизу для кубика
    final Offset topCenter = Offset(size.width / 2, padding);
    final double maxVisualWidth = size.width - padding * 2;
    final double maxVisualHeight = size.height - padding - bottomPadding;

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
    final List<Offset> points = [topCenter]; // начинаем с вершины
    double accumulatedY = 0.0;
    bool toLeft = true;

    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      final double currentRadius = rMax * (accumulatedY / H);
      final double xOffsetMeters = (toLeft ? -currentRadius : currentRadius);
      final Offset next = Offset(topCenter.dx + xOffsetMeters * scale, topCenter.dy + accumulatedY * scale);
      points.add(next);
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

    // Рисуем горизонтальные линии уровней с подписями длин
    final levelPaint = Paint()
      ..color = Colors.blueGrey.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    accumulatedY = 0.0;
    toLeft = true; // Отслеживаем направление для правильного размещения подписи
    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      final double currentRadius = rMax * (accumulatedY / H);
      final double y = topCenter.dy + accumulatedY * scale;
      final double rPx = currentRadius * scale;

      // Рисуем горизонтальную линию
      canvas.drawLine(Offset(topCenter.dx - rPx, y), Offset(topCenter.dx + rPx, y), levelPaint);

      // Определяем позицию крючка на этом уровне
      final Offset hookPoint = points[i + 1]; // +1 потому что points[0] - вершина

      // Подписываем расстояние от центра до крючка (радиус)
      // Позиция подписи - посередине между центром и крючком
      final double labelX = (topCenter.dx + hookPoint.dx) / 2;
      final double labelY = y + 14;

      _drawLengthLabel(
        canvas,
        '${currentRadius.toStringAsFixed(2)}м',
        Offset(labelX, labelY),
        Colors.blueGrey.shade700,
      );

      toLeft = !toLeft;
    }

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

    // Рисуем кубик 10см для масштаба (аксонометрическая проекция)
    _drawScaleCube(canvas, size, scale);
  }

  void _drawScaleCube(Canvas canvas, Size size, double scale) {
    // Кубик 10см = 0.1м
    final double cubeSize = 0.1; // метры
    final double cubeSizePx = cubeSize * scale; // пиксели

    // Размещаем кубик справа снизу
    final double cubeX = size.width - 80;
    final double cubeY = size.height - 80;

    // Аксонометрическая проекция (изометрия)
    // Углы: 30° для X и Z осей
    final double angle = 30 * pi / 180;
    final double xOffset = cubeSizePx * cos(angle);
    final double yOffsetX = cubeSizePx * sin(angle);
    final double zOffset = cubeSizePx * cos(angle);
    final double yOffsetZ = cubeSizePx * sin(angle);

    final cubePaint = Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.fill;
    final cubeEdgePaint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Определяем 8 вершин куба в изометрии
    // Нижняя грань (ближняя)
    final p1 = Offset(cubeX, cubeY); // нижняя передняя левая
    final p2 = Offset(cubeX + xOffset, cubeY - yOffsetX); // нижняя передняя правая
    final p3 = Offset(cubeX + xOffset - zOffset, cubeY - yOffsetX - yOffsetZ); // нижняя задняя правая
    final p4 = Offset(cubeX - zOffset, cubeY - yOffsetZ); // нижняя задняя левая

    // Верхняя грань
    final p5 = Offset(p1.dx, p1.dy - cubeSizePx); // верхняя передняя левая
    final p6 = Offset(p2.dx, p2.dy - cubeSizePx); // верхняя передняя правая
    final p7 = Offset(p3.dx, p3.dy - cubeSizePx); // верхняя задняя правая
    final p8 = Offset(p4.dx, p4.dy - cubeSizePx); // верхняя задняя левая

    // Рисуем три видимые грани

    // Передняя грань (светлая)
    final frontPath = Path();
    frontPath.moveTo(p1.dx, p1.dy);
    frontPath.lineTo(p2.dx, p2.dy);
    frontPath.lineTo(p6.dx, p6.dy);
    frontPath.lineTo(p5.dx, p5.dy);
    frontPath.close();
    canvas.drawPath(frontPath, cubePaint);
    canvas.drawPath(frontPath, cubeEdgePaint);

    // Правая грань (темнее)
    final rightPaint = Paint()
      ..color = Colors.orange.shade400
      ..style = PaintingStyle.fill;
    final rightPath = Path();
    rightPath.moveTo(p2.dx, p2.dy);
    rightPath.lineTo(p3.dx, p3.dy);
    rightPath.lineTo(p7.dx, p7.dy);
    rightPath.lineTo(p6.dx, p6.dy);
    rightPath.close();
    canvas.drawPath(rightPath, rightPaint);
    canvas.drawPath(rightPath, cubeEdgePaint);

    // Верхняя грань (самая светлая)
    final topPaint = Paint()
      ..color = Colors.orange.shade200
      ..style = PaintingStyle.fill;
    final topPath = Path();
    topPath.moveTo(p5.dx, p5.dy);
    topPath.lineTo(p6.dx, p6.dy);
    topPath.lineTo(p7.dx, p7.dy);
    topPath.lineTo(p8.dx, p8.dy);
    topPath.close();
    canvas.drawPath(topPath, topPaint);
    canvas.drawPath(topPath, cubeEdgePaint);

    // Подпись "10 см"
    final textPainter = TextPainter(
      text: TextSpan(
        text: '10 см',
        style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(cubeX - 10, cubeY + 10));
  }

  void _drawLengthLabel(Canvas canvas, String text, Offset position, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          backgroundColor: Colors.white.withAlpha(220),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CornerTreePainter oldDelegate) {
    return oldDelegate.H != H || oldDelegate.baseWidth != baseWidth || oldDelegate.hooks != hooks;
  }
}
