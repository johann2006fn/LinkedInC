import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/antigravity_theme.dart';

class MentorRadarVisual extends StatefulWidget {
  final int matchCount;
  
  const MentorRadarVisual({
    super.key,
    required this.matchCount,
  });

  @override
  State<MentorRadarVisual> createState() => _MentorRadarVisualState();
}

class _MentorRadarVisualState extends State<MentorRadarVisual> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
       vsync: this,
       duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: AntigravityTheme.midnightBlue,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric circles
          _buildConcentricCircle(240),
          _buildConcentricCircle(170),
          _buildConcentricCircle(100),
          
          // Center Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'YOUR RADAR',
                style: TextStyle(
                  color: AntigravityTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.matchCount}',
                style: const TextStyle(
                  color: AntigravityTheme.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  height: 1.1,
                ),
              ),
              const Text(
                'Waiting Mentees',
                style: TextStyle(
                  color: AntigravityTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          // Orbiting Avatars
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                   _buildOrbitingAvatar(0, 0.2, 120, 'assets/avatar1.png'),
                   _buildOrbitingAvatar(1, 0.5, 85, 'assets/avatar2.png'),
                   _buildOrbitingAvatar(2, 0.8, 120, 'assets/avatar3.png'),
                   _buildOrbitingAvatar(3, 0.05, 120, 'assets/avatar4.png'),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConcentricCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AntigravityTheme.electricPurple.withOpacity(0.15),
          width: 1,
        ),
      ),
    );
  }

  Widget _buildOrbitingAvatar(int index, double startingAnglePhase, double radius, String assetPath) {
    // Generate an angle that changes over time based on the controller
    final double angle = (startingAnglePhase * 2 * pi) + (_controller.value * 2 * pi * (index % 2 == 0 ? 1 : -1));
    
    // Offset from center
    final double x = radius * cos(angle);
    final double y = radius * sin(angle);

    return Align(
      alignment: Alignment.center,
      child: Transform.translate(
        offset: Offset(x, y),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AntigravityTheme.midnightBlue,
            border: Border.all(color: AntigravityTheme.electricPurple.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: AntigravityTheme.electricPurple.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              )
            ],
          ),
          child: const Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
