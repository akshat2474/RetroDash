import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'animated_background.dart';

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
              'START GAME',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
  bool _gameOver = false;
  final Random _random = Random();
  
  double _playerX = 0.5; // Position as percentage of screen width

  @override
  void initState() {
    super.initState();
    _startGame();
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

  void _startGame() {
    // Game loop
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      _updateGame();
    });
    
    // Enemy spawning
    _enemySpawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      _spawnEnemy();
    });
    
    // Auto-fire projectiles
    _projectileTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      _fireProjectile();
    });
  }

  void _spawnEnemy() {
    if (_gameOver) return;
    
    final size = MediaQuery.of(context).size;
    final enemy = Enemy(
      x: _random.nextDouble() * size.width,
      y: -50,
      width: 40 + _random.nextDouble(),
      height: 40 + _random.nextDouble(),
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
    
    setState(() {
      _projectiles.add(projectile);
    });
  }

  void _updateGame() {
    if (_gameOver) return;
    
    setState(() {
      // Update player position to follow touch/drag
      _player.x = MediaQuery.of(context).size.width * _playerX;
      
      // Move projectiles
      for (int i = _projectiles.length - 1; i >= 0; i--) {
        _projectiles[i].y -= _projectiles[i].speed;
        
        // Remove projectiles that go off screen
        if (_projectiles[i].y < -50) {
          _projectiles.removeAt(i);
        }
      }
      
      // Move enemies
      final size = MediaQuery.of(context).size;
      for (int i = _enemies.length - 1; i >= 0; i--) {
        _enemies[i].y += _enemies[i].speed;
        
        // Remove enemies that go off screen
        if (_enemies[i].y > size.height + 50) {
          _enemies.removeAt(i);
          continue;
        }
        
        // Check collision with player
        if (_checkCollision(_player, _enemies[i])) {
          _gameOver = true;
          _addExplosion(_player.x, _player.y);
          _endGame();
          break;
          
        }
        
        // Check collision with projectiles
        for (int j = _projectiles.length - 1; j >= 0; j--) {
          if (_checkCollision(_projectiles[j], _enemies[i])) {
            _enemies[i].health--;
            _projectiles.removeAt(j);
            
            if (_enemies[i].health <= 0) {
              _addExplosion(_enemies[i].x, _enemies[i].y);
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
    
    // Show game over after a short delay
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
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.8),
        title: const Text(
          'GAME OVER',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              'Your Score: $score',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.cyanAccent),
              ),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const GameScreen()),
                );
              },
              child: const Text('PLAY AGAIN'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _enemySpawnTimer?.cancel();
    _projectileTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          // Update player position (as percentage of screen width)
          final screenWidth = MediaQuery.of(context).size.width;
          _playerX += details.delta.dx / screenWidth;
          
          // Clamp player position
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
          
          // Player ship
          CustomPaint(
            painter: PlayerPainter(_player),
            size: Size.infinite,
          ),
          
          // Enemies
          for (final enemy in _enemies)
            CustomPaint(
              painter: EnemyPainter(enemy),
              size: Size.infinite,
            ),
          
          // Projectiles  
          for (final projectile in _projectiles)
            CustomPaint(
              painter: ProjectilePainter(projectile),
              size: Size.infinite,
            ),
            
          // Explosions
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

// Base class for game objects
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

// Custom painters
class PlayerPainter extends CustomPainter {
  final Player player;
  
  PlayerPainter(this.player);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.fill;
    
    // Draw player ship
    final path = Path();
    path.moveTo(player.x, player.y - player.height / 2);
    path.lineTo(player.x - player.width / 2, player.y + player.height / 2);
    path.lineTo(player.x + player.width / 2, player.y + player.height / 2);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw engine glow
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
    // Different colors for different enemy health
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
      
    // Draw alien ship
    final path = Path();
    path.moveTo(enemy.x, enemy.y - enemy.height / 2);
    path.lineTo(enemy.x - enemy.width / 2, enemy.y);
    path.lineTo(enemy.x - enemy.width / 3, enemy.y + enemy.height / 2);
    path.lineTo(enemy.x + enemy.width / 3, enemy.y + enemy.height / 2);
    path.lineTo(enemy.x + enemy.width / 2, enemy.y);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Draw evil eye
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
    
    // Add glow effect
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
    
    // Core of explosion
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

