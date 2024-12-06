import 'dart:async' show Timer;
import 'dart:math' as math;
import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

const List<Color> colors = <Color>[
  Color(0xFF581845),
  Color(0xFF900C3F),
  Color(0xFFC70039),
  Color(0xFFFF5733),
  Color(0xFFFFC30F),
];

final Random random = Random();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const App(),
      theme: ThemeData(useMaterial3: true),
      title: 'Flutter Demo',
    );
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Sketch(size: constraints.biggest);
          },
        ),
      ),
    );
  }
}

final class Sketch extends StatefulWidget {
  const Sketch({required this.size, super.key});

  final Size size;

  @override
  SketchState createState() {
    return SketchState();
  }
}

final class SketchState extends State<Sketch> {
  final List<Particle> particles = <Particle>[];

  @pragma('dart2js:late:trust')
  late Offset center;

  @pragma('dart2js:late:trust')
  late double scaleX;

  @pragma('dart2js:late:trust')
  late double scaleY;

  int variation = 0;
  Timer? variationTimer;

  double step = 0.0;
  Duration last = Duration.zero;
  Ticker? ticker;

  void resize(Size size) {
    center = size.center(Offset.zero);
    scaleX = size.width / 20.0;
    scaleY = size.height / 20.0 * size.aspectRatio;
  }

  @override
  void initState() {
    super.initState();
    resize(widget.size);

    variationTimer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      variation += 1;

      if (variation > 11) {
        variation = 0;
      }
    });

    ticker = Ticker((Duration elapsed) {
      setState(() {
        Duration delta = elapsed - last;
        last = elapsed;
        step = delta.inMilliseconds * 0.001;
        particles.retainWhere(Particle.filter);
      });
    });

    ticker!.start();
  }

  @override
  void didUpdateWidget(Sketch oldWidget) {
    super.didUpdateWidget(oldWidget);
    resize(widget.size);
  }

  @override
  void dispose() {
    ticker?.dispose();
    variationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Color(0xFF1A0633),
      ),
      child: GestureDetector(
        child: CustomPaint(
          painter: AppPainter(
            particles,
            variation,
            step,
            scaleX,
            scaleY,
          ),
        ),
        onPanUpdate: (DragUpdateDetails details) {
          Offset position = details.localPosition - center;

          Offset particelPosition = position.translate(
            random.nextDouble() * 100.0 - 50.0,
            random.nextDouble() * 100.0 - 50.0,
          );

          particles.add(Particle(
            particelPosition.scale(
              1.0 / scaleX,
              1.0 / scaleY,
            ),
          ));
        },
      ),
    );
  }
}

final class AppPainter extends CustomPainter {
  AppPainter(
    this.particles,
    this.variation,
    this.step,
    this.scaleX,
    this.scaleY,
  );

  final List<Particle> particles;

  final int variation;

  final double step;

  final double scaleX;

  final double scaleY;

  Offset slope(Particle particle) {
    double dx = particle.position.dx;
    double dy = particle.position.dy;

    double x, y;

    switch (variation) {
      case 0:
        x = math.cos(dy);
        y = math.sin(dx);
        break;
      case 1:
        x = math.cos(dy * 5.0) * dx * 0.3;
        y = math.sin(dx * 5.0) * dy * 0.3;
        break;
      case 2:
        x = 1.0;
        y = math.cos(dx * dy);
        break;
      case 3:
        x = 1.0;
        y = math.sin(dx) * math.cos(dy);
        break;
      case 4:
        x = 1.0;
        y = math.cos(dx) * dy * dy;
        break;
      case 5:
        x = 1.0;
        y = math.log(dx.abs()) * math.log(dy.abs());
        break;
      case 6:
        x = 1.0;
        y = math.tan(dx) * math.cos(dy);
        break;
      case 7:
        x = math.sin(dy * 0.1) * 3.0;
        y = -math.sin(dx * 0.1) * 3.0;
        break;
      case 8:
        x = dy / 3.0;
        y = (dx - dx * dx * dx) * 0.01;
        break;
      case 9:
        x = -dy;
        y = -math.sin(dx);
        break;
      case 10:
        x = -1.5 * dy;
        y = -dy - math.sin(1.5 * dx) + 0.7;
        break;
      default:
        x = math.sin(dy) * math.cos(dx);
        y = math.sin(dx) * math.cos(dy);
    }

    particle.position = particle.position.translate(
      particle.direction * x * step,
      particle.direction * y * step,
    );

    return particle.position.scale(scaleX, scaleY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();

    Offset center = size.center(Offset.zero);

    for (Particle particle in particles.reversed) {
      Offset position = center + slope(particle);
      Size sizeOffset = size + const Offset(400.0, 400.0);
      Offset positionOffset = position + const Offset(200.0, 200.0);

      if (sizeOffset.contains(positionOffset)) {
        Offset? lastPosition = particle.lastPosition;

        if (lastPosition != null) {
          paint.color = particle.color;
          paint.strokeWidth = particle.size;
          paint.strokeCap = StrokeCap.round;
          canvas.drawLine(position, lastPosition, paint);
        }

        particle.lastPosition = position;
      } else {
        particle.visible = false;
      }
    }
  }

  @override
  bool shouldRepaint(AppPainter oldDelegate) {
    return true;
  }
}

class Particle {
  Particle(this.position)
      : size = random.nextDouble() * 5.0,
        color = colors[random.nextInt(colors.length)],
        direction = random.nextDouble().clamp(0.1, 1.0) * (random.nextBool() ? 1.0 : -1.0),
        visible = true;

  Offset position;

  Offset? lastPosition;

  double size;

  Color color;

  double direction;

  bool visible;

  static bool filter(Particle particle) {
    return particle.visible;
  }
}
