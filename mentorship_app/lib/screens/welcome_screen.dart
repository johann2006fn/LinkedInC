import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/gradient_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AntigravityTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32.0,
              vertical: 48.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Official MentorHub Logo
                Center(
                  child: Hero(
                    tag: 'app_logo',
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AntigravityTheme.electricPurple,
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: [
                          BoxShadow(
                            color: AntigravityTheme.electricPurple.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 64),

                // Text 'MentorHub'
                Text(
                  'MentorHub',
                  style: Theme.of(
                    context,
                  ).textTheme.displayLarge?.copyWith(letterSpacing: 2.0),
                ),

                const SizedBox(height: 16),

                // Subheadline
                Text(
                  'Meaningful mentorship,\nalgorithmically matched.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AntigravityTheme.textSecondary,
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Glowing Gradient Button
                GradientButton(
                  text: 'Access Your Campus →',
                  onPressed: () => context.go('/auth'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
