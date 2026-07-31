import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppTabs extends StatefulWidget {
  final List<TabItem> tabs;
  final Widget Function(int index) contentBuilder;
  final int initialIndex;

  const AppTabs({
    super.key,
    required this.tabs,
    required this.contentBuilder,
    this.initialIndex = 0,
  });

  @override
  State<AppTabs> createState() => _AppTabsState();
}

class _AppTabsState extends State<AppTabs> with SingleTickerProviderStateMixin {
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(
      length: widget.tabs.length,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TabBar(
            controller: _controller,
            isScrollable: false,
            tabAlignment: TabAlignment.fill,
            labelColor: AppColors.foreground,
            unselectedLabelColor: AppColors.mutedForeground,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            tabs: widget.tabs.map((tab) => Tab(child: tab.child)).toList(),
          ),
        ),
        const SizedBox(height: 16),
        // 不限制内容高度：Tab 内容高度由内容自适应（列表可无限延伸，
        // 历史记录为空时正常显示占位），页面整体滚动由外层负责，避免记录被遮挡
        IndexedStack(
          index: _controller.index,
          children: List.generate(widget.tabs.length, (i) => widget.contentBuilder(i)),
        ),
      ],
    );
  }
}

class TabItem {
  final Widget child;
  final String? key;

  const TabItem({required this.child, this.key});
}
