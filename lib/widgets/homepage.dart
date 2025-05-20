import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimatedHomePage extends StatefulWidget {
  @override
  _AnimatedHomePageState createState() => _AnimatedHomePageState();
}

class _AnimatedHomePageState extends State<AnimatedHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open $url')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF181D27),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/b7.png', fit: BoxFit.cover),
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
                      border: Border.all(color: Colors.white, width: 4),
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
          // Inside the Positioned widget for footer
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Made by Akshat Singh',
                    style: TextStyle(
                      fontFamily: 'PixelFont',
                      fontSize: 14,
                      color:
                          Colors
                              .cyanAccent, // Changed to cyan for better visibility
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          blurRadius: 4.0,
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
                        icon: FaIcon(
                          FontAwesomeIcons.github,
                          color: Colors.white,
                          size: 28,
                        ),
                        onPressed:
                            () => _launchUrl('https://github.com/akshat2474'),
                      ),
                      SizedBox(width: 16),
                      IconButton(
                        icon: FaIcon(
                          FontAwesomeIcons.linkedin,
                          color: Colors.cyanAccent,
                          size: 28,
                        ),
                        onPressed:
                            () => _launchUrl(
                              'https://www.linkedin.com/in/akshat-singh-48a03b312/',
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
