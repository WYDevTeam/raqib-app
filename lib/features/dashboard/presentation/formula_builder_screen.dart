import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FormulaBuilderScreen extends StatefulWidget {
  final String? initialTitle;
  final List<String>? initialFormulaParts;

  const FormulaBuilderScreen({
    super.key,
    this.initialTitle,
    this.initialFormulaParts,
  });

  @override
  State<FormulaBuilderScreen> createState() => _FormulaBuilderScreenState();
}

class _FormulaBuilderScreenState extends State<FormulaBuilderScreen> {
  late List<String> _formulaParts;
  late TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _formulaParts = widget.initialFormulaParts ?? ['Liquid Cash', ' - ', 'Amanah Held'];
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('بناء / تعديل المعادلة'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'اسم المعادلة',
                  hintText: 'مثال: كاشي الحقيقي',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'المعادلة:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._formulaParts.asMap().entries.map((entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildFormulaChip(entry.key, entry.value),
                        )),
                    ActionChip(
                      label: const Icon(Icons.add, size: 16),
                      onPressed: _showAddVariableDialog,
                      backgroundColor: AppTheme.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: Color(0xFFEFEFEF)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'معاينة النتيجة:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      '\$3,000.00',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('حفظ المعادلة'),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddVariableDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('إضافة عنصر للمعادلة', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const Text('العمليات الحسابية:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [' + ', ' - ', ' * ', ' / ', ' ( ', ' ) '].map((op) => ActionChip(
                  label: Text(op, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  onPressed: () {
                    setState(() => _formulaParts.add(op));
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
              const SizedBox(height: 16),
              const Text('المتغيرات الأساسية:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  'الكاش الفعلي', 'إجمالي الديون', 'إجمالي الأمانات', 'الدخل', 'المصاريف', 'قيمة مخصصة'
                ].map((v) => ActionChip(
                  label: Text(v),
                  onPressed: () {
                    setState(() => _formulaParts.add(v));
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormulaChip(int index, String text) {
    final isOperator = ['+', '-', '*', '/', '(', ')'].contains(text.trim());
    return InkWell(
      onTap: () {
        setState(() {
          _formulaParts.removeAt(index);
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOperator ? AppTheme.primary.withValues(alpha: 0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOperator ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFEFEFEF),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isOperator ? AppTheme.primary : AppTheme.textPrimary,
                fontWeight: isOperator ? FontWeight.bold : FontWeight.normal,
                fontFamily: isOperator ? 'monospace' : null,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.close, size: 14, color: AppTheme.error.withValues(alpha: 0.7)),
          ],
        ),
      ),
    );
  }
}
