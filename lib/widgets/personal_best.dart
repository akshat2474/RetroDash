// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'animated_background.dart'; // Import the AnimatedBackground widget

class PersonalBestPage extends StatelessWidget {
  final List<ScoreEntry> topScores = [
    ScoreEntry(name: "Akshat", score: 9850, date: "2025-05-15"),
    ScoreEntry(name: "Ritika", score: 8720, date: "2025-05-10"),
    ScoreEntry(name: "Abhay", score: 7645, date: "2025-05-18"),
    ScoreEntry(name: "Amaan", score: 6980, date: "2025-05-01"),
    ScoreEntry(name: "Anant", score: 6540, date: "2025-04-28"),
    ScoreEntry(name: "Divyansh", score: 5890, date: "2025-04-25"),
    ScoreEntry(name: "Amogh", score: 5430, date: "2025-05-12"),
    ScoreEntry(name: "Aadyanh", score: 4950, date: "2025-05-05"),
    ScoreEntry(name: "Adamya", score: 4320, date: "2025-04-30"),
    ScoreEntry(name: "Abhoydya", score: 3760, date: "2025-04-22"),
  ];

  PersonalBestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      backgroundColor: const Color(0xFF0A0E17),
      particleCount: 40,
      showGrid: true,
      showParticles: true,
      gridColor: const Color(0x2600FFFF),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Title with space theme
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Colors.cyanAccent, Colors.purpleAccent],
              ).createShader(bounds),
              child: const Text(
                "SPACE BLASTERS",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "PERSONAL BEST",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.amberAccent,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 30),
            // Score table
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.cyanAccent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(13),
                          topRight: Radius.circular(13),
                        ),
                      ),
                      child: const Row(
                        children: [
                          SizedBox(width: 20),
                          Expanded(
                            flex: 1,
                            child: Text(
                              "RANK",
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "PILOT",
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "SCORE",
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "DATE",
                              style: TextStyle(
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                    ),
                    // Score entries
                    Expanded(
                      child: ListView.builder(
                        itemCount: topScores.length,
                        itemBuilder: (context, index) {
                          return ScoreEntryWidget(
                            rank: index + 1,
                            entry: topScores[index],
                            isEven: index % 2 == 0,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purpleAccent.withOpacity(0.7),
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "BACK TO GAME",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// Model class for score entries
class ScoreEntry {
  final String name;
  final int score;
  final String date;

  ScoreEntry({required this.name, required this.score, required this.date});
}

class ScoreEntryWidget extends StatelessWidget {
  final int rank;
  final ScoreEntry entry;
  final bool isEven;

  const ScoreEntryWidget({super.key, 
    required this.rank,
    required this.entry,
    required this.isEven,
  });

  @override
  Widget build(BuildContext context) {
    // Determine row color based on rank
    Color rowColor;
    Color textColor;
    
    if (rank == 1) {
      rowColor = Colors.amber.withOpacity(0.3);
      textColor = Colors.white;
    } else if (rank == 2) {
      rowColor = Colors.grey.shade300.withOpacity(0.2);
      textColor = Colors.white;
    } else if (rank == 3) {
      rowColor = Colors.brown.shade300.withOpacity(0.2);
      textColor = Colors.white;
    } else {
      rowColor = isEven ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.2);
      textColor = Colors.white.withOpacity(0.8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: rowColor,
        border: Border(
          bottom: BorderSide(
            color: Colors.cyanAccent.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Text(
              "$rank",
              style: TextStyle(
                color: rank <= 3 ? Colors.amberAccent : textColor,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.name,
              style: TextStyle(
                color: textColor,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.score.toString(),
              style: TextStyle(
                color: textColor,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              entry.date,
              style: TextStyle(
                color: textColor,
                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
