# Space Blaster

A fast-paced space shooter game built with Flutter where you defend against waves of enemy ships.

## 🚀 Features

- **Dynamic Space Combat**: Control your ship to avoid enemies and blast them with your lasers
- **Immersive Space Environment**: Animated starfield background with parallax effect
- **Progressive Difficulty**: Enemies become more challenging as your score increases
- **Sound Effects**: Laser blasts and explosion sounds for a complete arcade experience
- **Responsive Controls**: Smooth touch-based ship controls

## 🛠️ Installation

1. Make sure you have Flutter installed on your machine. For installation instructions, view the [official documentation](https://flutter.dev/docs/get-started/install).

2. Clone this repository:
   ```
   git clone https://github.com/akshat2474/RetroDash.git
   ```

3. Navigate to the project directory:
   ```
   cd RetroDash
   ```

4. Install dependencies:
   ```
   flutter pub get
   ```

5. Run the app:
   ```
   flutter run
   ```

## 🎮 How to Play

1. **Start**: Tap the "START GAME" button on the title screen
2. **Controls**: Drag your finger horizontally to move your ship left and right
3. **Objective**: Destroy enemy ships and avoid collisions
4. **Scoring**: Each destroyed enemy ship adds 10 points to your score

## ⚙️ Requirements

- Flutter 3.0.0 or higher
- Dart 3.0.0 or higher
- Android 5.0+ or iOS 11.0+


## 🔧 Troubleshooting

### Sound Not Working?

If you encounter audio initialization issues:

1. Make sure you have the correct folder structure:
   ```
   assets/
   └── audio/
       ├── laser_blast.mp3
       ├── explosion.mp3
       └── space_theme.mp3
   ```

2. Verify your `pubspec.yaml` correctly includes the assets:
   ```yaml
   flutter:
     assets:
       - assets/audio/
   ```

3. Run `flutter clean` and then `flutter pub get` to refresh dependencies

## 🔍 Future Improvements

- [ ] Add power-ups and special weapons
- [ ] Implement different enemy types
- [ ] Add boss battles after specific score milestones
- [ ] Create a local leaderboard system
- [ ] Add difficulty settings

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgements

- Inspired by classic arcade space shooters
- Sound effects from [freesound.org](https://freesound.org/)

---

Developed with ❤️ using Flutter