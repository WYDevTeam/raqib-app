import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/entities/category_entity.dart';
import 'cubit/category_cubit.dart';
import 'cubit/category_state.dart';

// ── Color palette ─────────────────────────────────────────────────────────────

const _kColors = [
  Color(0xFFFF6B6B),
  Color(0xFFFF9A9A),
  Color(0xFFFFBE7B),
  Color(0xFFF9C74F),
  Color(0xFF10C469),
  Color(0xFF4ECDC4),
  Color(0xFF45B7D1),
  Color(0xFF2E6FF2),
  Color(0xFF7EC8E3),
  Color(0xFFBB86FC),
  Color(0xFFC7A8F0),
  Color(0xFF9A9FA5),
];

// ── Emoji palette ─────────────────────────────────────────────────────────────

const _kEmojis = [
  '🍕', '🍔', '🍣', '☕', '🍎', '🥗', '🍜', '🧁',
  '🚗', '🚌', '✈️', '⛽', '🚲', '🏍️', '🚢', '🛵',
  '🏠', '🏢', '🛒', '💊', '🎮', '📚', '💰', '💳',
  '🎬', '🎵', '🏋️', '🐕', '🌱', '⚡', '💧', '🎁',
  '👕', '💻', '📱', '🎓', '🏖️', '🔧', '💼', '🎯',
  '📦', '🏥', '🛍️', '🐈', '🌿', '🔌', '🎄', '🏦',
];

class AddCategoryScreen extends StatelessWidget {
  final CategoryEntity? category;
  const AddCategoryScreen({super.key, this.category});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CategoryCubit>(),
      child: _AddCategoryView(category: category),
    );
  }
}

class _AddCategoryView extends StatefulWidget {
  final CategoryEntity? category;
  const _AddCategoryView({this.category});

  @override
  State<_AddCategoryView> createState() => _AddCategoryViewState();
}

class _AddCategoryViewState extends State<_AddCategoryView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedEmoji = '📦';
  Color _selectedColor = _kColors[0];
  CategoryType _selectedType = CategoryType.expense;

  bool get _isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    if (c != null) {
      _nameController.text = c.name;
      _selectedEmoji = c.emoji;
      _selectedColor = Color(c.colorValue);
      _selectedType = c.type;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final cubit = context.read<CategoryCubit>();

    if (_isEditing) {
      final updated = widget.category!.copyWith(
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        colorValue: _selectedColor.toARGB32(),
        type: _selectedType,
      );
      await cubit.updateCategory(updated);
    } else {
      final cat = CategoryEntity(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        emoji: _selectedEmoji,
        colorValue: _selectedColor.toARGB32(),
        type: _selectedType,
      );
      await cubit.addCategory(cat);
    }

    if (context.mounted) Navigator.pop(context);
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EmojiPickerSheet(
        selected: _selectedEmoji,
        onSelected: (e) => setState(() => _selectedEmoji = e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoryCubit, CategoryState>(
      listener: (context, state) {
        if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.error),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'تعديل الفئة' : 'فئة جديدة'),
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Emoji + color preview ──────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _showEmojiPicker,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: _selectedColor, width: 2),
                      ),
                      child: Center(
                        child: Text(_selectedEmoji,
                            style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'اضغط لتغيير الأيقونة',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 28),

                // ── Name ──────────────────────────────────────────────
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'اسم الفئة'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'أدخل اسم الفئة'
                      : null,
                ),
                const SizedBox(height: 24),

                // ── Type ──────────────────────────────────────────────
                Text('النوع',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 10),
                Row(
                  children: CategoryType.values.map((t) {
                    final sel = _selectedType == t;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedType = t),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: sel
                                  ? AppTheme.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? AppTheme.primary
                                    : AppTheme.textDisabled,
                                width: sel ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              t.arabicLabel,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: sel
                                    ? AppTheme.primary
                                    : AppTheme.textSecondary,
                                fontWeight: sel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // ── Color palette ─────────────────────────────────────
                Text('اللون',
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _kColors.map((c) {
                    final sel = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: sel
                              ? Border.all(
                                  color: Colors.black26, width: 3)
                              : null,
                        ),
                        child: sel
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 18)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                // ── Save ──────────────────────────────────────────────
                ElevatedButton(
                  onPressed: () => _save(context),
                  child:
                      Text(_isEditing ? 'حفظ التعديلات' : 'إضافة الفئة'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Emoji picker sheet ────────────────────────────────────────────────────────

class _EmojiPickerSheet extends StatelessWidget {
  final String selected;
  final void Function(String) onSelected;

  const _EmojiPickerSheet(
      {required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.textDisabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Text('اختر أيقونة',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _kEmojis.length,
              itemBuilder: (context, i) {
                final emoji = _kEmojis[i];
                final isSel = emoji == selected;
                return GestureDetector(
                  onTap: () {
                    onSelected(emoji);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSel
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isSel
                          ? Border.all(color: AppTheme.primary)
                          : null,
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 22)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
