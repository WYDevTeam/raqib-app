import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/category_service.dart';

class FilterTransactionsSheet extends StatefulWidget {
  const FilterTransactionsSheet({super.key});

  @override
  State<FilterTransactionsSheet> createState() =>
      _FilterTransactionsSheetState();
}

class _FilterTransactionsSheetState extends State<FilterTransactionsSheet> {
  int _selectedTypeIndex = 0;
  int _selectedDateIndex = 1;
  String? _selectedCategory; // null = All

  Future<void> _showAddCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة فئة جديدة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'مثال: رياضة، سفر، هدايا...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                CategoryService.addCategory(controller.text);
                Navigator.pop(ctx);
                setState(() {}); // Refresh chip list
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = CategoryService.categories;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'تصفية المعاملات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Type ──────────────────────────────────────────────
                  const Text(
                    'النوع',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildFilterChip('الكل', 0, _selectedTypeIndex,
                          (i) => setState(() => _selectedTypeIndex = i)),
                      const SizedBox(width: 8),
                      _buildFilterChip('دخل', 1, _selectedTypeIndex,
                          (i) => setState(() => _selectedTypeIndex = i)),
                      const SizedBox(width: 8),
                      _buildFilterChip('مصروف', 2, _selectedTypeIndex,
                          (i) => setState(() => _selectedTypeIndex = i)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Period ────────────────────────────────────────────
                  const Text(
                    'الفترة',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip('كل الوقت', 0, _selectedDateIndex,
                          (i) => setState(() => _selectedDateIndex = i)),
                      _buildFilterChip('هذا الشهر', 1, _selectedDateIndex,
                          (i) => setState(() => _selectedDateIndex = i)),
                      _buildFilterChip('آخر 30 يوم', 2, _selectedDateIndex,
                          (i) => setState(() => _selectedDateIndex = i)),
                      _buildFilterChip('تخصيص...', 3, _selectedDateIndex,
                          (i) => setState(() => _selectedDateIndex = i)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Categories ────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'الفئة',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: _showAddCategoryDialog,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('إضافة فئة'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // "All" chip
                      _buildCategoryChip('الكل', null),
                      // Dynamic categories from CategoryService
                      ...categories.map((cat) => _buildCategoryChip(cat, cat)),
                    ],
                  ),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('تطبيق الفلاتر'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    int index,
    int selectedIndex,
    Function(int) onSelected,
  ) {
    final isSelected = index == selectedIndex;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onSelected(index),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.background,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : const Color(0xFFEFEFEF),
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategory = value),
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.background,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primary : const Color(0xFFEFEFEF),
      ),
    );
  }
}
