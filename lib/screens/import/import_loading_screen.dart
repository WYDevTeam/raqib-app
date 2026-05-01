import 'package:flutter/material.dart';

import '../../models/import/file_analysis.dart';
import '../../models/import/user_answer.dart';
import '../../services/import/gemini_import_service.dart';
import 'import_review_screen.dart';

class ImportLoadingScreen extends StatefulWidget {
  final String filePath;
  final FileAnalysis analysis;
  final List<UserAnswer> userAnswers;

  const ImportLoadingScreen({
    super.key,
    required this.filePath,
    required this.analysis,
    required this.userAnswers,
  });

  @override
  State<ImportLoadingScreen> createState() => _ImportLoadingScreenState();
}

class _ImportLoadingScreenState extends State<ImportLoadingScreen> {
  double _progress = 0.0;
  int _currentRow = 0;
  int _totalRows = 0;
  String _statusText = 'جاري التحضير...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _startClassification();
  }

  Future<void> _startClassification() async {
    setState(() {
      _hasError = false;
      _progress = 0.0;
      _statusText = 'جاري تحليل البيانات...';
    });

    try {
      final result = await GeminiImportService.classifyWithAnswers(
        filePath: widget.filePath,
        analysis: widget.analysis,
        userAnswers: widget.userAnswers,
        onProgress: (current, total) {
          if (mounted) {
            setState(() {
              _currentRow = current;
              _totalRows = total;
              _progress = total > 0 ? current / total : 0;
              _statusText = 'جاري معالجة الصف $current من $total...';
            });
          }
        },
      );

      if (!mounted) return;

      setState(() {
        _progress = 1.0;
        _statusText = 'اكتمل التحليل!';
      });

      await Future.delayed(const Duration(milliseconds: 600));

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ImportReviewScreen(
            result: result,
            filePath: widget.filePath,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _retry() => _startClassification();

  void _cancel() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _hasError, // لا يسمح بالرجوع أثناء المعالجة
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0E1A),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                // ── أيقونة متحركة ─────────────────────────────────────────
                if (!_hasError) ...[
                  _AnimatedBrainIcon(color: colorScheme.primary),
                ] else ...[
                  Icon(
                    Icons.error_outline_rounded,
                    size: 80,
                    color: Colors.red.shade400,
                  ),
                ],
                const SizedBox(height: 40),
                if (!_hasError) ...[
                  // ── نص الحالة ───────────────────────────────────────────
                  Text(
                    _statusText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (_totalRows > 0)
                    Text(
                      'تمت معالجة $_currentRow من $_totalRows صف',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 32),
                  // ── شريط التقدم ─────────────────────────────────────────
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _progress > 0 ? _progress : null,
                      minHeight: 8,
                      backgroundColor: Colors.white12,
                      valueColor:
                          AlwaysStoppedAnimation(colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'يُرجى الانتظار وعدم إغلاق التطبيق',
                    style: TextStyle(
                      color: Colors.white30,
                      fontFamily: 'Cairo',
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  // ── رسالة الخطأ ──────────────────────────────────────────
                  Text(
                    'حدث خطأ',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'Cairo',
                        fontSize: 14,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text(
                      'حاول مجدداً',
                      style: TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _cancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white54,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إلغاء',
                      style:
                          TextStyle(fontFamily: 'Cairo', color: Colors.white54),
                    ),
                  ),
                ],
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Animated brain/AI icon ────────────────────────────────────────────────────
class _AnimatedBrainIcon extends StatefulWidget {
  final Color color;
  const _AnimatedBrainIcon({required this.color});

  @override
  State<_AnimatedBrainIcon> createState() => _AnimatedBrainIconState();
}

class _AnimatedBrainIconState extends State<_AnimatedBrainIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _pulse,
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withValues(alpha: 0.3),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 56,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}
