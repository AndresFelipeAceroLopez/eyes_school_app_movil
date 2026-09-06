import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class NavItem {
  const NavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Shared bottom navigation bar. When [elevatedIndex] is set, that item is
/// rendered as a raised circular gradient button (used for the QR tab on the
/// Teacher and Admin shells).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.elevatedIndex,
  });

  final List<NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int? elevatedIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        height: 78,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(color: AppColors.cardShadow, blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(items.length, (index) {
            final isElevated = elevatedIndex == index;
            if (isElevated) {
              return _ElevatedItem(
                item: items[index],
                onTap: () => onTap(index),
              );
            }
            return _NavTab(
              item: items[index],
              selected: currentIndex == index,
              onTap: () => onTap(index),
            );
          }),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({required this.item, required this.selected, required this.onTap});

  final NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.indigo : AppColors.textSecondary;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: 24),
              const SizedBox(height: 3),
              // One line, always: five tabs on a narrow phone (or a user with
              // large text) would otherwise wrap and overflow the bar.
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ElevatedItem extends StatelessWidget {
  const _ElevatedItem({required this.item, required this.onTap});

  final NavItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, -14),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: AppColors.primaryGradient),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Color(0x555B34D6), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: Icon(item.icon, color: Colors.white, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
