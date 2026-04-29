import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GestureDetector(
            onTap: () => context.push('/subscription'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.workspace_premium, color: Color(0xFFFFD700)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ارتقِ إلى راقب Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'افتح جميع الميزات المتقدمة',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Color(0xFFFFD700), size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'كيف تُحسب أرقامي؟',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          _buildSettingsSection(
            context,
            title: 'المعادلات الأساسية',
            children: [
              ListTile(
                title: const Text('صافي الثروة'),
                subtitle: const Text('المعادلة الحالية: الأصول + الكاش - الديون'),
                trailing: const Icon(Icons.edit, color: AppTheme.primary),
                onTap: () {
                  context.push('/dashboard/settings/formula-builder', extra: {
                    'title': 'صافي الثروة',
                    'formulaParts': ['الأصول', ' + ', 'الكاش', ' - ', 'الديون'],
                  });
                },
              ),
              ListTile(
                title: const Text('الكاش الفعلي'),
                subtitle: const Text('المعادلة الحالية: كاش جاهز - أمانات'),
                trailing: const Icon(Icons.edit, color: AppTheme.primary),
                onTap: () {
                  context.push('/dashboard/settings/formula-builder', extra: {
                    'title': 'الكاش الفعلي',
                    'formulaParts': ['كاش جاهز', ' - ', 'أمانات عندي'],
                  });
                },
              ),
              ListTile(
                title: const Text('الربح الحقيقي (P&L)'),
                subtitle: const Text('المعادلة الحالية: الدخل - المصاريف'),
                trailing: const Icon(Icons.edit, color: AppTheme.primary),
                onTap: () {
                  context.push('/dashboard/settings/formula-builder', extra: {
                    'title': 'الربح الحقيقي (P&L)',
                    'formulaParts': ['الدخل', ' - ', 'المصاريف'],
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSettingsSection(
            context,
            title: 'الرصيد التراكمي',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تاريخ عرض البيانات'),
                trailing: DropdownButton<String>(
                  value: '12 Months',
                  items: const [
                    DropdownMenuItem(value: '12 Months', child: Text('آخر 12 شهر')),
                    DropdownMenuItem(value: 'All Time', child: Text('كل التاريخ')),
                  ],
                  onChanged: (val) {},
                  underline: const SizedBox(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.error,
                side: const BorderSide(color: AppTheme.error),
              ),
              onPressed: () {},
              child: const Text('إعادة تعيين المعادلات للقيم الافتراضية'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }
}
