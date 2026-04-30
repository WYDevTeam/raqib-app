import 'package:flutter/material.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/entities/dashboard_widget_entity.dart';
import '../domain/usecases/delete_custom_widget_usecase.dart';
import '../domain/usecases/update_dashboard_widgets_usecase.dart';

class CustomizeDashboardScreen extends StatefulWidget {
  final List<DashboardWidget> initialWidgets;
  const CustomizeDashboardScreen({super.key, required this.initialWidgets});

  @override
  State<CustomizeDashboardScreen> createState() =>
      _CustomizeDashboardScreenState();
}

class _CustomizeDashboardScreenState extends State<CustomizeDashboardScreen> {
  late List<DashboardWidget> _widgets;
  final List<String> _toDelete = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _widgets = List.from(widget.initialWidgets);
  }

  void _toggle(int index) {
    setState(() {
      _widgets[index] = _widgets[index].copyWith(
        isVisible: !_widgets[index].isVisible,
      );
    });
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final item = _widgets.removeAt(oldIndex);
      _widgets.insert(newIndex, item);
      for (var i = 0; i < _widgets.length; i++) {
        _widgets[i] = _widgets[i].copyWith(sortOrder: i);
      }
    });
  }

  void _resetDefaults() {
    setState(() {
      _widgets = _widgets.map((w) => w.copyWith(isVisible: true)).toList();
    });
  }

  void _deleteWidget(DashboardWidget w) {
    setState(() {
      _widgets.removeWhere((ww) => ww.id == w.id);
      _toDelete.add(w.id);
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    for (final id in _toDelete) {
      await sl<DeleteCustomWidgetUseCase>()(id);
    }
    await sl<UpdateDashboardWidgetsUseCase>()(_widgets);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تخصيص الواجهة'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _resetDefaults,
            child: const Text('إعادة الافتراضي',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'اسحب لإعادة الترتيب، أو فعّل/أوقف كل بطاقة',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _widgets.length,
              onReorder: _reorder,
              itemBuilder: (context, index) {
                final w = _widgets[index];
                return _WidgetTile(
                  key: ValueKey(w.id),
                  widget: w,
                  onToggle: () => _toggle(index),
                  onDelete: w.isCustomFormula ? () => _deleteWidget(w) : null,
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('حفظ'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WidgetTile extends StatelessWidget {
  final DashboardWidget widget;
  final VoidCallback onToggle;
  final VoidCallback? onDelete;

  const _WidgetTile({
    super.key,
    required this.widget,
    required this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: ListTile(
        leading: const Icon(Icons.drag_handle, color: AppTheme.textDisabled),
        title:
            Text(widget.title, style: Theme.of(context).textTheme.titleSmall),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppTheme.error, size: 20),
                onPressed: onDelete,
              ),
            Switch(
              value: widget.isVisible,
              onChanged: (_) => onToggle(),
              activeThumbColor: AppTheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
