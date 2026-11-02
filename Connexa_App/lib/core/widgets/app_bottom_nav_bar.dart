import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:connexa/core/theme/theme.dart';
import 'package:connexa/core/widgets/app_button.dart';
import 'package:connexa/features/auth/providers/auth_provider.dart';

/// Shows the confirmation dialog before revoking member session and logging out.
Future<void> showLogoutConfirmationDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final bool? confirm = await showDialog<bool>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text(
          'Are you sure you want to end your active session? Your session tokens will be securely revoked.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          AppButton.primary(
            text: 'Log Out',
            height: 38,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) {
      context.go('/login');
    }
  }
}

/// Fixed 5-destination bottom navigation bar for Connexa mobile destinations:
/// 0: Dashboard, 1: Directory, 2: Products (Center button), 3: Network, 4: Profile.
class AppBottomNavBar extends ConsumerWidget {
  const AppBottomNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  void _onItemTapped(BuildContext context, WidgetRef ref, int index) {
    if (index == currentIndex) return;

    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/directory');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/network');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: const Border(
          top: BorderSide(color: AppColors.border, width: 1.0),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              _buildNavItem(
                context,
                ref,
                index: 0,
                key: const Key('bottomNavDashboard'),
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard_rounded,
                label: 'Dashboard',
              ),
              _buildNavItem(
                context,
                ref,
                index: 1,
                key: const Key('bottomNavDirectory'),
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Directory',
              ),
              _buildNavItem(
                context,
                ref,
                index: 2,
                key: const Key('bottomNavProducts'),
                icon: Icons.inventory_2_outlined,
                activeIcon: Icons.inventory_2_rounded,
                label: 'Products',
              ),
              _buildNavItem(
                context,
                ref,
                index: 3,
                key: const Key('bottomNavNetwork'),
                icon: Icons.people_outline,
                activeIcon: Icons.people_rounded,
                label: 'Network',
              ),
              _buildNavItem(
                context,
                ref,
                index: 4,
                key: const Key('bottomNavProfile'),
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required Key key,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final bool isSelected = currentIndex == index;
    final Color selectedColor = AppColors.primary;
    final Color unselectedColor = AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        key: key,
        onTap: () => _onItemTapped(context, ref, index),
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? selectedColor : unselectedColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
