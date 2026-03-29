import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomBottomBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabTap;
  final List<CustomBottomBarItem> items;
  final VoidCallback onAddHabitTap;
  final VoidCallback onAnalyticsTap;

  const CustomBottomBar({
    super.key,
    required this.selectedIndex,
    required this.onTabTap,
    required this.items,
    required this.onAddHabitTap,
    required this.onAnalyticsTap,
  });

  @override
  State<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar>
    with SingleTickerProviderStateMixin {
  bool _isMenuOpen = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _closeMenu();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _closeMenu();
    } else {
      _openMenu();
    }
  }

  void _openMenu() {
    setState(() => _isMenuOpen = true);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return _MenuOverlay(
          fadeAnim: _fadeAnim,
          scaleAnim: _scaleAnim,
          onDismiss: _closeMenu,
          onAddHabit: () {
            _closeMenu();
            widget.onAddHabitTap();
          },
          onAnalytics: () {
            _closeMenu();
            widget.onAnalyticsTap();
          },
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward();
  }

  void _closeMenu() {
    if (!_isMenuOpen) return;
    _animController.reverse().then((_) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
    setState(() => _isMenuOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          padding: EdgeInsets.only(bottom: bottomPadding + 12, top: 8),
          decoration: BoxDecoration(
            color: theme.cardColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ...widget.items.sublist(0, (widget.items.length / 2).ceil()).map(
                    (item) => _buildTabItem(item, theme),
                  ),
              const SizedBox(width: 72),
              ...widget.items.sublist((widget.items.length / 2).ceil()).map(
                    (item) => _buildTabItem(item, theme),
                  ),
            ],
          ),
        ),
        Positioned(
          top: -22,
          child: GestureDetector(
            onTap: _toggleMenu,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  width: 4,
                ),
              ),
              child: AnimatedRotation(
                turns: _isMenuOpen ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                child:
                    const Icon(LucideIcons.plus, color: Colors.white, size: 28),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabItem(CustomBottomBarItem item, ThemeData theme) {
    final isSelected = widget.selectedIndex == item.index;
    return GestureDetector(
      onTap: () => widget.onTabTap(item.index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 22,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 4 : 0,
              height: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  final Animation<double> fadeAnim;
  final Animation<double> scaleAnim;
  final VoidCallback onDismiss;
  final VoidCallback onAddHabit;
  final VoidCallback onAnalytics;

  const _MenuOverlay({
    required this.fadeAnim,
    required this.scaleAnim,
    required this.onDismiss,
    required this.onAddHabit,
    required this.onAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        GestureDetector(
          onTap: onDismiss,
          child: FadeTransition(
            opacity: fadeAnim,
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        Positioned(
          bottom: bottomPadding + 102,
          left: (screenWidth - 56) / 2,
          child: ScaleTransition(
            scale: scaleAnim,
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: onAddHabit,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child:
                          Icon(LucideIcons.plus, color: Colors.white, size: 22),
                    ),
                  ),
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  GestureDetector(
                    onTap: onAnalytics,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Icon(LucideIcons.barChart2,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class CustomBottomBarItem {
  final int index;
  final IconData icon;
  final String label;

  const CustomBottomBarItem({
    required this.index,
    required this.icon,
    required this.label,
  });
}
