import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'homepage.dart';
import 'animated_background.dart'; // Import the AnimatedBackground widget

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Image picker
  final ImagePicker _picker = ImagePicker();
  File? _profileImage;
  String? _savedImagePath;

  // Animations
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  // Game stats
  double _gameHours = 42.5; // Example value, replace with actual data
  int _gamesPlayed = 34;
  int _gamesWon = 28;

  // Form validation
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  bool _isSaving = false;

  // SharedPreferences keys
  static const String _nameKey = 'profile_name';
  static const String _usernameKey = 'profile_username';
  static const String _imagePathKey = 'profile_image_path';
  static const String _gameHoursKey = 'game_hours';
  static const String _gamesPlayedKey = 'games_played';
  static const String _gamesWonKey = 'games_won';

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Load saved profile data
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        // Load text fields
        _nameController.text = prefs.getString(_nameKey) ?? "Pixel Warrior";
        _usernameController.text =
            prefs.getString(_usernameKey) ?? "pixel_dash_master";

        // Load profile image path
        _savedImagePath = prefs.getString(_imagePathKey);
        if (_savedImagePath != null) {
          final file = File(_savedImagePath!);
          if (file.existsSync()) {
            _profileImage = file;
          }
        }

        // Load game stats
        _gameHours = prefs.getDouble(_gameHoursKey) ?? 42.5;
        _gamesPlayed = prefs.getInt(_gamesPlayedKey) ?? 34;
        _gamesWon = prefs.getInt(_gamesWonKey) ?? 28;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile data: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
          _isEditing = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _saveProfileImage() async {
    if (_profileImage == null) return _savedImagePath;

    try {
      // Get the app's document directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = path.join(appDir.path, fileName);

      // Copy the image to app documents directory for persistence
      final File newImage = await _profileImage!.copy(savedImagePath);

      // Delete the old image if it exists and it's not the same as the new one
      if (_savedImagePath != null && _savedImagePath != savedImagePath) {
        final oldFile = File(_savedImagePath!);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      }

      return savedImagePath;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile image: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Save profile image
        final imagePath = await _saveProfileImage();

        // Get SharedPreferences instance
        final prefs = await SharedPreferences.getInstance();

        // Save profile data
        await prefs.setString(_nameKey, _nameController.text);
        await prefs.setString(_usernameKey, _usernameController.text);

        if (imagePath != null) {
          await prefs.setString(_imagePathKey, imagePath);
          _savedImagePath = imagePath;
        }

        // Save game stats (in a real app, these would be updated elsewhere)
        await prefs.setDouble(_gameHoursKey, _gameHours);
        await prefs.setInt(_gamesPlayedKey, _gamesPlayed);
        await prefs.setInt(_gamesWonKey, _gamesWon);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.greenAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      backgroundColor: const Color(0xFF0A0E17),
      particleColors: const [
        Colors.cyanAccent,
        Colors.pinkAccent,
        Colors.purpleAccent,
        Colors.blueAccent,
      ],
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 30),
                _buildProfileImage(),
                const SizedBox(height: 30),
                _buildProfileForm(),
                const SizedBox(height: 30),
                _buildGameStats(),
                const SizedBox(height: 40),
                _buildSaveButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.cyanAccent.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.cyanAccent,
              size: 22,
            ),
          ),
        ),

        // Title
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Colors.cyanAccent, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: const Text(
            'PROFILE',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
              shadows: [
                Shadow(
                  blurRadius: 15.0,
                  color: Colors.black,
                  offset: Offset(2, 2),
                ),
              ],
            ),
          ),
        ),

        // Settings button
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnimatedHomePage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.pinkAccent.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pinkAccent.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.home,
              color: Colors.pinkAccent,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                  border: Border.all(
                    color:
                        _isEditing
                            ? Colors.greenAccent.withOpacity(0.8)
                            : Colors.cyanAccent.withOpacity(0.8),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          _isEditing
                              ? Colors.greenAccent.withOpacity(0.4)
                              : Colors.cyanAccent.withOpacity(0.4),
                      blurRadius: 15 * _pulseAnimation.value,
                      spreadRadius: 2 * _pulseAnimation.value,
                    ),
                  ],
                ),
                child: ClipOval(
                  child:
                      _profileImage != null
                          ? Image.file(_profileImage!, fit: BoxFit.cover)
                          : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'TAP TO\nUPLOAD',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'PixelFont',
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
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
    );
  }

  Widget _buildProfileForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Name field
          _buildTextField(
            label: 'NAME',
            controller: _nameController,
            icon: Icons.person,
            color: Colors.cyanAccent,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          // Username field
          _buildTextField(
            label: 'USERNAME',
            controller: _usernameController,
            icon: Icons.alternate_email,
            color: Colors.pinkAccent,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.contains(' ')) {
                return 'Username cannot contain spaces';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required Color color,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: const TextStyle(
          fontFamily: 'PixelFont',
          color: Colors.white,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontFamily: 'PixelFont',
            color: color.withOpacity(0.7),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: color),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          errorStyle: const TextStyle(
            fontFamily: 'PixelFont',
            color: Colors.redAccent,
            fontSize: 12,
          ),
        ),
        onChanged: (value) {
          setState(() {
            _isEditing = true;
          });
        },
      ),
    );
  }

  Widget _buildGameStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.2),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'GAME STATISTICS',
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 18,
              color: Colors.purpleAccent,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 20),

          // Total hours
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.amberAccent.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amberAccent.withOpacity(0.3),
                      blurRadius: 8 * _pulseAnimation.value,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timer,
                          color: Colors.amberAccent,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'TOTAL HOURS:',
                          style: TextStyle(
                            fontFamily: 'PixelFont',
                            fontSize: 12,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_gameHours.toString()} HRS',
                      style: const TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amberAccent,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Additional stats
          Row(
            children: [
              Expanded(
                child: _buildStatBlock(
                  label: 'GAMES',
                  value: _gamesPlayed.toString(),
                  icon: Icons.games,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatBlock(
                  label: 'WINS',
                  value: _gamesWon.toString(),
                  icon: Icons.emoji_events,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatBlock({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 12,
              color: color.withOpacity(0.8),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'PixelFont',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedOpacity(
      opacity: _isEditing ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 300),
      child: GestureDetector(
        onTap: _isEditing ? _saveProfile : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color:
                _isEditing
                    ? Colors.deepPurpleAccent
                    : Colors.deepPurple.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color:
                    _isEditing
                        ? Colors.deepPurpleAccent.withOpacity(0.5)
                        : Colors.transparent,
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child:
                _isSaving
                    ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                    : const Text(
                      'SAVE PROFILE',
                      style: TextStyle(
                        fontFamily: 'PixelFont',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            blurRadius: 4.0,
                            color: Colors.black,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}