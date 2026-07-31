import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/credential_storage.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _bucketController = TextEditingController();
  final _accessKeyController = TextEditingController();
  final _secretKeyController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureSecret = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _bucketController.dispose();
    _accessKeyController.dispose();
    _secretKeyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final bucket = _bucketController.text.trim();
    final accessKey = _accessKeyController.text.trim();
    final secretKey = _secretKeyController.text;

    if (username.isEmpty ||
        password.isEmpty ||
        bucket.isEmpty ||
        accessKey.isEmpty ||
        secretKey.isEmpty) {
      setState(() {
        _errorMessage = '请填写所有字段';
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final authService = await ref.read(authServiceProvider.future);
      await authService.login(
        username: username.trim(),
        password: password.trim(),
        bucket: bucket.trim(),
        accessKey: accessKey.trim(),
        secretKey: secretKey.trim(),
      );

      if (mounted) {
        ref.invalidate(credentialStorageProvider);
        ref.invalidate(isLoggedInProvider);
        ref.invalidate(s3CredentialsProvider);
        context.go('/daily-plan');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                    padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cloud, color: AppColors.primary, size: 28),
                          SizedBox(width: 12),
                          Text('生活工作台',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.foreground)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('登录您的账户以开始使用',
                          style: TextStyle(
                              fontSize: 13, color: AppColors.mutedForeground)),
                      const SizedBox(height: 28),
                      _buildField(
                        controller: _usernameController,
                        label: '用户名',
                        hintText: '请输入用户名',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _passwordController,
                        label: '密码',
                        hintText: '请输入密码',
                        icon: Icons.lock_outline,
                        obscure: _obscurePassword,
                        onToggleObscure: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('S3 对象存储配置',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.mutedForeground)),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _bucketController,
                              label: '桶名',
                              hintText: 'bucket-name',
                              icon: Icons.storage,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _accessKeyController,
                              label: 'AccessKey',
                              hintText: 'Access Key',
                              icon: Icons.vpn_key_outlined,
                            ),
                            const SizedBox(height: 12),
                            _buildField(
                              controller: _secretKeyController,
                              label: 'SecretKey',
                              hintText: 'Secret Key',
                              icon: Icons.enhanced_encryption,
                              obscure: _obscureSecret,
                              onToggleObscure: () =>
                                  setState(() => _obscureSecret = !_obscureSecret),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.destructive.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.destructive.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppColors.destructive, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(_errorMessage!,
                                    style: const TextStyle(
                                        color: AppColors.destructive, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                      if (_errorMessage != null) const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('登录',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'S3 地址: s3.cstcloud.cn',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedForeground.withValues(alpha: 0.7)),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ),
              ),
            ),
          ),
        );
      },
      ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    bool obscure = false,
    VoidCallback? onToggleObscure,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedForeground)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(icon, size: 18, color: AppColors.mutedForeground),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: const TextStyle(fontSize: 14, color: AppColors.foreground),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: const TextStyle(
                        color: AppColors.mutedForeground, fontSize: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isCollapsed: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (onToggleObscure != null)
                GestureDetector(
                  onTap: onToggleObscure,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                        obscure ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: AppColors.mutedForeground),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
