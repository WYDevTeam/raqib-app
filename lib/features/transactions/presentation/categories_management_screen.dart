import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/entities/category_entity.dart';
import 'cubit/category_cubit.dart';
import 'cubit/category_state.dart';

class CategoriesManagementScreen extends StatelessWidget {
  const CategoriesManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CategoryCubit>()..loadCategories(),
      child: const _CategoriesView(),
    );
  }
}

class _CategoriesView extends StatelessWidget {
  const _CategoriesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الفئات')),
      body: BlocConsumer<CategoryCubit, CategoryState>(
        listener: (context, state) {
          if (state is CategoryError) {
            ScaffoldMessenger.of(context)
              ..clearSnackBars()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          }
        },
        builder: (context, state) {
          // Always resolve to a category list; never blank the screen on error.
          final categories = switch (state) {
            CategoryLoaded(:final categories) => categories,
            CategoryError(:final categories) => categories,
            _ => null,
          };

          if (categories == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _CategoriesList(categories: categories);
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'categories_add_fab',
        onPressed: () => _navigateToAdd(context),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _navigateToAdd(BuildContext context) {
    final cubit = context.read<CategoryCubit>();
    context.push('/categories/add').then((_) => cubit.loadCategories());
  }
}

class _CategoriesList extends StatelessWidget {
  final List<CategoryEntity> categories;
  const _CategoriesList({required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: AppTheme.textDisabled,
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد فئات',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            SizedBox(height: 8),
            Text(
              'اضغط + لإضافة فئة جديدة',
              style: TextStyle(color: AppTheme.textDisabled, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      separatorBuilder: (context, i) => const SizedBox(height: 8),
      itemBuilder: (context, i) => _CategoryTile(category: categories[i]),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final CategoryEntity category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  IconData(category.iconCodePoint, fontFamily: 'MaterialIcons'),
                  size: 20,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    category.type.arabicLabel,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
              onPressed: () => _showOptions(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final cubit = context.read<CategoryCubit>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.textDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('تعديل الفئة'),
              onTap: () {
                Navigator.pop(sheetCtx);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context
                        .push('/categories/add', extra: category)
                        .then((_) => cubit.loadCategories());
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppTheme.error),
              title: const Text(
                'حذف الفئة',
                style: TextStyle(color: AppTheme.error),
              ),
              onTap: () {
                Navigator.pop(sheetCtx);
                // Wait for sheet close animation before showing dialog.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) _confirmDelete(context, cubit);
                });
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, CategoryCubit cubit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف الفئة'),
        content: Text('هل تريد حذف فئة "${category.name}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.deleteCategory(category.id);
  }
}
