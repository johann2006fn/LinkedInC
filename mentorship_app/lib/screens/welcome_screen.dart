import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/gradient_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AntigravityTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                
                // Glowing 3D Glassmorphic Logo Placeholder
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AntigravityTheme.electricPurple.withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: GlassContainer(
                      width: 120,
                      height: 120,
                      borderRadius: 60,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AntigravityTheme.softBlue.withOpacity(0.8),
                                width: 3,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Positioned(
                            left: 20,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: AntigravityTheme.electricPurple.withOpacity(0.8),
                                  width: 3,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 64),
                
                // Text 'MentorHub'
                Text(
                  'MentorHub',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    letterSpacing: 2.0,
                  ),
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
