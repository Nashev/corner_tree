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
  bool _mirrorTree = false; // зеркальное отражение

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конусная ёлка с гирляндой'),
        actions: [
          IconButton(
            icon: Icon(_mirrorTree ? Icons.flip : Icons.flip_outlined),
            tooltip: 'Зеркальное отражение',
            onPressed: () {
              setState(() {
                _mirrorTree = !_mirrorTree;
              });
            },
          ),
        ],
      ),
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
                  painter: CornerTreePainter(H: _height, baseWidth: _baseWidth, hooks: _hooks, mirrorTree: _mirrorTree),
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
                  _buildNumberRow('Высота конуса (см)', (_height * 100).round().toString()),
                  Slider(
                    min: 10,
                    max: 500,
                    divisions: 490,
                    value: _height * 100,
                    label: '${(_height * 100).round()} см',
                    onChanged: (v) => setState(() => _height = v / 100),
                  ),

                  _buildNumberRow('Ширина основания (см)', (_baseWidth * 100).round().toString()),
                  Slider(
                    min: 10,
                    max: 300,
                    divisions: 290,
                    value: _baseWidth * 100,
                    label: '${(_baseWidth * 100).round()} см',
                    onChanged: (v) => setState(() => _baseWidth = v / 100),
                  ),

                  _buildNumberRow('Число крючков', '$_hooks'),
                  Slider(
                    min: 2,
                    max: 70,
                    divisions: 68,
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
            TextSpan(text: 'Сегментов: $segments (по $hCm см высотой) • '),
            TextSpan(
              text: 'Длина гирлянды: $totalLengthCm см',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: ' • Угол: ${coneAngle.toStringAsFixed(1)}°'),
          ],
        ),
      ),
    );
  }
}

class CornerTreePainter extends CustomPainter {
  final double H; // meters (высота конуса)
  final double baseWidth; // meters (ширина основания конуса)
  final int hooks; // количество крючков (включая верхний)
  final bool mirrorTree; // зеркальное отражение

  CornerTreePainter({required this.H, required this.baseWidth, required this.hooks, required this.mirrorTree});

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

    // Конусная геометрия: вершина вверху, расширение книзу
    final int segments = hooks - 1; // сегментов на 1 меньше, чем крючков

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
    bool toLeft = mirrorTree ? false : true; // Начальное направление зависит от зеркалирования

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

    // Рисуем провод, свисающий с нижнего крючка
    final Offset lastHook = points[points.length - 1];
    final double wireLength = 80; // пиксели
    final double wireEndX = lastHook.dx < topCenter.dx
        ? 0 // уходит влево за экран
        : size.width; // уходит вправо за экран
    final double wireEndY = lastHook.dy + wireLength;

    final Path wirePath = Path();
    wirePath.moveTo(lastHook.dx, lastHook.dy);
    wirePath.quadraticBezierTo(lastHook.dx, wireEndY, wireEndX, wireEndY);
    canvas.drawPath(wirePath, paintWire);

    // Рисуем горизонтальные линии уровней с подписями длин
    final levelPaint = Paint()
      ..color = Colors.blueGrey.withAlpha(40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    accumulatedY = 0.0;
    toLeft = mirrorTree ? false : true; // Сбрасываем направление
    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      final double currentRadius = rMax * (accumulatedY / H);
      final double y = topCenter.dy + accumulatedY * scale;
      final double rPx = currentRadius * scale;

      // Рисуем горизонтальную линию
      canvas.drawLine(Offset(topCenter.dx - rPx, y), Offset(topCenter.dx + rPx, y), levelPaint);

      // Определяем позицию крючка на этом уровне
      final Offset hookPoint = points[i + 1]; // +1 потому что points[0] - вершина

      // Переводим расстояние в сантиметры
      final int aCm = (currentRadius * 100).round();

      // Вычисляем расстояние от угла: sqrt((2*a)^2/2) = sqrt(2*a^2) = a*sqrt(2)
      final int cornerDistCm = (currentRadius * sqrt(2) * 100).round();

      // Формируем текст подписи
      final bool isLastSegment = (i == segments - 1);
      final String labelText = isLastSegment
          ? '$aCm см ($cornerDistCm см от угла, если ёлка в углу)'
          : '$aCm см ($cornerDistCm см)';

      // Позиция подписи - посередине между центром и крючком
      final double labelX = (topCenter.dx + hookPoint.dx) / 2;
      final double labelY = y + 14;

      _drawLengthLabel(canvas, labelText, Offset(labelX, labelY), Colors.blueGrey.shade700);

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
    final double yOffset = cubeSizePx * sin(angle);

    final cubePaint = Paint()
      ..color = Colors.orange.shade300
      ..style = PaintingStyle.fill;
    final cubeEdgePaint = Paint()
      ..color = Colors.orange.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Определяем 8 вершин куба в изометрии
    // Нижняя грань (левая)
    final p0 = Offset(cubeX, cubeY); // центр куба
    final p1 = p0 + Offset(0, 2 * yOffset); // вниз, нижняя правая
    final p2 = p0 + Offset(-xOffset, yOffset); // влево, нижняя левая
    final p3 = p0 + Offset(-xOffset, -yOffset); // верхняя левая

    // Верхняя грань
    final p4 = p0 + Offset(0, -2 * yOffset); // верхняя
    final p5 = p0 + Offset(xOffset, -yOffset); // правая
    // Нижняя правая грань
    final p6 = p0 + Offset(xOffset, yOffset); //  правая нижняя

    // Рисуем три видимые грани

    // Передняя грань (светлая)
    final frontPath = Path();
    frontPath.moveTo(p0.dx, p0.dy);
    frontPath.lineTo(p1.dx, p1.dy);
    frontPath.lineTo(p2.dx, p2.dy);
    frontPath.lineTo(p3.dx, p3.dy);
    frontPath.close();
    canvas.drawPath(frontPath, cubePaint);
    canvas.drawPath(frontPath, cubeEdgePaint);

    // Правая грань (темнее)
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

    // Верхняя грань (самая светлая)
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

    // Подпись "10 см"
    final textPainter = TextPainter(
      text: TextSpan(
        text: '10 см',
        style: TextStyle(color: Colors.orange.shade900, fontSize: 11, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
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
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CornerTreePainter oldDelegate) {
    return oldDelegate.H != H ||
        oldDelegate.baseWidth != baseWidth ||
        oldDelegate.hooks != hooks ||
        oldDelegate.mirrorTree != mirrorTree;
  }
}
