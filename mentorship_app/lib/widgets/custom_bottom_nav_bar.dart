import 'package:flutter/material.dart';
import '../theme/antigravity_theme.dart';

/// Role-aware floating pill bottom nav bar.
/// Pass [isMentor] = true for the Mentor tab set, false for Mentee.
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool isMentor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.isMentor = false,
  });

  @override
  Widget build(BuildContext context) {
    // ── Tab definitions ────────────────────────────────────
    final menteeItems = [
      _NavItem(Icons.explore_rounded, Icons.explore_outlined, 'Explore'),
      _NavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
      _NavItem(Icons.people_rounded, Icons.people_outline_rounded, 'Network'),
      _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];
    final mentorItems = [
      _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard'),
      _NavItem(Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chat'),
      _NavItem(Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar'),
      _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
    ];
    final items = isMentor ? mentorItems : menteeItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1527).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AntigravityTheme.electricPurple.withValues(alpha: 0.08),
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (i) {
            final selected = currentIndex == i;
            final item = items[i];
            return _buildTab(
              icon: selected ? item.activeIcon : item.inactiveIcon,
              label: item.label,
              isSelected: selected,
              onTap: () => onTap(i),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AntigravityTheme.electricPurple.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? AntigravityTheme.electricPurple
                  : Colors.white38,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? AntigravityTheme.electricPurple
                    : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  const _NavItem(this.activeIcon, this.inactiveIcon, this.label);
}
