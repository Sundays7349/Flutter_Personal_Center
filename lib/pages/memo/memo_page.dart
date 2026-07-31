import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../widgets/app_checkbox.dart';
import '../../widgets/app_tabs.dart';
import '../../core/models/models.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/device_info.dart';

class MemoPage extends ConsumerStatefulWidget {
  const MemoPage({super.key});

  @override
  ConsumerState<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends ConsumerState<MemoPage> {
  final _noteController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _contactAccountController = TextEditingController();
  final _contactPasswordController = TextEditingController();
  final _shopController = TextEditingController();

  final bool _obscurePassword = true;

  @override
  void dispose() {
    _noteController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _contactAccountController.dispose();
    _contactPasswordController.dispose();
    _shopController.dispose();
    super.dispose();
  }

  Future<void> _addNote() async {
    if (_noteController.text.trim().isEmpty) return;
    final repo = ref.read(memoRepoProvider);
    final now = DeviceInfo.nowTimestamp();
    await repo.insertNote(MemoNote(
      id: const Uuid().v4(),
      content: _noteController.text.trim(),
      done: false,
      createdAt: now,
      updatedAt: now,
      deviceId: '',
      synced: false,
    ));
    _noteController.clear();
    ref.invalidate(memoNotesProvider);
  }

  Future<void> _toggleNoteDone(MemoNote note) async {
    final repo = ref.read(memoRepoProvider);
    await repo.updateNote(note.copyWith(
      done: !note.done,
      updatedAt: DeviceInfo.nowTimestamp(),
      synced: false,
    ));
    ref.invalidate(memoNotesProvider);
  }

  Future<void> _deleteNote(String id) async {
    final repo = ref.read(memoRepoProvider);
    await repo.deleteNote(id);
    ref.invalidate(memoNotesProvider);
  }

  Future<void> _addContact() async {
    if (_contactNameController.text.trim().isEmpty) return;
    final repo = ref.read(memoRepoProvider);
    final now = DeviceInfo.nowTimestamp();
    await repo.insertContact(MemoContact(
      id: const Uuid().v4(),
      name: _contactNameController.text.trim(),
      phone: _contactPhoneController.text.isEmpty ? null : _contactPhoneController.text.trim(),
      account: _contactAccountController.text.isEmpty ? null : _contactAccountController.text.trim(),
      password: _contactPasswordController.text.isEmpty ? null : _contactPasswordController.text.trim(),
      createdAt: now,
      updatedAt: now,
      deviceId: '',
      synced: false,
    ));
    _contactNameController.clear();
    _contactPhoneController.clear();
    _contactAccountController.clear();
    _contactPasswordController.clear();
    ref.invalidate(memoContactsProvider);
  }

  Future<void> _deleteContact(String id) async {
    final repo = ref.read(memoRepoProvider);
    await repo.deleteContact(id);
    ref.invalidate(memoContactsProvider);
  }

  Future<void> _addShopping() async {
    if (_shopController.text.trim().isEmpty) return;
    final repo = ref.read(memoRepoProvider);
    final now = DeviceInfo.nowTimestamp();
    await repo.insertShopping(MemoShopping(
      id: const Uuid().v4(),
      name: _shopController.text.trim(),
      done: false,
      createdAt: now,
      updatedAt: now,
      deviceId: '',
      synced: false,
    ));
    _shopController.clear();
    ref.invalidate(memoShoppingsProvider);
  }

  Future<void> _toggleShoppingDone(MemoShopping item) async {
    final repo = ref.read(memoRepoProvider);
    await repo.updateShopping(item.copyWith(
      done: !item.done,
      updatedAt: DeviceInfo.nowTimestamp(),
      synced: false,
    ));
    ref.invalidate(memoShoppingsProvider);
  }

  Future<void> _deleteShopping(String id) async {
    final repo = ref.read(memoRepoProvider);
    await repo.deleteShopping(id);
    ref.invalidate(memoShoppingsProvider);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: AppTabs(
        tabs: const [
          TabItem(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.description, size: 14), SizedBox(width: 6), Text('随笔事项')])),
          TabItem(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.phone, size: 14), SizedBox(width: 6), Text('联系人归档')])),
          TabItem(child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.shopping_bag, size: 14), SizedBox(width: 6), Text('购物清单')])),
        ],
        contentBuilder: (index) {
          switch (index) {
            case 0:
              return _buildNotesTab();
            case 1:
              return _buildContactsTab();
            case 2:
              return _buildShoppingTab();
            default:
              return const SizedBox.shrink();
          }
        },
      ),
    );
  }

  Widget _buildNotesTab() {
    final notesAsync = ref.watch(memoNotesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextarea(
          controller: _noteController,
          hintText: '随手记录想法、临时事项...',
          maxLines: 3,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppButton(
              onPressed: _addNote,
              child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('添加随笔')]),
            ),
          ],
        ),
        const SizedBox(height: 16),
        notesAsync.when(
          data: (notes) {
            if (notes.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '暂无随笔，记录点什么吧 ✍️',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                ),
              );
            }
            return Column(
              children: notes.map((note) => _buildNoteItem(note)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败: $error')),
        ),
      ],
    );
  }

  Widget _buildNoteItem(MemoNote note) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCheckbox(value: note.done, onChanged: (_) => _toggleNoteDone(note)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              note.content,
              style: TextStyle(
                fontSize: 14,
                color: note.done ? AppColors.mutedForeground : AppColors.foreground,
                decoration: note.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => _deleteNote(note.id),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsTab() {
    final contactsAsync = ref.watch(memoContactsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.muted.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: 180, child: AppInput(controller: _contactNameController, hintText: '姓名/备注')),
              SizedBox(width: 180, child: AppInput(controller: _contactPhoneController, hintText: '电话')),
              SizedBox(width: 180, child: AppInput(controller: _contactAccountController, hintText: '账号')),
              SizedBox(width: 180, child: AppInput(controller: _contactPasswordController, hintText: '密码', obscureText: _obscurePassword)),
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AppButton(
                      onPressed: _addContact,
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 16), SizedBox(width: 6), Text('添加联系人')]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        contactsAsync.when(
          data: (contacts) {
            if (contacts.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '暂无联系人 📇',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                ),
              );
            }
            return Column(
              children: contacts.map((c) => _buildContactItem(c)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败: $error')),
        ),
      ],
    );
  }

  Widget _buildContactItem(MemoContact c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.foreground)),
                if (c.phone != null && c.phone!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('📞 ${c.phone}', style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                ],
                if (c.account != null && c.account!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text('👤 ${c.account}', style: const TextStyle(fontSize: 13, color: AppColors.mutedForeground)),
                ],
              ],
            ),
          ),
          AppButton(
            variant: AppButtonVariant.destructive,
            size: AppButtonSize.sm,
            onPressed: () => _deleteContact(c.id),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget _buildShoppingTab() {
    final shoppingAsync = ref.watch(memoShoppingsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AppInput(controller: _shopController, hintText: '添加购物项...'),
            ),
            const SizedBox(width: 8),
            AppButton(onPressed: _addShopping, child: const Text('添加')),
          ],
        ),
        const SizedBox(height: 16),
        shoppingAsync.when(
          data: (shopping) {
            if (shopping.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                decoration: BoxDecoration(
                  color: AppColors.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '购物清单空空如也 🛒',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.mutedForeground),
                ),
              );
            }
            return Column(
              children: shopping.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
                ),
                child: Row(
                  children: [
                    AppCheckbox(value: item.done, onChanged: (_) => _toggleShoppingDone(item)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: item.done ? AppColors.mutedForeground : AppColors.foreground,
                          decoration: item.done ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    AppButton(
                      variant: AppButtonVariant.destructive,
                      size: AppButtonSize.sm,
                      onPressed: () => _deleteShopping(item.id),
                      child: const Text('删除'),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('加载失败: $error')),
        ),
      ],
    );
  }
}
