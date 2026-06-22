// lib/widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/app_provider.dart';

class HomeProtectorBottomNav extends StatelessWidget {
  const HomeProtectorBottomNav({super.key});

  static const List<_NavItem> _items = [
    _NavItem(
      icon: Icons.home_rounded,
      label: '홈',
      emoji: '🏠',
      isActive: true,
    ),
    _NavItem(
      icon: Icons.map_rounded,
      label: '지도',
      emoji: '🗺️',
      isActive: true,
    ),
    _NavItem(
      icon: Icons.notifications_active_rounded,
      label: '알림',
      emoji: '🚨',
      isActive: true,
    ),
    _NavItem(
      icon: Icons.calendar_month_rounded,
      label: '캘린더',
      emoji: '📅',
      isActive: true,
    ),
    _NavItem(
      icon: Icons.shield_rounded,
      label: '대비계획',
      emoji: '🛡️',
      isActive: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final activeTab = provider.activeTab;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isSelected = activeTab == i;
              return Expanded(
                child: _NavTabItem(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => context.read<AppProvider>().setActiveTab(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String emoji;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.emoji,
    required this.isActive,
  });
}

class _NavTabItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavTabItem> createState() => _NavTabItemState();
}

class _NavTabItemState extends State<_NavTabItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    if (widget.isSelected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NavTabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _ctrl.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.item.isActive;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with indicator
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.item.icon,
                    size: 22,
                    color: isSelected
                        ? AppColors.accent
                        : isEnabled
                            ? AppColors.textMuted
                            : AppColors.border,
                  ),
                ),

                // "준비 중" badge for inactive tabs
                if (!isEnabled)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: AppColors.borderLight, width: 1),
                      ),
                      child: Text(
                        'Soon',
                        style: GoogleFonts.outfit(
                          fontSize: 7,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 2),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: GoogleFonts.notoSans(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppColors.accent
                    : isEnabled
                        ? AppColors.textMuted
                        : AppColors.border,
              ),
              child: Text(widget.item.label),
            ),

            // Active underline dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(top: 3),
              width: isSelected ? 16 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
