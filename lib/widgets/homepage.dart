import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'profile.dart';

class AnimatedHomePage extends StatefulWidget {
  const AnimatedHomePage({super.key});

  @override
  _AnimatedHomePageState createState() => _AnimatedHomePageState();
}

class _AnimatedHomePageState extends State<AnimatedHomePage>
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _buttonController;
  late AnimationController _particleController;
  late AnimationController _pulseController;

  late Animation<double> _titleScale;
  late Animation<double> _titleGlow;
  late Animation<double> _buttonScale;
  late Animation<double> _buttonHover;
  late Animation<double> _pulseAnimation;

  bool _showOptions = false;

  final Random _random = Random();
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _titleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _titleScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );

    _titleGlow = Tween<double>(begin: 1.0, end: 2.5).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeInOut),
    );

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOutBack),
    );

    _buttonHover = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeOut),
    );

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

    Future.delayed(const Duration(milliseconds: 300), () {
      _animateEntrance();
    });
  }

  bool _particlesGenerated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_particlesGenerated) {
      _generateParticles();
      _particlesGenerated = true;
    }
  }

  void _animateEntrance() {
    _titleController.forward(from: 0.0);
  }

  void _generateParticles() {
    _particles.clear();

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    for (int i = 0; i < 50; i++) {
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
    final colors = [
      Colors.cyanAccent,
      Colors.pinkAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.amberAccent,
    ];
    return colors[_random.nextInt(colors.length)];
  }

  void _updateParticles() {
    if (!mounted) return;

    final double screenHeight = MediaQuery.of(context).size.width;

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
    _titleController.dispose();
    _buttonController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Show the game options
  void _toggleOptions() {
    setState(() {
      _showOptions = !_showOptions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background
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
                      const Color(0xFF0A0E17),
                    ],
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                left: -10 + 20 * _pulseAnimation.value,
                top: -10 + 20 * _pulseAnimation.value,
                right: -10 + 20 * _pulseAnimation.value,
                bottom: -10 + 20 * _pulseAnimation.value,
                child: Opacity(
                  opacity: 0.7,
                  // child: Image.asset(
                  //   'assets/images/b10.png',
                  //   fit: BoxFit.cover,
                  // ),
                ),
              );
            },
          ),

          CustomPaint(
            painter: ParticlePainter(_particles),
            size: Size.infinite,
          ),
          CustomPaint(painter: GridPainter(), size: Size.infinite),

          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_titleScale, _titleGlow]),
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withOpacity(
                                0.2 * _titleGlow.value,
                              ),
                              blurRadius: 25 * _titleGlow.value,
                              spreadRadius: 5 * _titleGlow.value,
                            ),
                          ],
                        ),
                        child: Transform.scale(
                          scale: _titleScale.value,
                          child: Column(
                            children: [
                              const SizedBox(height: 130),
                              const Text(
                                'RETRO',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'PixelFont',
                                  fontSize: 50,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 5,
                                  height: 0.9,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 15.0,
                                      color: Colors.cyanAccent,
                                      offset: Offset(0, 0),
                                    ),
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.pinkAccent,
                                      offset: Offset(3, 3),
                                    ),
                                  ],
                                ),
                              ),
                              ShaderMask(
                                shaderCallback: (Rect bounds) {
                                  return const LinearGradient(
                                    colors: [
                                      Colors.cyanAccent,
                                      Colors.pinkAccent,
                                      Colors.purpleAccent,
                                      Colors.blueAccent,
                                    ],
                                    tileMode: TileMode.mirror,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'DASH',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 58,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 5,
                                    height: 0.9,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 18.0,
                                        color: Colors.black,
                                        offset: Offset(2, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 60),

                  GestureDetector(
                    onTapDown: (_) => _buttonController.forward(),
                    onTapUp: (_) {
                      _buttonController.reverse();
                      _toggleOptions();
                    },
                    onTapCancel: () => _buttonController.reverse(),
                    child: AnimatedBuilder(
                      animation: _buttonController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonScale.value,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 45,
                              vertical: 20,
                            ),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                Colors.pinkAccent,
                                Colors.purpleAccent,
                                _buttonHover.value,
                              ),
                              border: Border.all(color: Colors.white, width: 4),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black87,
                                  offset: const Offset(6, 6),
                                  blurRadius: 0,
                                ),
                                BoxShadow(
                                  color: Colors.pinkAccent.withOpacity(0.5),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Text(
                              'START GAME',
                              style: TextStyle(
                                fontFamily: 'PixelFont',
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 4.0,
                                    color: Colors.deepPurple,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Game options that appear when Start Game is pressed
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: SizedBox(
                      height: _showOptions ? null : 0,
                      child:
                          _showOptions
                              ? Column(
                                children: [
                                  const SizedBox(height: 20),
                                  _buildOptionButton(
                                    'NEW GAME',
                                    Colors.greenAccent,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildOptionButton(
                                    'CONTINUE',
                                    Colors.amberAccent,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildOptionButton(
                                    'PROFILE',
                                    Colors.blueAccent,
                                  ),
                                ],
                              )
                              : null,
                    ),
                  ),

                  const Spacer(),

                  _buildCreditsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String text, Color color) {
    return GestureDetector(
      onTap: () {
        // Handle option button taps
        if (text == 'PROFILE') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()),
          );
        } else if (text == 'NEW GAME') {
          // Start new game
        } else if (text == 'CONTINUE') {
          // Continue saved game
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'PixelFont',
            fontSize: 16,
            color: color,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildCreditsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyanAccent.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Colors.cyanAccent, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Text(
              'MADE BY AKSHAT',
              style: TextStyle(
                fontFamily: 'PixelFont',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                FontAwesomeIcons.github,
                Colors.white,
                () => _launchUrl('https://github.com/akshat2474'),
              ),
              const SizedBox(width: 20),
              _buildSocialButton(
                FontAwesomeIcons.linkedin,
                Colors.cyanAccent,
                () => _launchUrl(
                  'https://www.linkedin.com/in/akshat-singh-48a03b312/',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: FaIcon(icon, color: color, size: 24),
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
      final paint =
          Paint()
            ..color = particle.color.withOpacity(particle.opacity)
            ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// Custom painter for grid lines
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.cyanAccent.withOpacity(0.15)
          ..strokeWidth = 1.0;

    // Draw horizontal lines
    final horizontalLineCount = 20;
    final verticalLineCount = 20;

    // Horizontal lines
    final double horizontalSpacing = size.height / horizontalLineCount;
    for (int i = 0; i <= horizontalLineCount; i++) {
      final double y = i * horizontalSpacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical lines
    final double verticalSpacing = size.width / verticalLineCount;
    for (int i = 0; i <= verticalLineCount; i++) {
      final double x = i * verticalSpacing;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
