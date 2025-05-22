import 'package:flutter/material.dart';
import 'dart:math';

class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color backgroundColor;
  final Color gridColor;
  final double gridLineWidth;
  final int horizontalGridCount;
  final int verticalGridCount;
  final bool showGrid;
  final bool showParticles;
  final List<Color> particleColors;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
    this.backgroundColor = const Color(0xFF0A0E17),
    this.gridColor = const Color(0x2600FFFF), // Colors.cyanAccent.withOpacity(0.15)
    this.gridLineWidth = 1.0,
    this.horizontalGridCount = 20,
    this.verticalGridCount = 20,
    this.showGrid = true,
    this.showParticles = true,
    this.particleColors = const [
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.amberAccent,
    ],
  });

  @override
  _AnimatedBackgroundState createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final Random _random = Random();
  final List<Particle> _particles = [];

  bool _particlesGenerated = false;

  @override
  void initState() {
    super.initState();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _particleController.addListener(_updateParticles);
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_particlesGenerated && widget.showParticles) {
      _generateParticles();
      _particlesGenerated = true;
    }
  }

  void _generateParticles() {
    _particles.clear();

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble() * screenWidth,
          y: _random.nextDouble() * screenHeight,
          size: _random.nextDouble() * 4 + 1,
          speed: _random.nextDouble() * 30 + 10,
          opacity: _random.nextDouble() * 0.7 + 0.3,
          color: _getRandomColor(),
        ),
      );
    }
  }

  Color _getRandomColor() {
    return widget.particleColors[_random.nextInt(widget.particleColors.length)];
  }

  void _updateParticles() {
    if (!mounted || !widget.showParticles) return;

    final double screenHeight = MediaQuery.of(context).size.height;

    setState(() {
      for (var particle in _particles) {
        particle.y -= particle.speed * 0.01;
        if (particle.y < 0) {
          particle.y = screenHeight;
          particle.x = _random.nextDouble() * MediaQuery.of(context).size.width;
          particle.opacity = _random.nextDouble() * 0.7 + 0.3;
        }
      }
    });
  }

  @override
  void dispose() {
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [

          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Color.lerp(
                        const Color(0xFF1A1F35),
                        const Color(0xFF2A2F45),
                        _pulseAnimation.value,
                      )!,
                      widget.backgroundColor,
                    ],
                  ),
                ),
              );
            },
          ),
          
          if (widget.showParticles)
            CustomPaint(
              painter: ParticlePainter(_particles),
              size: Size.infinite,
            ),
          
          if (widget.showGrid)
            CustomPaint(
              painter: GridPainter(
                gridColor: widget.gridColor, 
                lineWidth: widget.gridLineWidth,
                horizontalLineCount: widget.horizontalGridCount,
                verticalLineCount: widget.verticalGridCount,
              ), 
              size: Size.infinite,
            ),
          widget.child,
        ],
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  Color color;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.color,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = particle.color.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  final Color gridColor;
  final double lineWidth;
  final int horizontalLineCount;
  final int verticalLineCount;

  GridPainter({
    required this.gridColor,
    required this.lineWidth,
    required this.horizontalLineCount,
    required this.verticalLineCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = lineWidth;

    final double horizontalSpacing = size.height / horizontalLineCount;
    for (int i = 0; i <= horizontalLineCount; i++) {
      final double y = i * horizontalSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final double verticalSpacing = size.width / verticalLineCount;
    for (int i = 0; i <= verticalLineCount; i++) {
      final double x = i * verticalSpacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}