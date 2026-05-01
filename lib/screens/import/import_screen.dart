import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/import/gemini_import_service.dart';
import 'import_loading_screen.dart';
import 'import_questions_screen.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isAnalyzing = false;

  Future<void> _pickAndAnalyze() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'csv'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final filePath = result.files.single.path;
    if (filePath == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final analysis =
          await GeminiImportService.analyzeAndGenerateQuestions(filePath);

      if (!mounted) return;

      if (analysis.ambiguousItems.isEmpty) {
        // لا أسئلة → انتقل مباشرة لشاشة التحميل
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImportLoadingScreen(
              filePath: filePath,
              analysis: analysis,
              userAnswers: const [],
            ),
          ),
        );
      } else {
        // في أسئلة → شاشة الأسئلة
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ImportQuestionsScreen(
              filePath: filePath,
              analysis: analysis,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'استيراد من Excel',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Spacer(),
            // ── أيقونة ──────────────────────────────────────────────────────
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.3),
                    colorScheme.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.table_chart_rounded,
                size: 56,
                color: colorScheme.primary,
              ),
            ).also((w) => Center(child: w)),
            const SizedBox(height: 32),
            const Text(
              'استيراد ذكي لبياناتك',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'ارفع ملف Excel أو CSV وسيقوم Gemini بتحليله\nوتصنيف بياناتك تلقائياً',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 15,
                fontFamily: 'Cairo',
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            // ── خطوات ────────────────────────────────────────────────────────
            _buildStep(1, 'اختر الملف', 'xlsx أو csv', Icons.upload_file),
            const SizedBox(height: 12),
            _buildStep(2, 'أجب على الأسئلة',
                'Gemini يسألك عن الحالات الغامضة فقط', Icons.quiz_outlined),
            const SizedBox(height: 12),
            _buildStep(3, 'راجع وحفظ',
                'تحقق من النتائج قبل الحفظ في تطبيقك', Icons.checklist_rounded),
            const Spacer(),
            // ── زر الاختيار ────────────────────────────────────────────────
            if (_isAnalyzing) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    CircularProgressIndicator(color: colorScheme.primary),
                    const SizedBox(height: 16),
                    const Text(
                      'جاري تحليل ملفك بواسطة Gemini...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'قد يستغرق هذا 10-20 ثانية',
                      style: TextStyle(
                        color: Colors.white38,
                        fontFamily: 'Cairo',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _pickAndAnalyze,
                icon: const Icon(Icons.upload_file, size: 22),
                label: const Text(
                  'اختر ملف Excel أو CSV',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
        Icon(icon, color: Colors.white30, size: 20),
      ],
    );
  }
}

// Helper extension
extension _AlsoExt<T extends Widget> on T {
  Widget also(Widget Function(T) fn) => fn(this);
}
