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
  double _length = 5.5; // meters
  double _height = 1.5; // meters
  int _hooks = 14; // количество крючков

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
                          painter: CornerTreePainter(L: _length, H: _height, hooks: _hooks),
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
                  Text('Конус расширяется от вершины книзу'),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        // quick example preset
                        _length = 5.5;
                        _height = 1.5;
                        _hooks = 14;
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
  final double L; // meters (длина гирлянды)
  final double H; // meters (высота конуса)
  final int hooks; // количество крючков

  CornerTreePainter({required this.L, required this.H, required this.hooks});

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
    // hooks - общее количество крючков (не считая вершину)
    final int segments = hooks; // количество сегментов гирлянды
    final double h = H / segments; // вертикальный шаг на один сегмент (м)
    final double s = L / segments; // длина одного сегмента гирлянды (м)

    // Радиус конуса в основании (максимальный)
    // Используем формулу: если общая длина L распределена по конусу,
    // то нужно рассчитать максимальный радиус основания
    // Упрощённо: радиус растёт линейно от 0 до rMax
    double rMax = 0.0;
    bool impossible = false;

    // Проверка: можно ли разместить гирлянду с такими параметрами
    if (s <= h) {
      impossible = true;
    } else {
      // Для конуса радиус растёт пропорционально высоте
      // r(y) = rMax * (y / H), где y - текущая высота
      // Каждый сегмент имеет горизонтальную проекцию d_i
      // d_i^2 = s^2 - h^2, но для конуса d растёт
      // Упрощаем: используем средний радиус для оценки
      rMax = sqrt(max(0.0, s * s - h * h)) * segments / 4;
    }

    // Настройка визуализации
    final double padding = size.width * 0.08;
    final Offset topCenter = Offset(size.width / 2, padding);
    final double maxVisualWidth = size.width - padding * 2;
    final double maxVisualHeight = size.height - padding * 2;

    // Масштаб: метры -> пиксели
    final double widthInMeters = 2 * rMax;
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

    // Если параметры несовместимы
    if (impossible) {
      paintText.text = TextSpan(
        text: 'Параметры несовместимы: длина сегмента s ≤ h',
        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
      );
      paintText.layout(maxWidth: size.width - 20);
      paintText.paint(canvas, Offset(10, size.height / 2 - 10));
      return;
    }

    // Строим крючки (hooks) с постепенным расширением
    final List<Offset> points = [];
    double accumulatedY = 0.0;
    bool toLeft = true;

    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      // Радиус на текущей высоте (линейное расширение)
      final double currentRadius = rMax * (accumulatedY / H);

      // Горизонтальное смещение для текущего уровня
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
    garlandPath.moveTo(topCenter.dx, topCenter.dy);
    for (final p in points) {
      garlandPath.lineTo(p.dx, p.dy);
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

    // Выводим сводную информацию
    final double baseWidth = 2 * rMax;
    final double coneAngle = atan(rMax / H) * 180 / pi;
    final summary =
        'L=${L.toStringAsFixed(2)}м  H=${H.toStringAsFixed(2)}м  Hooks: $hooks\n'
        'Основание конуса: ${baseWidth.toStringAsFixed(2)}м  '
        'Угол: ${coneAngle.toStringAsFixed(1)}°';
    paintText.text = TextSpan(
      text: summary,
      style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
    );
    paintText.layout(maxWidth: size.width - 20);
    paintText.paint(canvas, Offset(10, 6));

    // Рисуем маленькие метки на центральной оси
    final tickPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1;
    accumulatedY = 0.0;
    for (int i = 0; i < segments; i++) {
      accumulatedY += h;
      final double y = topCenter.dy + accumulatedY * scale;
      canvas.drawLine(Offset(topCenter.dx - 5, y), Offset(topCenter.dx + 5, y), tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CornerTreePainter oldDelegate) {
    return oldDelegate.L != L || oldDelegate.H != H || oldDelegate.hooks != hooks;
  }
}
