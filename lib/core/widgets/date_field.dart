import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class DateField extends StatelessWidget {
  final DateTime? value;
  final void Function(DateTime) onChanged;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const DateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'التاريخ',
    this.firstDate,
    this.lastDate,
  });

  String _format(DateTime d) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      locale: const Locale('ar'),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today_outlined,
              size: 18, color: AppTheme.textSecondary),
        ),
        child: Text(
          value != null ? _format(value!) : '',
          style: value != null
              ? Theme.of(context).textTheme.bodyLarge
              : Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: AppTheme.textDisabled),
        ),
      ),
    );
  }
}
