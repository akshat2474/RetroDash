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
  bool _autoFireMode = true; // Track game mode

  void _startGame(bool autoFire) {
    setState(() {
      _gameStarted = true;
      _autoFireMode = autoFire;
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
            ? GameplayScreen(autoFire: _autoFireMode)
            : StartScreen(onStart: _startGame),
      ),
    );
  }
}

class StartScreen extends StatelessWidget {
  final Function(bool) onStart;

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
            onPressed: () => onStart(true),
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
            onPressed: () => onStart(false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent.withOpacity(0.2),
              foregroundColor: Colors.white,
              elevation: 8,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Colors.orangeAccent, width: 2),
              ),
            ),
            child: const Text(
              'MANUAL FIRE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

class GameplayScreen extends StatefulWidget {
  final bool autoFire;
  
  const GameplayScreen({super.key, required this.autoFire});

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> with TickerProviderStateMixin {
  late final Player _player;
  final List<Enemy> _enemies = [];
  final List<Projectile> _projectiles = [];
  final List<Explosion> _explosions = [];
  
  Timer? _gameTimer;
  Timer? _enemySpawnTimer;
  Timer? _projectileTimer;
  Timer? _instructionTimer;
  int score = 0;
  int lives = 3;
  bool _gameOver = false;
  final Random _random = Random();
  
  // Power-up states
  bool _rapidFireActive = false;
  Timer? _rapidFireTimer;
  bool _hasRapidFirePowerUp = false;
  bool _hasBigExplosionPowerUp = false;
  
  // Fire rate variables
  int _baseFireRate = 400; // milliseconds
  int get _currentFireRate => _rapidFireActive ? (_baseFireRate ~/ 2) : _baseFireRate;
  
  double _playerX = 0.5; 
  bool _isDragging = false; // Track if user is dragging

  final GameAudio _gameAudio = GameAudio();
  bool _audioInitialized = false;
  
  // Animation controller for tap instruction
  late AnimationController _instructionAnimationController;
  late Animation<double> _instructionOpacity;
  bool _showInstruction = false;

  // Power-up animation controllers
  late AnimationController _powerUpAnimationController;
  late Animation<double> _powerUpPulse;

  // Power-up message animation
  late AnimationController _powerUpMessageController;
  late Animation<double> _powerUpMessageOpacity;
  late Animation<double> _powerUpMessageScale;
  String _powerUpMessage = '';
  bool _showPowerUpMessage = false;

  // Nuclear explosion animation
  late AnimationController _nukeAnimationController;
  late Animation<double> _nukeFlashOpacity;
  late Animation<double> _nukeShockwaveRadius;
  late Animation<double> _nukeShockwaveOpacity;
  late Animation<double> _screenShakeX;
  late Animation<double> _screenShakeY;
  bool _showNukeEffect = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _instructionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _instructionOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _instructionAnimationController,
      curve: Curves.easeOut,
    ));
    
    _powerUpAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _powerUpPulse = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _powerUpAnimationController,
      curve: Curves.easeInOut,
    ));

    // Power-up message animation
    _powerUpMessageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _powerUpMessageOpacity = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _powerUpMessageController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));

    _powerUpMessageScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _powerUpMessageController,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));

    // Nuclear explosion animation
    _nukeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _nukeFlashOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _nukeAnimationController,
      curve: const Interval(0.0, 0.1, curve: Curves.easeOut),
    ));

    _nukeShockwaveRadius = Tween<double>(
      begin: 0.0,
      end: 1500.0,
    ).animate(CurvedAnimation(
      parent: _nukeAnimationController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
    ));

    _nukeShockwaveOpacity = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _nukeAnimationController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOut),
    ));

    _screenShakeX = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_nukeAnimationController);

    _screenShakeY = Tween<double>(
      begin: 0.0,
      end: 0.0,
    ).animate(_nukeAnimationController);
    
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sound effects could not be initialized'),
            duration: Duration(seconds: 2),
          ),
        );
      }
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
    
    // Only start auto-fire timer if in auto-fire mode
    if (widget.autoFire) {
      _startAutoFireTimer();
    } else {
      // Show instruction for manual fire mode
      setState(() {
        _showInstruction = true;
      });
      
      // Start fade out animation after 3.5 seconds, complete fade by 5 seconds
      _instructionTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          _instructionAnimationController.forward().then((_) {
            if (mounted) {
              setState(() {
                _showInstruction = false;
              });
            }
          });
        }
      });
    }
  }

  void _startAutoFireTimer() {
    _projectileTimer?.cancel();
    _projectileTimer = Timer.periodic(Duration(milliseconds: _currentFireRate), (timer) {
      if (!_gameOver) {
        _fireProjectile();
      }
    });
  }

  void _updateFireRate() {
    if (widget.autoFire) {
      _startAutoFireTimer();
    }
  }

  void _spawnEnemy() {
    if (_gameOver) return;
    
    final size = MediaQuery.of(context).size;
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

  void _onScreenTap(TapDownDetails details) {
    // Only fire manually if not in auto-fire mode and not dragging
    if (!widget.autoFire && !_isDragging) {
      _fireProjectile();
    }
  }

  void _showPowerUpUnlockedMessage(String powerUpName) {
    setState(() {
      _powerUpMessage = '$powerUpName UNLOCKED!';
      _showPowerUpMessage = true;
    });

    _powerUpMessageController.reset();
    _powerUpMessageController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showPowerUpMessage = false;
        });
      }
    });
  }

  void _useRapidFirePowerUp() {
    if (!_hasRapidFirePowerUp || _rapidFireActive || _gameOver) return;
    
    debugPrint('Activating Rapid Fire power-up');
    
    setState(() {
      _rapidFireActive = true;
      _hasRapidFirePowerUp = false;
    });
    
    // Show activation message
    setState(() {
      _powerUpMessage = 'RAPID FIRE ACTIVATED!';
      _showPowerUpMessage = true;
    });

    _powerUpMessageController.reset();
    _powerUpMessageController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showPowerUpMessage = false;
        });
      }
    });
    
    _updateFireRate();
    
    _rapidFireTimer?.cancel();
    _rapidFireTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _rapidFireActive = false;
        });
        _updateFireRate();
      }
    });
  }

  void _useBigExplosionPowerUp() {
    if (!_hasBigExplosionPowerUp || _gameOver) return;
    
    debugPrint('Activating Big Explosion power-up');
    
    // Start nuclear explosion animation
    setState(() {
      _showNukeEffect = true;
    });

    // Create random screen shake effect
    final random = Random();
    _screenShakeX = Tween<double>(
      begin: -10.0 + random.nextDouble() * 20,
      end: -5.0 + random.nextDouble() * 10,
    ).animate(CurvedAnimation(
      parent: _nukeAnimationController,
      curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
    ));

    _screenShakeY = Tween<double>(
      begin: -8.0 + random.nextDouble() * 16,
      end: -4.0 + random.nextDouble() * 8,
    ).animate(CurvedAnimation(
      parent: _nukeAnimationController,
      curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
    ));

    _nukeAnimationController.forward().then((_) {
      if (mounted) {
        setState(() {
          _showNukeEffect = false;
        });
        _nukeAnimationController.reset();
      }
    });
    
    // Delay the actual destruction to sync with the shockwave
    Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      // Show activation message
      setState(() {
        _powerUpMessage = 'NUCLEAR STRIKE!';
        _showPowerUpMessage = true;
      });

      _powerUpMessageController.reset();
      _powerUpMessageController.forward().then((_) {
        if (mounted) {
          setState(() {
            _showPowerUpMessage = false;
          });
        }
      });
      
      // Create massive explosion effects for each enemy
      for (final enemy in _enemies) {
        _addExplosion(enemy.x, enemy.y);
        // Add extra explosions around each enemy for more dramatic effect
        for (int i = 0; i < 3; i++) {
          _addExplosion(
            enemy.x + (Random().nextDouble() - 0.5) * 100,
            enemy.y + (Random().nextDouble() - 0.5) * 100,
          );
        }
        score += 10;
      }
      
      // Add multiple central explosions
      final size = MediaQuery.of(context).size;
      for (int i = 0; i < 8; i++) {
        _addExplosion(
          size.width / 2 + (Random().nextDouble() - 0.5) * 200,
          size.height / 2 + (Random().nextDouble() - 0.5) * 200,
        );
      }

      if (_audioInitialized) {
        _gameAudio.playExplosionSound();
      }
      
      setState(() {
        _enemies.clear();
        _hasBigExplosionPowerUp = false;
      });
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
    
      // Update projectiles
      for (int i = _projectiles.length - 1; i >= 0; i--) {
        _projectiles[i].y -= _projectiles[i].speed;
        
        if (_projectiles[i].y < -50) {
          _projectiles.removeAt(i);
        }
      }
      
      final size = MediaQuery.of(context).size;
      for (int i = _enemies.length - 1; i >= 0; i--) {
        _enemies[i].y += _enemies[i].speed;
        
        if (_enemies[i].y > size.height + 50) {
          _enemies.removeAt(i);
          _loseLife();
          continue;
        }
        
        if (_checkCollision(_player, _enemies[i])) {
          _addExplosion(_player.x, _player.y);
          
          if (_audioInitialized) {
            _gameAudio.playExplosionSound();
          }
          
          _enemies.removeAt(i);
          _loseLife();
          continue;
        }
        
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
              
              // Check for power-up unlocks
              if (widget.autoFire && !_hasRapidFirePowerUp && !_rapidFireActive) {
                // Rapid Fire appears at 50, 150, 250, 350, etc. (every 100 points after 50)
                int rapidFireInterval = 100;
                int firstRapidFire = 50;
                
                // Check if we've reached a rapid fire milestone
                bool shouldUnlockRapidFire = false;
                if (score >= firstRapidFire) {
                  // Calculate which milestone we should be at
                  int expectedMilestone = firstRapidFire;
                  while (expectedMilestone <= score) {
                    if (score >= expectedMilestone && (score - 10) < expectedMilestone) {
                      shouldUnlockRapidFire = true;
                      break;
                    }
                    expectedMilestone += rapidFireInterval;
                  }
                }
                
                if (shouldUnlockRapidFire) {
                  _hasRapidFirePowerUp = true;
                  _showPowerUpUnlockedMessage('RAPID FIRE');
                }
              }
              
              // Big Explosion appears every 200 points (200, 400, 600, etc.)
              if (!_hasBigExplosionPowerUp) {
                int bigExplosionInterval = 200;
                
                // Check if we've reached a big explosion milestone
                bool shouldUnlockBigExplosion = false;
                int expectedMilestone = bigExplosionInterval;
                while (expectedMilestone <= score) {
                  if (score >= expectedMilestone && (score - 10) < expectedMilestone) {
                    shouldUnlockBigExplosion = true;
                    break;
                  }
                  expectedMilestone += bigExplosionInterval;
                }
                
                if (shouldUnlockBigExplosion) {
                  _hasBigExplosionPowerUp = true;
                  _showPowerUpUnlockedMessage('BIG EXPLOSION');
                }
              }
            }
            break;
          }
        }
      }
      
      for (int i = _explosions.length - 1; i >= 0; i--) {
        _explosions[i].timeToLive--;
        if (_explosions[i].timeToLive <= 0) {
          _explosions.removeAt(i);
        }
      }
    });
  }
  
  bool _checkCollision(dynamic a, dynamic b) {
    // Increased hitbox multiplier for better collision detection
    double hitboxMultiplier = 1.5;
    
    double aLeft = a.x - (a.width * hitboxMultiplier) / 2;
    double aRight = a.x + (a.width * hitboxMultiplier) / 2;
    double aTop = a.y - (a.height * hitboxMultiplier) / 2;
    double aBottom = a.y + (a.height * hitboxMultiplier) / 2;
    
    double bLeft = b.x - (b.width * hitboxMultiplier) / 2;
    double bRight = b.x + (b.width * hitboxMultiplier) / 2;
    double bTop = b.y - (b.height * hitboxMultiplier) / 2;
    double bBottom = b.y + (b.height * hitboxMultiplier) / 2;
    
    return (aLeft < bRight &&
        aRight > bLeft &&
        aTop < bBottom &&
        aBottom > bTop);
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
    _rapidFireTimer?.cancel();
    
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
              const SizedBox(height: 10),
              Text(
                'Mode: ${widget.autoFire ? "AUTO FIRE" : "MANUAL FIRE"}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white60,
                ),
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
    _instructionTimer?.cancel();
    _rapidFireTimer?.cancel();
    _instructionAnimationController.dispose();
    _powerUpAnimationController.dispose();
    _powerUpMessageController.dispose();
    _nukeAnimationController.dispose();
    _gameAudio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
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
        child: Stack(
          children: [
            // Main game area with gesture detection and screen shake effect
            AnimatedBuilder(
              animation: _nukeAnimationController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_screenShakeX.value, _screenShakeY.value),
                  child: SizedBox.expand(
                    child: GestureDetector(
                      onHorizontalDragStart: (details) {
                        _isDragging = true;
                      },
                      onHorizontalDragUpdate: (details) {
                        setState(() {
                          final screenWidth = MediaQuery.of(context).size.width;
                          _playerX += details.delta.dx / screenWidth;
                          _playerX = _playerX.clamp(0.05, 0.95);
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        _isDragging = false;
                      },
                      onTapDown: _onScreenTap,
                      child: Container(
                        color: Colors.transparent,
                        child: Stack(
                          children: [
                            // Game objects
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
                      ),
                    ),
                  ),
                );
              },
            ),

          // Nuclear explosion effect
          if (_showNukeEffect)
            AnimatedBuilder(
              animation: _nukeAnimationController,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Bright flash effect
                    if (_nukeFlashOpacity.value > 0)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(_nukeFlashOpacity.value * 0.9),
                        ),
                      ),
                    
                    // Shockwave effect
                    if (_nukeShockwaveRadius.value > 0)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: NukeShockwavePainter(
                            radius: _nukeShockwaveRadius.value,
                            opacity: _nukeShockwaveOpacity.value,
                            centerX: MediaQuery.of(context).size.width / 2,
                            centerY: MediaQuery.of(context).size.height / 2,
                          ),
                          size: Size.infinite,
                        ),
                      ),
                  ],
                );
              },
            ),
          
          // Score display
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SCORE: $score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.autoFire ? 'AUTO FIRE' : 'MANUAL FIRE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: widget.autoFire ? Colors.cyanAccent : Colors.orangeAccent,
                  ),
                ),
                if (_rapidFireActive)
                  Text(
                    'RAPID FIRE!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.yellowAccent,
                      shadows: [
                        Shadow(
                          color: Colors.yellowAccent.withOpacity(0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
              ],
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
          
          // Power-up buttons for auto-fire mode
          if (widget.autoFire && (_hasRapidFirePowerUp || _hasBigExplosionPowerUp))
            Positioned(
              top: 100,
              right: 20,
              child: Column(
                children: [
                  if (_hasRapidFirePowerUp)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            debugPrint('Rapid Fire button tapped');
                            _useRapidFirePowerUp();
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedBuilder(
                            animation: _powerUpPulse,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _powerUpPulse.value,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.yellowAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.yellowAccent, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.yellowAccent.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.flash_on,
                                    color: Colors.yellowAccent,
                                    size: 30,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  if (_hasBigExplosionPowerUp)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          debugPrint('Big Explosion button tapped');
                          _useBigExplosionPowerUp();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedBuilder(
                          animation: _powerUpPulse,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _powerUpPulse.value,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.redAccent, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.redAccent,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Big explosion button for manual mode (only big explosion)
          if (!widget.autoFire && _hasBigExplosionPowerUp)
            Positioned(
              top: 100,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    debugPrint('Big Explosion button tapped (manual mode)');
                    _useBigExplosionPowerUp();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedBuilder(
                    animation: _powerUpPulse,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _powerUpPulse.value,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.redAccent, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.redAccent,
                            size: 30,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          
          // Power-up unlocked message (centered)
          if (_showPowerUpMessage)
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _powerUpMessageController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _powerUpMessageScale.value,
                      child: Opacity(
                        opacity: _powerUpMessageOpacity.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber.withOpacity(0.9),
                                Colors.orange.withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.amber,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Text(
                            _powerUpMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 5,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          // Manual fire instruction with animation
          if (!widget.autoFire && _showInstruction)
            Positioned.fill(
              child: Center(
                child: AnimatedBuilder(
                  animation: _instructionOpacity,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _instructionOpacity.value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orangeAccent.withOpacity(0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orangeAccent.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TAP TO SHOOT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.orangeAccent,
                                shadows: [
                                  Shadow(
                                    color: Colors.orangeAccent.withOpacity(0.8),
                                    blurRadius: 15,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'DRAG TO MOVE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyanAccent,
                                shadows: [
                                  Shadow(
                                    color: Colors.cyanAccent.withOpacity(0.8),
                                    blurRadius: 15,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Icon(
                              Icons.touch_app,
                              color: Colors.orangeAccent,
                              size: 48,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
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

class NukeShockwavePainter extends CustomPainter {
  final double radius;
  final double opacity;
  final double centerX;
  final double centerY;
  
  NukeShockwavePainter({
    required this.radius,
    required this.opacity,
    required this.centerX,
    required this.centerY,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (radius <= 0 || opacity <= 0) return;
    
    final center = Offset(centerX, centerY);
    
    // Draw multiple shockwave rings for more dramatic effect
    for (int i = 0; i < 3; i++) {
      final ringRadius = radius - (i * 50);
      if (ringRadius <= 0) continue;
      
      final ringOpacity = opacity * (1.0 - i * 0.3);
      if (ringOpacity <= 0) continue;
      
      // Outer ring (orange/red)
      final outerPaint = Paint()
        ..color = (i == 0 ? Colors.orange : Colors.red).withOpacity(ringOpacity * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 15.0 - (i * 3);
      
      canvas.drawCircle(center, ringRadius, outerPaint);
      
      // Inner ring (bright yellow/white)
      final innerPaint = Paint()
        ..color = (i == 0 ? Colors.yellow : Colors.orange).withOpacity(ringOpacity * 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0 - (i * 2);
      
      canvas.drawCircle(center, ringRadius - 5, innerPaint);
    }
    
    // Central bright core
    final corePaint = Paint()
      ..color = Colors.white.withOpacity(opacity * 0.9)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    
    canvas.drawCircle(center, 30, corePaint);
    
    // Fireball effect
    final fireballPaint = Paint()
      ..color = Colors.orange.withOpacity(opacity * 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    
    canvas.drawCircle(center, radius * 0.1, fireballPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EnemyPainter extends CustomPainter {
  final Enemy enemy;
  
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