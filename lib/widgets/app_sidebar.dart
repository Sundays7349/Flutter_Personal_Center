import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppSidebarItem {
  final String path;
  final String label;
  final Widget icon;

  const AppSidebarItem({
    required this.path,
    required this.label,
    required this.icon,
  });
}

class AppSidebar extends StatelessWidget {
  final List<AppSidebarItem> items;
  final String selectedPath;
  final ValueChanged<String> onTap;
  final bool collapsed;
  final Widget? header;
  final double width;
  final double collapsedWidth;

  const AppSidebar({
    super.key,
    required this.items,
    required this.selectedPath,
    required this.onTap,
    this.collapsed = false,
    this.header,
    this.width = 220,
    this.collapsedWidth = 60,
  });

  @override
  Widget build(BuildContext context) {
    final currentWidth = collapsed ? collapsedWidth : width;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: currentWidth,
      constraints: BoxConstraints(minWidth: currentWidth, maxWidth: currentWidth),
      decoration: const BoxDecoration(
        color: AppColors.sidebar,
        border: Border(right: BorderSide(color: AppColors.sidebarBorder)),
      ),
      child: Column(
        children: [
          header ?? const SizedBox.shrink(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final item = items[index];
                final isActive = item.path == selectedPath;
                return _buildNavItem(item, isActive);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(AppSidebarItem item, bool isActive) {
    return Tooltip(
      message: collapsed ? item.label : '',
      child: InkWell(
        onTap: () => onTap(item.path),
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.sidebarAccent.withValues(alpha: 0.5),
        splashColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: collapsed ? 0 : 12,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive ? AppColors.sidebarAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Center(child: item.icon),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.sidebarAccentForeground
                          : AppColors.sidebarForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppSidebarHeader extends StatelessWidget {
  final Widget avatar;
  final String title;
  final String subtitle;
  final bool collapsed;

  const AppSidebarHeader({
    super.key,
    required this.avatar,
    required this.title,
    required this.subtitle,
    this.collapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(collapsed ? 8 : 12, 12, 8, 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.sidebarBorder)),
      ),
      child: collapsed
          ? avatar
          : Row(
              children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.sidebarForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedForeground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
