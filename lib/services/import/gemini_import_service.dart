import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../models/import/file_analysis.dart';
import '../../models/import/import_result.dart';
import '../../models/import/parsed_items.dart';
import '../../models/import/user_answer.dart';

class GeminiImportService {
  static const String _groqModel = 'llama-3.1-8b-instant';

  // ────────────────────────────────────────────────────────────────────────────
  // PUBLIC API
  // ────────────────────────────────────────────────────────────────────────────

  /// Pass 1: تحليل هيكل الملف وتوليد أسئلة للحالات الغامضة فقط.
  static Future<FileAnalysis> analyzeAndGenerateQuestions(
    String filePath,
  ) async {
    final allRows = await _readFile(filePath);
    if (allRows.isEmpty) {
      throw Exception('الملف فارغ أو لا يحتوي على بيانات قابلة للقراءة.');
    }

    final sample = allRows.take(15).toList();
    final sampleText = sample
        .asMap()
        .entries
        .map((e) => 'Row ${e.key + 1}: ${e.value.join(' | ')}')
        .join('\n');

    final allCategories = _extractUniqueCategories(allRows);
    final prompt = _buildAnalysisPrompt(
      sampleText: sampleText,
      allCategories: allCategories,
    );

    final apiKey = AppConfig.groqApiKey;
    if (apiKey.isEmpty) {
      throw Exception(
        'لم يتم العثور على مفتاح Groq API (GROQ_API_KEY) في ملف .env',
      );
    }

    final rawJson = await _callGemini(prompt, apiKey);
    final cleaned = _cleanJson(rawJson);

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception(
        'فشل تحليل استجابة Gemini: $e\n\nالاستجابة:\n${cleaned.substring(0, cleaned.length.clamp(0, 200))}',
      );
    }

    // أضف الكاتيغوريز الكاملة للنتيجة
    final FileAnalysis analysis;
    try {
      final parsed = FileAnalysis.fromJson(data);
      analysis = FileAnalysis(
        headers: parsed.headers,
        dataStartRow: parsed.dataStartRow,
        detectedColumns: parsed.detectedColumns,
        amountBehavior: parsed.amountBehavior,
        typeColumnIncomeValue: parsed.typeColumnIncomeValue,
        typeColumnExpenseValue: parsed.typeColumnExpenseValue,
        incomeColumnIndex: parsed.incomeColumnIndex,
        expenseColumnIndex: parsed.expenseColumnIndex,
        uniqueCategories: allCategories,
        ambiguousItems: parsed.ambiguousItems,
        notes: parsed.notes,
      );
    } catch (e) {
      throw Exception('خطأ في معالجة نتيجة Gemini: $e');
    }

    return analysis;
  }

  /// Pass 2: تصنيف كامل الملف مع Batch Processing (40 صف/batch).
  static Future<ImportResult> classifyWithAnswers({
    required String filePath,
    required FileAnalysis analysis,
    required List<UserAnswer> userAnswers,
    void Function(int current, int total)? onProgress,
  }) async {
    final allRows = await _readFile(filePath);
    final decisionsMap = _buildDecisionsMap(analysis, userAnswers);

    final dataRows = allRows.skip(analysis.dataStartRow).toList();

    final finalResult = ImportResult.empty();
    const batchSize = 40;

    for (int i = 0; i < dataRows.length; i += batchSize) {
      final end = (i + batchSize).clamp(0, dataRows.length);
      final batch = dataRows.sublist(i, end);

      try {
        final batchResult = await _classifyBatch(
          rows: batch,
          startIndex: i,
          analysis: analysis,
          decisionsMap: decisionsMap,
        );
        finalResult.merge(batchResult);
      } catch (e) {
        // لو batch فشل → أضف صفوفه كـ unclear
        for (int j = 0; j < batch.length; j++) {
          finalResult.unclear.add(
            UnclearRow(
              rowIndex: i + j,
              originalData: batch[j].join(' | '),
              reason: 'فشل التحليل: $e',
            ),
          );
        }
      }

      if (onProgress != null) {
        onProgress(end, dataRows.length);
      }

      // Groq free tier TPM recovery: wait 35s between batches to avoid 429
      if (end < dataRows.length) {
        await Future.delayed(const Duration(seconds: 35));
      }
    }

    return finalResult;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PRIVATE — FILE READING
  // ────────────────────────────────────────────────────────────────────────────

  static Future<List<List<String>>> _readFile(String filePath) async {
    if (filePath.toLowerCase().endsWith('.csv')) {
      return _readCsvFile(filePath);
    }
    return _readExcelFile(filePath);
  }

  static Future<List<List<String>>> _readExcelFile(String filePath) async {
    final bytes = await File(filePath).readAsBytes();

    final SpreadsheetDecoder decoder;
    try {
      decoder = SpreadsheetDecoder.decodeBytes(bytes.buffer.asUint8List());
    } catch (e) {
      throw Exception(
        'تعذّر قراءة ملف Excel.\n'
        'تأكد أن الملف بصيغة xlsx صحيحة وغير تالف.\n'
        'يمكنك أيضاً تصديره كـ CSV من Excel أو Google Sheets.\n'
        'تفاصيل: $e',
      );
    }

    if (decoder.tables.isEmpty) {
      throw Exception(
        'الملف لا يحتوي على أي ورقة بيانات (Sheet) قابلة للقراءة.',
      );
    }

    final sheetName = decoder.tables.keys.first;
    final sheet = decoder.tables[sheetName];
    if (sheet == null) return [];

    final result = <List<String>>[];

    for (final row in sheet.rows) {
      final cells = row.map((cell) {
        if (cell == null) return '';

        // التعامل مع DateTime
        if (cell is DateTime) {
          return '${cell.year}-${cell.month.toString().padLeft(2, '0')}-${cell.day.toString().padLeft(2, '0')}';
        }

        // Excel date serials: whole numbers in range 25569–54789 (1970–2050)
        // spreadsheet_decoder returns these as int/double instead of DateTime
        if (cell is int || cell is double) {
          final n = (cell as num).toDouble();
          if (n >= 25569 && n <= 54789 && n == n.truncateToDouble()) {
            try {
              final date = DateTime(
                1899,
                12,
                30,
              ).add(Duration(days: n.toInt()));
              return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            } catch (_) {}
          }
        }

        // تجاهل المعادلات
        final str = cell.toString().trim();
        if (str.startsWith('=')) return '';
        return str;
      }).toList();

      // تجاهل الصفوف الفارغة كلياً
      if (cells.every((c) => c.isEmpty)) continue;
      result.add(cells);
    }

    return result;
  }

  static Future<List<List<String>>> _readCsvFile(String filePath) async {
    final content = await File(filePath).readAsString();
    final lines = content.split('\n');
    final result = <List<String>>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final cells = trimmed.split(',').map((c) => c.trim()).toList();
      if (cells.every((c) => c.isEmpty)) continue;
      result.add(cells);
    }

    return result;
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PRIVATE — BATCH CLASSIFICATION
  // ────────────────────────────────────────────────────────────────────────────

  static Future<ImportResult> _classifyBatch({
    required List<List<String>> rows,
    required int startIndex,
    required FileAnalysis analysis,
    required Map<String, String> decisionsMap,
  }) async {
    final rowsText = rows
        .asMap()
        .entries
        .map((e) => 'Row ${startIndex + e.key + 1}: ${e.value.join(' | ')}')
        .join('\n');

    final prompt = _buildClassificationPrompt(
      analysis: analysis,
      decisionsMap: decisionsMap,
      rowsText: rowsText,
    );

    final apiKey = AppConfig.groqApiKey;
    if (apiKey.isEmpty) {
      throw Exception(
        'لم يتم العثور على مفتاح Groq API (GROQ_API_KEY) في ملف .env',
      );
    }

    final rawJson = await _callGemini(prompt, apiKey);
    final cleaned = _cleanJson(rawJson);

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('فشل تحليل batch JSON: $e');
    }

    try {
      return ImportResult.fromJson(data);
    } catch (e) {
      throw Exception('خطأ في تحويل بيانات Gemini: $e');
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PRIVATE — PROMPTS
  // ────────────────────────────────────────────────────────────────────────────

  static String _buildAnalysisPrompt({
    required String sampleText,
    required List<String> allCategories,
  }) {
    return '''
أنت محلل بيانات مالية ذكي. مهمتك تحليل ملف Excel مالي وتوليد أسئلة للمستخدم.

ملاحظة: بعض الخلايا قد تحتوي على أرقام صحيحة تمثل تواريخ Excel (مثل 45300 = 2024-03-06). إذا رأيت أرقاماً صحيحة كبيرة (40000–55000) في عمود يبدو أنه تاريخ، فتجاهلها واعتبرها تواريخ.

=== عينة من الملف (أول 15 صف) ===
$sampleText

=== جميع الكاتيغوريز الموجودة في الملف ===
${allCategories.join(', ')}

=== المطلوب ===

أولاً: افهم هيكل الملف
- حدد صف الـ headers (قد يكون الأول أو الثاني أو الثالث)
- حدد عمود التاريخ / المبلغ / النوع / الوصف / الكاتيغوري
- حدد كيف يُميَّز الدخل عن المصروف:
  * "type_column": عمود بقيم مثل Income/Expense أو دخل/مصروف
  * "signed": المبلغ سالب للمصروف وموجب للدخل
  * "two_columns": عمودان منفصلان للدخل وللمصروف

ثانياً: حدد الكاتيغوريز الغامضة وولّد أسئلة

لا تسأل عن هذه أبداً (واضحة):
- راتب: Salary, راتب, Pay, أجر
- طعام: Food, أكل, مطعم, Groceries, Restaurant, Cafe
- مواصلات: Transport, Taxi, Uber, Careem, بنزين, مواصلات
- استثمار: Gold, ذهب, Silver, فضة, Crypto, Bitcoin, USDT, BTC, ETH
- إيجار: Rent, إيجار, سكن
- صحة: Medical, Health, Doctor, Pharmacy, صحة, دكتور, دواء
- فواتير: Bills, Utilities, Internet, كهرباء, ماء, هاتف
- سفر: Travel, Trip, سفر, رحلة, طيران, Hotel, Airbnb
- ترفيه: Entertainment, ترفيه, سينما, Gaming, Gym, Sport
- تسوق: Shopping, Clothes, ملابس, Outfit

اسأل عن هذه الأنماط فقط:
- أسماء أشخاص مجردة → "هل هذا دين أعطيته؟ أم مصروف عادي؟"
- "Lending" أو "قرض" + اسم → "هل أعطيت هذا الشخص قرضاً؟"
- اختصارات أو كلمات غامضة → "ما هو هذا تحديداً؟"
- Commission, Award, Tips, Bonus → "هل هذا دخل من عملك؟"
- Donation, زكاة, صدقة → "كيف تريد تصنيف هذا؟"
- أمانة أو Deposit من شخص → "هل هذه أموال تحتفظ بها لشخص آخر؟"
- أي تبادل مالي بين أشخاص غير واضح → "دين أم مصروف؟"

قواعد الأسئلة:
- لا تولد أكثر من 8 أسئلة
- الأسئلة بالعربي دائماً
- كل سؤال له خيارات واضحة
- اذكر مثالاً حقيقياً من بيانات الملف في حقل context
- اقترح خياراً افتراضياً معقولاً

أرجع JSON فقط بلا أي كلام إضافي:

{
  "headers": [],
  "data_start_row": 1,
  "detected_columns": {
    "date": 0, "amount": 1,
    "type": null, "description": null, "category": null
  },
  "amount_behavior": "signed",
  "type_column_income_value": null,
  "type_column_expense_value": null,
  "income_column_index": null,
  "expense_column_index": null,
  "unique_categories": [],
  "ambiguous_items": [
    {
      "id": "q1",
      "type": "category",
      "category_name": "اسم الكاتيغوري من الملف",
      "question": "سؤال واضح بالعربي",
      "context": "مثال حقيقي من بيانات الملف",
      "options": [
        "مصروف شخصي عادي",
        "دين أعطيته لشخص",
        "تبرع أو هبة",
        "غير ذلك"
      ],
      "default_option": "مصروف شخصي عادي"
    }
  ],
  "notes": ""
}
''';
  }

  static String _buildClassificationPrompt({
    required FileAnalysis analysis,
    required Map<String, String> decisionsMap,
    required String rowsText,
  }) {
    final decisionsText = decisionsMap.isEmpty
        ? 'لا توجد قرارات خاصة.'
        : decisionsMap.entries
              .map((e) => '- "${e.key}" → ${e.value}')
              .join('\n');

    final amountGuide = switch (analysis.amountBehavior) {
      'signed' =>
        'المبلغ موجب = دخل، سالب = مصروف. استخدم القيمة المطلقة دائماً.',
      'type_column' =>
        'عمود النوع يحتوي: "${analysis.typeColumnIncomeValue}" = دخل، '
            '"${analysis.typeColumnExpenseValue}" = مصروف.',
      'two_columns' =>
        'عمود الدخل: ${analysis.incomeColumnIndex}، '
            'عمود المصروف: ${analysis.expenseColumnIndex}. '
            'خذ العمود غير الفارغ.',
      _ => 'حدد النوع من السياق.',
    };

    return '''
Classify financial rows. JSON only, no explanation.

COLS: date=${analysis.detectedColumns['date']} amount=${analysis.detectedColumns['amount']} category=${analysis.detectedColumns['category']} desc=${analysis.detectedColumns['description'] ?? 'none'} type=${analysis.detectedColumns['type'] ?? 'none'}
AMOUNT: $amountGuide
DECISIONS: $decisionsText

TYPES:
transaction → category: salary|freelance|food|transport|rent|bills|health|family|travel|entertainment|other
  salary:راتب,Pay | freelance:Commission,Bonus,Tips | food:طعام,مطعم,بقالة | transport:تاكسي,بنزين,Uber | rent:إيجار | bills:فواتير,كهرباء,انترنت | health:دكتور,دواء | family:أهل,عيلة | travel:سفر,طيران | entertainment:ترفيه,سينما | other:anything_else
asset_transaction → gold(XAU,ذهب,gram) silver(XAG,فضة,gram) crypto(USDT,BTC,ETH,USDT) | negative/expense=buy positive/income=sell | quantity+price from desc else null
debt → money given to person | amount positive | person_name from category/desc
amanah → money held for person | amount positive | person_name from desc
unclear → only truly missing/contradictory data; never for user decisions

DATA:
$rowsText

{"transactions":[{"date":"YYYY-MM-DD","amount":0.0,"type":"income|expense","category":"","description":""}],"asset_transactions":[{"date":"YYYY-MM-DD","asset_type":"gold|silver|crypto","transaction_type":"buy|sell","quantity":0.0,"price_per_unit":0.0,"unit":"gram|USDT","description":""}],"debts":[{"date":"YYYY-MM-DD","person_name":"","amount":0.0,"notes":""}],"amanahs":[{"date":"YYYY-MM-DD","person_name":"","amount":0.0,"notes":""}],"unclear":[{"row_index":0,"original_data":"","reason":""}]}
''';
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PRIVATE — GROQ HTTP
  // ────────────────────────────────────────────────────────────────────────────

  static Future<String> _callGemini(
    String prompt,
    String apiKey, {
    int retryCount = 0,
  }) async {
    const url = 'https://api.groq.com/openai/v1/chat/completions';

    try {
      print('=== [Groq API] Sending request (Attempt ${retryCount + 1}) ===');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': _groqModel,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.1,
              'response_format': {'type': 'json_object'},
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 429 || response.statusCode == 503) {
        if (retryCount >= 4) {
          throw Exception(
            'Groq: الخادم مشغول أو تم تجاوز الحد الأقصى للطلبات (${response.statusCode}). يرجى المحاولة لاحقاً.',
          );
        }
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '10') ?? 10;
        final backoff = (retryAfter * (1 << retryCount)).clamp(10, 120);
        print(
          '=== [Groq API] Rate limited (${response.statusCode}). Retrying in $backoff seconds... ===',
        );
        await Future.delayed(Duration(seconds: backoff));
        return _callGemini(prompt, apiKey, retryCount: retryCount + 1);
      }

      print(
        '=== [Groq API] Response received (Status: ${response.statusCode}) ===',
      );

      if (response.statusCode != 200) {
        String errorMsg = 'خطأ ${response.statusCode}';
        try {
          final errData = jsonDecode(response.body) as Map<String, dynamic>;
          final err = errData['error'];
          if (err != null) {
            errorMsg = err['message']?.toString() ?? errorMsg;
          }
        } catch (_) {}
        throw Exception('Groq: $errorMsg');
      }

      final Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        throw Exception('Groq أرجع استجابة غير صالحة (ليست JSON).');
      }

      if (data.containsKey('error')) {
        final err = data['error'];
        throw Exception('Groq: ${err['message'] ?? 'خطأ غير معروف'}');
      }

      final choices = data['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception('Groq لم يُرجع نتائج (choices فارغة أو null).');
      }

      final text =
          (choices[0] as Map<String, dynamic>)['message']?['content']
              ?.toString();
      if (text == null || text.isEmpty) {
        throw Exception('Groq: content = null أو فارغ في الاستجابة.');
      }

      return text;
    } on TimeoutException {
      throw Exception(
        'انتهت مهلة الاتصال بـ Groq (60 ثانية). الخادم مزدحم أو الإنترنت ضعيف.',
      );
    } on SocketException {
      throw Exception('لا يوجد اتصال بالإنترنت. تحقق من شبكتك وحاول مجدداً.');
    } catch (e) {
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // PRIVATE — HELPERS
  // ────────────────────────────────────────────────────────────────────────────

  static String _cleanJson(String text) {
    String clean = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = clean.indexOf('{');
    final end = clean.lastIndexOf('}');
    if (start == -1 || end == -1) {
      throw Exception('لم يُرجع Gemini استجابة JSON صالحة.');
    }
    return clean.substring(start, end + 1);
  }

  static Map<String, String> _buildDecisionsMap(
    FileAnalysis analysis,
    List<UserAnswer> userAnswers,
  ) {
    final map = <String, String>{};
    for (final answer in userAnswers) {
      try {
        final item = analysis.ambiguousItems.firstWhere(
          (i) => i.id == answer.ambiguousItemId,
        );
        map[item.categoryName] = answer.customText ?? answer.chosenOption;
      } catch (_) {
        // item غير موجود → تجاهل
      }
    }
    return map;
  }

  static List<String> _extractUniqueCategories(List<List<String>> rows) {
    final categories = <String>{};
    // نتجاهل أول صفين (headers محتملة)
    for (final row in rows.skip(2)) {
      // نجرّب كل عمود غير فارغ كـ category مرشح
      for (final cell in row) {
        final trimmed = cell.trim();
        if (trimmed.isNotEmpty &&
            !trimmed.startsWith('=') &&
            !RegExp(r'^\d').hasMatch(trimmed) && // لا نأخذ أرقاماً
            trimmed.length > 1 &&
            trimmed.length < 50) {
          // filter تواريخ YYYY-MM-DD
          if (!RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(trimmed)) {
            categories.add(trimmed);
          }
        }
      }
    }
    return categories.take(50).toList(); // نحدد بـ 50 كاتيغوري كحد أقصى
  }
}
