import 'package:flutter/material.dart';

class AnimatedHomePage extends StatefulWidget {
  @override
  _AnimatedHomePageState createState() => _AnimatedHomePageState();
}

class _AnimatedHomePageState extends State<AnimatedHomePage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pixel art background
          Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
          // Overlay with content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _animation,
                  child: Text(
                    'RETRO DASH',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 36,
                      color: Colors.cyanAccent,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          blurRadius: 6.0,
                          color: Colors.blueAccent,
                          offset: Offset(0, 0),
                        ),
                        Shadow(
                          blurRadius: 16.0,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 40),
                // Pixel art style button
                GestureDetector(
                  onTap: () {
                    // Navigate to game screen
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                    decoration: BoxDecoration(
                      color: Colors.pinkAccent,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black87,
                          offset: Offset(6, 6),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Text(
                      'START GAME',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 20,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
