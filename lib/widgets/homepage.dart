import 'package:flutter/material.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // Helper function to launch URLs
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pixel art background (uncomment and set your asset if you have one)
          // Image.asset('assets/images/background.png', fit: BoxFit.cover),
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
          // Footer with "Made by" and social icons
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  'Made by Akshat Singh',
                  style: TextStyle(
                    fontFamily: 'PixelFont',
                    fontSize: 14,
                    color: Colors.white70,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 2.0,
                        color: Colors.black,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(SimpleIcons.github, color: Colors.white, size: 28),
                      tooltip: 'GitHub',
                      onPressed: () => _launchUrl('https://github.com/akshat2474'),
                    ),
                    SizedBox(width: 16),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
