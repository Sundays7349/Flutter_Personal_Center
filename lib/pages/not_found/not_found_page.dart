import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('404', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('页面不存在', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/daily-plan'),
            child: const Text('返回首页'),
          ),
        ],
      ),
    );
  }
}
