import 'dart:ui';
import 'package:flutter/material.dart';

class NavItemData {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final List<Color> gradientColors;

  const NavItemData({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.gradientColors,
  });
}

class CustomFloatingBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final List<NavItemData> items;

  const CustomFloatingBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final scale = (w / 360).clamp(0.72, 1.0);

        return SizedBox(
          height: 76 * scale,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              margin: EdgeInsets.fromLTRB(12, 0, 12, 10 * scale),
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.16),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: items.asMap().entries.map((entry) {
                    final int index = entry.key;
                    final NavItemData item = entry.value;
                    final bool isSelected = selectedIndex == index;

                    return GestureDetector(
                      onTap: () => onItemSelected(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? (12 * scale).clamp(8.0, 14.0) : (10 * scale).clamp(6.0, 12.0),
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: item.gradientColors,
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: item.gradientColors[1].withValues(alpha: 0.4),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSelected ? item.selectedIcon : item.icon,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                                size: isSelected ? 21 * scale : 22 * scale,
                              ),
                              if (isSelected) ...[
                                SizedBox(width: 5 * scale),
                                Text(
                                  item.label,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5 * scale,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
