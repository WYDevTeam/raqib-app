import 'package:flutter/material.dart';

import '../../models/import/ambiguous_item.dart';
import '../../models/import/file_analysis.dart';
import '../../models/import/user_answer.dart';
import 'import_loading_screen.dart';

class ImportQuestionsScreen extends StatefulWidget {
  final String filePath;
  final FileAnalysis analysis;

  const ImportQuestionsScreen({
    super.key,
    required this.filePath,
    required this.analysis,
  });

  @override
  State<ImportQuestionsScreen> createState() => _ImportQuestionsScreenState();
}

class _ImportQuestionsScreenState extends State<ImportQuestionsScreen> {
  int _currentIndex = 0;
  final Map<String, String> _selectedOptions = {};
  final Map<String, TextEditingController> _customControllers = {};

  List<AmbiguousItem> get _items => widget.analysis.ambiguousItems;
  AmbiguousItem get _current => _items[_currentIndex];
  bool get _isLast => _currentIndex == _items.length - 1;

  @override
  void initState() {
    super.initState();
    // ضع الخيار الافتراضي لكل سؤال
    for (final item in _items) {
      if (item.defaultOption != null) {
        _selectedOptions[item.id] = item.defaultOption!;
      }
      _customControllers[item.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _onNext() {
    if (_selectedOptions[_current.id] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار إجابة قبل المتابعة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isLast) {
      _finishAndNavigate();
    } else {
      setState(() => _currentIndex++);
    }
  }

  void _finishAndNavigate() {
    final answers = <UserAnswer>[];
    for (final item in _items) {
      final chosen = _selectedOptions[item.id];
      if (chosen == null) continue;

      final customText = chosen == 'غير ذلك'
          ? _customControllers[item.id]?.text.trim()
          : null;

      answers.add(UserAnswer(
        ambiguousItemId: item.id,
        chosenOption: chosen,
        customText: customText?.isEmpty == true ? null : customText,
      ));
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ImportLoadingScreen(
          filePath: widget.filePath,
          analysis: widget.analysis,
          userAnswers: answers,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_currentIndex + 1) / _items.length;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () {
            if (_currentIndex > 0) {
              setState(() => _currentIndex--);
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'فهم ملفك',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Row(
              children: [
                Text(
                  'السؤال ${_currentIndex + 1} من ${_items.length}',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontFamily: 'Cairo',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'أجب على هذه الأسئلة لاستيراد بياناتك بدقة',
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'Cairo',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildQuestionCard(_current, colorScheme),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: ElevatedButton(
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _isLast ? 'إنهاء وابدأ الاستيراد' : 'التالي',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(AmbiguousItem item, ColorScheme colorScheme) {
    final selectedOption = _selectedOptions[item.id];
    final isOther = selectedOption == 'غير ذلك';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── السؤال ──────────────────────────────────────────────────────────
          Text(
            item.question,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          // ── السياق ─────────────────────────────────────────────────────────
          if (item.context.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.format_quote,
                      color: colorScheme.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.context,
                      style: TextStyle(
                        color: colorScheme.primary.withValues(alpha: 0.8),
                        fontFamily: 'Cairo',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          // ── الخيارات ───────────────────────────────────────────────────────
          const Text(
            'اختر الإجابة:',
            style: TextStyle(
              color: Colors.white60,
              fontFamily: 'Cairo',
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...item.options.map((option) {
            final isSelected = selectedOption == option;
            return GestureDetector(
              onTap: () => setState(() => _selectedOptions[item.id] = option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(vertical: 5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.white.withValues(alpha: 0.1),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? colorScheme.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.white38,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check,
                              size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected
                              ? colorScheme.primary
                              : Colors.white70,
                          fontFamily: 'Cairo',
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (item.defaultOption == option)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'افتراضي',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          // ── حقل "غير ذلك" ──────────────────────────────────────────────────
          if (isOther) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customControllers[item.id],
              style: const TextStyle(
                  color: Colors.white, fontFamily: 'Cairo'),
              decoration: InputDecoration(
                hintText: 'اكتب تصنيفك الخاص...',
                hintStyle: const TextStyle(
                    color: Colors.white38, fontFamily: 'Cairo'),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
