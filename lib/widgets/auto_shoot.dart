import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'animated_background.dart';
import 'audio_player.dart';
import 'homepage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const SpaceBlasterApp());
}

class SpaceBlasterApp extends StatelessWidget {
  const SpaceBlasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Space Blaster',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _gameStarted = false;

  void _startGame() {
    setState(() {
      _gameStarted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      backgroundColor: const Color(0xFF0A0E17),
      showGrid: true,
      showParticles: true,
      particleCount: 50,
      particleColors: const [
        Colors.cyanAccent,
        Colors.blueAccent,
        Colors.purpleAccent,
        Colors.white,
      ],
      child: SafeArea(
        child: _gameStarted
            ? const GameplayScreen()
            : StartScreen(onStart: _startGame),
      ),
    );
  }
}

class StartScreen extends StatelessWidget {
  final VoidCallback onStart;

  const StartScreen({super.key, required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'SPACE BLASTER',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Colors.cyanAccent.withOpacity(0.7),
                  blurRadius: 15,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 60),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 8,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Colors.cyanAccent, width: 2),
              ),
            ),
            child: const Text(
              'AUTO FIRE',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: onStart,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 8,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Colors.cyanAccent, width: 2),
              ),
            ),
            child: const Text(
              'HARD MODE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({super.key});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  late final Player _player;
  final List<Enemy> _enemies = [];
  final List<Projectile> _projectiles = [];
  final List<Explosion> _explosions = [];
  
  Timer? _gameTimer;
  Timer? _enemySpawnTimer;
  Timer? _projectileTimer;
  int score = 0;
  int lives = 3; // Add lives system
  bool _gameOver = false;
  final Random _random = Random();
  
  double _playerX = 0.5; 

  final GameAudio _gameAudio = GameAudio();
  bool _audioInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    try {
      debugPrint('Initializing game resources...');
      
      debugPrint('Attempting to initialize audio...');
      await _gameAudio.initialize();
      
      setState(() {
        _audioInitialized = true;
      });
      
      debugPrint('Audio initialization complete');
    } catch (e) {
      debugPrint('Error during audio initialization: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sound effects could not be initialized'),
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      _startGameLoop();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = MediaQuery.of(context).size;
    _player = Player(
      x: screenSize.width * _playerX,
      y: screenSize.height * 0.85,
      width: 60,
      height: 60,
    );
  }

  void _startGameLoop() {
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
    
    _enemySpawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _spawnEnemy();
    });
    
    _projectileTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      _fireProjectile();
    });
  }

  void _spawnEnemy() {
    if (_gameOver) return;
    
    final size = MediaQuery.of(context).size;
    // Spawn enemies only in 90% of screen width (5% margin on each side)
    final spawnAreaWidth = size.width * 0.9;
    final spawnAreaStart = size.width * 0.05;
    
    final enemy = Enemy(
      x: spawnAreaStart + (_random.nextDouble() * spawnAreaWidth),
      y: -50,
      width: 40 + _random.nextDouble() * 10,
      height: 40 + _random.nextDouble() * 10,
      speed: 1 + _random.nextDouble() * 3,
      health: 1 + _random.nextInt(3),
    );
    
    setState(() {
      _enemies.add(enemy);
    });
  }

  void _fireProjectile() {
    if (_gameOver) return;
    
    final projectile = Projectile(
      x: _player.x,
      y: _player.y - 20,
      width: 5,
      height: 20,
      speed: 8,
    );

    if (_audioInitialized) {
      _gameAudio.playBlastSound();
    }
    
    setState(() {
      _projectiles.add(projectile);
    });
  }

  void _loseLife() {
    setState(() {
      lives--;
    });
    
    if (lives <= 0) {
      _gameOver = true;
      _endGame();
    }
  }

  void _updateGame() {
    if (_gameOver) return;
    
    setState(() {
      _player.x = MediaQuery.of(context).size.width * _playerX;
    
      for (int i = _projectiles.length - 1; i >= 0; i--) {
        _projectiles[i].y -= _projectiles[i].speed;
        
        if (_projectiles[i].y < -50) {
          _projectiles.removeAt(i);
        }
      }
      
      final size = MediaQuery.of(context).size;
      for (int i = _enemies.length - 1; i >= 0; i--) {
        _enemies[i].y += _enemies[i].speed;
        
        // Check if enemy fell out of screen (missed by player)
        if (_enemies[i].y > size.height + 50) {
          _enemies.removeAt(i);
          _loseLife(); // Lose life when enemy is missed
          continue;
        }
        
        // Check collision with player
        if (_checkCollision(_player, _enemies[i])) {
          _addExplosion(_player.x, _player.y);
          
          if (_audioInitialized) {
            _gameAudio.playExplosionSound();
          }
          
          _enemies.removeAt(i);
          _loseLife(); // Lose life when hit by enemy
          continue;
        }
        
        // Check collision with projectiles
        for (int j = _projectiles.length - 1; j >= 0; j--) {
          if (_checkCollision(_projectiles[j], _enemies[i])) {
            _enemies[i].health--;
            _projectiles.removeAt(j);
            
            if (_enemies[i].health <= 0) {
              _addExplosion(_enemies[i].x, _enemies[i].y);

              if (_audioInitialized) {
                _gameAudio.playExplosionSound();
              }
              
              score += 10;
              _enemies.removeAt(i);
            }
            break;
          }
        }
      }
      
      // Update explosions
      for (int i = _explosions.length - 1; i >= 0; i--) {
        _explosions[i].timeToLive--;
        if (_explosions[i].timeToLive <= 0) {
          _explosions.removeAt(i);
        }
      }
    });
  }
  
  bool _checkCollision(GameObject a, GameObject b) {
    return (a.x < b.x + b.width &&
        a.x + a.width > b.x &&
        a.y < b.y + b.height &&
        a.y + a.height > b.y);
  }
  
  void _addExplosion(double x, double y) {
    setState(() {
      _explosions.add(Explosion(x: x, y: y, timeToLive: 20));
    });
  }
  
  void _endGame() {
    _gameTimer?.cancel();
    _enemySpawnTimer?.cancel();
    _projectileTimer?.cancel();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _showGameOverDialog();
      }
    });
  }
  
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.red.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAME OVER',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.red.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 24),
                        const SizedBox(width: 10),
                        Text(
                          'FINAL SCORE',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.amber.shade300,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.stars, color: Colors.amber, size: 24),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Lives Lost: ${3 - lives}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.cyanAccent, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const GameScreen()),
                      );
                    },
                    icon: const Icon(Icons.refresh, size: 20),
                    label: const Text(
                      'PLAY AGAIN',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.red, width: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const AnimatedHomePage()),
                      );
                    },
                    icon: const Icon(Icons.home, size: 20),
                    label: const Text(
                      'MAIN MENU',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _enemySpawnTimer?.cancel();
    _projectileTimer?.cancel();
    _gameAudio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          final screenWidth = MediaQuery.of(context).size.width;
          _playerX += details.delta.dx / screenWidth;
          
          _playerX = _playerX.clamp(0.05, 0.95);
        });
      },
      child: Stack(
        children: [
          // Score display
          Positioned(
            top: 20,
            left: 20,
            child: Text(
              'SCORE: $score',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Lives display
          Positioned(
            top: 20,
            right: 20,
            child: Row(
              children: [
                const Text(
                  'LIVES: ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                for (int i = 0; i < lives; i++)
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                for (int i = lives; i < 3; i++)
                  Container(
                    margin: const EdgeInsets.only(left: 5),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.grey,
                      size: 24,
                    ),
                  ),
              ],
            ),
          ),
          
          CustomPaint(
            painter: PlayerPainter(_player),
            size: Size.infinite,
          ),
        
          for (final enemy in _enemies)
            CustomPaint(
              painter: EnemyPainter(enemy),
              size: Size.infinite,
            ),
          
          for (final projectile in _projectiles)
            CustomPaint(
              painter: ProjectilePainter(projectile),
              size: Size.infinite,
            ),
            
          for (final explosion in _explosions)
            CustomPaint(
              painter: ExplosionPainter(explosion),
              size: Size.infinite,
            ),
        ],
      ),
    );
  }
}

class GameObject {
  double x;
  double y;
  double width;
  double height;
  
  GameObject({
    required this.x, 
    required this.y, 
    required this.width, 
    required this.height,
  });
}

class Player extends GameObject {
  Player({
    required super.x, 
    required super.y, 
    required super.width, 
    required super.height,
  });
}

class Enemy extends GameObject {
  double speed;
  int health;
  
  Enemy({
    required super.x, 
    required super.y, 
    required super.width, 
    required super.height,
    required this.speed,
    required this.health,
  });
}

class Projectile extends GameObject {
  double speed;
  
  Projectile({
    required super.x, 
    required super.y, 
    required super.width, 
    required super.height,
    required this.speed,
  });
}

class Explosion {
  double x;
  double y;
  int timeToLive;
  
  Explosion({
    required this.x,
    required this.y,
    required this.timeToLive,
  });
}

class PlayerPainter extends CustomPainter {
  final Player player;
  
  PlayerPainter(this.player);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    
    final path = Path();
    path.moveTo(player.x, player.y - player.height / 2);
    path.lineTo(player.x - player.width / 2, player.y + player.height / 2);
    path.lineTo(player.x + player.width / 2, player.y + player.height / 2);
    path.close();
    
    canvas.drawPath(path, paint);
    
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    
    canvas.drawCircle(
      Offset(player.x, player.y + player.height / 3),
      player.width / 4,
      glowPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnemyPainter extends CustomPainter {
  final Enemy enemy;
  final Random _random = Random();
  
  EnemyPainter(this.enemy);
  
  @override
  void paint(Canvas canvas, Size size) {
    Color enemyColor;
    switch (enemy.health) {
      case 1:
        enemyColor = Colors.redAccent;
        break;
      case 2:
        enemyColor = Colors.orangeAccent;
        break;
      default:
        enemyColor = Colors.purpleAccent;
    }
    
    final paint = Paint()
      ..color = enemyColor
      ..style = PaintingStyle.fill;
      
    final path = Path();
    path.moveTo(enemy.x, enemy.y - enemy.height / 2);
    path.lineTo(enemy.x - enemy.width / 2, enemy.y);
    path.lineTo(enemy.x - enemy.width / 3, enemy.y + enemy.height / 2);
    path.lineTo(enemy.x + enemy.width / 3, enemy.y + enemy.height / 2);
    path.lineTo(enemy.x + enemy.width / 2, enemy.y);
    path.close();
    
    canvas.drawPath(path, paint);

    final eyePaint = Paint()
      ..color = Colors.white;
    
    canvas.drawCircle(
      Offset(enemy.x, enemy.y),
      enemy.width / 5,
      eyePaint,
    );
    
    final pupilPaint = Paint()
      ..color = Colors.black;
      
    canvas.drawCircle(
      Offset(enemy.x, enemy.y),
      enemy.width / 10,
      pupilPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ProjectilePainter extends CustomPainter {
  final Projectile projectile;
  
  ProjectilePainter(this.projectile);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
      
    // Draw laser bolt
    canvas.drawRect(
      Rect.fromLTWH(
        projectile.x - projectile.width / 2,
        projectile.y - projectile.height / 2,
        projectile.width,
        projectile.height,
      ),
      paint,
    );
    
    final glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
    canvas.drawRect(
      Rect.fromLTWH(
        projectile.x - projectile.width * 1.5,
        projectile.y - projectile.height / 2,
        projectile.width * 3,
        projectile.height,
      ),
      glowPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ExplosionPainter extends CustomPainter {
  final Explosion explosion;
  final Random _random = Random();
  
  ExplosionPainter(this.explosion);
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create particles for explosion
    final int particleCount = 12;
    final radius = 10 + (20 - explosion.timeToLive);
    
    for (int i = 0; i < particleCount; i++) {
      final angle = i * (2 * pi / particleCount);
      final distance = radius * (0.8 + _random.nextDouble() * 0.4);
      
      final x = explosion.x + cos(angle) * distance;
      final y = explosion.y + sin(angle) * distance;
      
      final opacity = explosion.timeToLive / 20;
      
      final paint = Paint()
        ..color = (_random.nextBool() 
          ? Colors.orangeAccent 
          : Colors.redAccent).withOpacity(opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(x, y),
        2 + _random.nextDouble() * 3,
        paint,
      );
    }
    
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(explosion.timeToLive / 30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      
    canvas.drawCircle(
      Offset(explosion.x, explosion.y),
      radius * 0.5,
      corePaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

