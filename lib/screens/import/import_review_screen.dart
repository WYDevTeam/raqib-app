import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../core/di/injection.dart';
import '../../features/dashboard/presentation/cubit/dashboard_cubit.dart';
import '../../features/debts_amanah/data/models/amanah_model.dart';
import '../../features/debts_amanah/data/models/debt_model.dart';
import '../../features/investments/data/models/asset_model.dart';
import '../../features/investments/data/models/asset_transaction_model.dart';
import '../../features/transactions/data/models/category_model.dart';
import '../../features/transactions/data/models/transaction_model.dart';
import '../../models/import/import_result.dart';
import '../../models/import/parsed_items.dart';

class ImportReviewScreen extends StatefulWidget {
  final ImportResult result;
  final String filePath;

  const ImportReviewScreen({
    super.key,
    required this.result,
    required this.filePath,
  });

  @override
  State<ImportReviewScreen> createState() => _ImportReviewScreenState();
}

class _ImportReviewScreenState extends State<ImportReviewScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isSaving = false;

  // قوائم مُعدَّلة (للـ unclear يمكن تغيير التصنيف)
  late final List<UnclearRow> _unclearRows;

  // خيارات التصنيف اليدوي
  static const _classificationOptions = [
    'معاملة عادية',
    'استثمار',
    'دين أعطيته',
    'أمانة عندي',
    'تجاهل',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _unclearRows = List.from(widget.result.unclear);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // SAVE LOGIC
  // ────────────────────────────────────────────────────────────────────────────

  Future<void> _saveAll() async {
    setState(() => _isSaving = true);

    try {
      const uuid = Uuid();
      final now = DateTime.now().millisecondsSinceEpoch;

      final txBox = Hive.box<TransactionModel>('transactions');
      final categoryBox = Hive.box<CategoryModel>('categories');
      final assetBox = Hive.box<AssetModel>('assets');
      final assetTxBox = Hive.box<AssetTransactionModel>('asset_transactions');
      final debtBox = Hive.box<DebtModel>('debts');
      final amanahBox = Hive.box<AmanahModel>('amanah');

      // ── 1. Transactions ───────────────────────────────────────────────────
      for (final parsed in widget.result.transactions) {
        final categoryId =
            await _resolveOrCreateCategory(parsed.category, categoryBox, uuid);
        final tx = TransactionModel(
          id: uuid.v4(),
          amount: parsed.amount.abs(),
          categoryId: categoryId,
          description: parsed.description,
          date: _parseDate(parsed.date) ?? DateTime.now(),
          isIncome: parsed.type == 'income',
          isRecurring: false,
        );
        await txBox.add(tx);
      }

      // ── 2. Asset Transactions ─────────────────────────────────────────────
      for (final parsed in widget.result.assetTransactions) {
        final assetId = await _resolveOrCreateAsset(
          parsed,
          assetBox,
          uuid,
          now,
        );

        final assetTx = AssetTransactionModel(
          id: uuid.v4(),
          assetId: assetId,
          isBuy: parsed.transactionType == 'buy',
          quantity: parsed.quantity ?? 0.0,
          pricePerUnit: parsed.pricePerUnit ?? 0.0,
          dateMs: _parseDate(parsed.date)?.millisecondsSinceEpoch ?? now,
          note: parsed.description,
        );
        await assetTxBox.add(assetTx);

        // تحديث الـ asset quantity و totalCost
        final asset = assetBox.values
            .where((a) => a.id == assetId)
            .firstOrNull;
        if (asset != null) {
          if (parsed.transactionType == 'buy') {
            asset.quantity += parsed.quantity ?? 0;
            asset.totalCost += (parsed.quantity ?? 0) * (parsed.pricePerUnit ?? 0);
          } else {
            asset.quantity = (asset.quantity - (parsed.quantity ?? 0))
                .clamp(0.0, double.infinity);
          }
          if (asset.isInBox) await asset.save();
        }
      }

      // ── 3. Debts ─────────────────────────────────────────────────────────
      for (final parsed in widget.result.debts) {
        final name = parsed.personName.trim();
        final existingDebt = debtBox.values
            .where((d) => d.personName.trim().toLowerCase() == name.toLowerCase())
            .firstOrNull;

        if (existingDebt != null) {
          String newNote = existingDebt.note;
          if (parsed.notes.isNotEmpty && !existingDebt.note.contains(parsed.notes)) {
             newNote = '${existingDebt.note} | ${parsed.notes}'.trim();
             if (newNote.startsWith('|')) newNote = newNote.substring(1).trim();
          }
          final updatedDebt = DebtModel(
            id: existingDebt.id,
            personName: existingDebt.personName,
            totalAmount: existingDebt.totalAmount + parsed.amount.abs(),
            paidAmount: existingDebt.paidAmount,
            givenDateMs: existingDebt.givenDateMs,
            dueDateMs: existingDebt.dueDateMs,
            note: newNote,
            isSettled: existingDebt.isSettled,
          );
          await debtBox.put(existingDebt.key, updatedDebt);
        } else {
          final debt = DebtModel(
            id: uuid.v4(),
            personName: name,
            totalAmount: parsed.amount.abs(),
            paidAmount: 0.0,
            givenDateMs: _parseDate(parsed.date)?.millisecondsSinceEpoch ?? now,
            note: parsed.notes,
          );
          await debtBox.add(debt);
        }
      }

      // ── 4. Amanahs ────────────────────────────────────────────────────────
      for (final parsed in widget.result.amanahs) {
        final name = parsed.personName.trim();
        final existingAmanah = amanahBox.values
            .where((a) => a.personName.trim().toLowerCase() == name.toLowerCase())
            .firstOrNull;

        if (existingAmanah != null) {
          String newNote = existingAmanah.note;
          if (parsed.notes.isNotEmpty && !existingAmanah.note.contains(parsed.notes)) {
             newNote = '${existingAmanah.note} | ${parsed.notes}'.trim();
             if (newNote.startsWith('|')) newNote = newNote.substring(1).trim();
          }
          final updatedAmanah = AmanahModel(
            id: existingAmanah.id,
            personName: existingAmanah.personName,
            amount: existingAmanah.amount + parsed.amount.abs(),
            receivedDateMs: existingAmanah.receivedDateMs,
            expectedReturnDateMs: existingAmanah.expectedReturnDateMs,
            note: newNote,
            isReturned: existingAmanah.isReturned,
            returnedAmount: existingAmanah.returnedAmount,
          );
          await amanahBox.put(existingAmanah.key, updatedAmanah);
        } else {
          final amanah = AmanahModel(
            id: uuid.v4(),
            personName: name,
            amount: parsed.amount.abs(),
            receivedDateMs:
                _parseDate(parsed.date)?.millisecondsSinceEpoch ?? now,
            note: parsed.notes,
          );
          await amanahBox.add(amanah);
        }
      }

      // ── 5. تحديث Dashboard ────────────────────────────────────────────────
      sl<DashboardCubit>().refresh();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ تم حفظ ${widget.result.totalCount} عنصر بنجاح',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 3),
        ),
      );

      // أغلق كل شاشات الاستيراد
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'خطأ أثناء الحفظ: ${e.toString().replaceAll('Exception: ', '')}',
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Category resolution ───────────────────────────────────────────────────
  Future<String> _resolveOrCreateCategory(
    String categoryName,
    Box<CategoryModel> box,
    Uuid uuid,
  ) async {
    final translatedName = _arabicCategoryName(categoryName);
    // ابحث عن category موجودة بنفس الاسم (case-insensitive) باستخدام الاسم المترجم
    final existing = box.values
        .where((c) =>
            c.name.trim().toLowerCase() == translatedName.toLowerCase())
        .firstOrNull;

    if (existing != null) return existing.id;

    // أنشئ category جديدة بأيقونة ولون افتراضيين
    final newId = uuid.v4();
    final colorValue = _defaultColorForCategory(categoryName);
    final iconCodePoint = _defaultIconForCategory(categoryName);

    final newCategory = CategoryModel(
      id: newId,
      name: _arabicCategoryName(categoryName),
      iconCodePoint: iconCodePoint,
      colorValue: colorValue,
      typeValue: 0, // both
    );
    await box.add(newCategory);
    return newId;
  }

  // ── Asset resolution ──────────────────────────────────────────────────────
  Future<String> _resolveOrCreateAsset(
    ParsedAssetTransaction parsed,
    Box<AssetModel> box,
    Uuid uuid,
    int now,
  ) async {
    final typeName = _arabicAssetType(parsed.assetType);
    final existing = box.values
        .where((a) => a.type == parsed.assetType)
        .firstOrNull;

    if (existing != null) return existing.id;

    final newId = uuid.v4();
    final asset = AssetModel(
      id: newId,
      name: typeName,
      type: parsed.assetType,
      symbol: _symbolForAsset(parsed.assetType),
      quantity: 0.0,
      unit: parsed.unit,
      totalCost: 0.0,
      currentValuePerUnit: 0.0,
      createdAtMs: now,
    );
    await box.add(asset);
    return newId;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  int _defaultColorForCategory(String name) {
    final map = {
      'salary': 0xFF4CAF50,
      'freelance': 0xFF8BC34A,
      'food': 0xFFFF9800,
      'transport': 0xFF2196F3,
      'rent': 0xFF9C27B0,
      'bills': 0xFF607D8B,
      'health': 0xFFF44336,
      'family': 0xFFE91E63,
      'travel': 0xFF00BCD4,
      'entertainment': 0xFFFF5722,
      'other': 0xFF9E9E9E,
    };
    return map[name.toLowerCase()] ?? 0xFF9E9E9E;
  }

  int _defaultIconForCategory(String name) {
    final map = {
      'salary': 0xe6e2, // work
      'freelance': 0xe8a0, // laptop
      'food': 0xe56c, // restaurant
      'transport': 0xe531, // directions_car
      'rent': 0xe88a, // home
      'bills': 0xe8f6, // receipt
      'health': 0xe548, // local_hospital
      'family': 0xe7fb, // group
      'travel': 0xe7ef, // flight
      'entertainment': 0xe87e, // sports_esports
      'other': 0xe574, // more_horiz
    };
    return map[name.toLowerCase()] ?? 0xe574;
  }

  String _arabicCategoryName(String name) {
    final map = {
      'salary': 'راتب',
      'freelance': 'عمل حر',
      'food': 'طعام',
      'transport': 'مواصلات',
      'rent': 'إيجار',
      'bills': 'فواتير',
      'health': 'صحة',
      'family': 'عائلة',
      'travel': 'سفر',
      'entertainment': 'ترفيه',
      'other': 'أخرى',
    };
    return map[name.toLowerCase()] ?? name;
  }

  String _arabicAssetType(String type) {
    const map = {
      'gold': 'ذهب',
      'silver': 'فضة',
      'crypto': 'كريبتو',
    };
    return map[type] ?? type;
  }

  String _symbolForAsset(String type) {
    const map = {
      'gold': 'XAU',
      'silver': 'XAG',
      'crypto': 'BTCUSDT',
    };
    return map[type] ?? '';
  }

  // ────────────────────────────────────────────────────────────────────────────
  // BUILD
  // ────────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final r = widget.result;
    final totalSaving = r.totalCount;

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
          'راجع النتائج',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          tabs: [
            Tab(text: 'معاملات (${r.transactions.length})'),
            Tab(text: 'استثمارات (${r.assetTransactions.length})'),
            Tab(text: 'ديون (${r.debts.length})'),
            Tab(text: 'أمانات (${r.amanahs.length})'),
            Tab(text: 'غير واضح (${_unclearRows.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TransactionsTab(items: r.transactions),
                _AssetTransactionsTab(items: r.assetTransactions),
                _DebtsTab(items: r.debts),
                _AmanahsTab(items: r.amanahs),
                _UnclearTab(
                  items: _unclearRows,
                  options: _classificationOptions,
                  onChanged: (i, val) {
                    setState(() => _unclearRows[i].manualClassification = val);
                  },
                ),
              ],
            ),
          ),
          // ── زر الحفظ ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E1A),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: _isSaving || totalSaving == 0 ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        totalSaving > 0
                            ? 'حفظ الكل ($totalSaving عنصر)'
                            : 'لا توجد بيانات للحفظ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// TAB WIDGETS
// ────────────────────────────────────────────────────────────────────────────

class _TransactionsTab extends StatelessWidget {
  final List<ParsedTransaction> items;
  const _TransactionsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _emptyState('لا توجد معاملات');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final t = items[i];
        final isIncome = t.type == 'income';
        return _ReviewCard(
          icon: isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          iconColor: isIncome ? Colors.green : Colors.red,
          title: t.description.isNotEmpty ? t.description : t.category,
          subtitle: '${t.category} • ${t.date ?? 'بدون تاريخ'}',
          trailing: '${isIncome ? '+' : '-'}${t.amount.toStringAsFixed(2)}',
          trailingColor: isIncome ? Colors.green : Colors.red,
        );
      },
    );
  }
}

class _AssetTransactionsTab extends StatelessWidget {
  final List<ParsedAssetTransaction> items;
  const _AssetTransactionsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _emptyState('لا توجد استثمارات');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final t = items[i];
        final isBuy = t.transactionType == 'buy';
        final assetIcon = switch (t.assetType) {
          'gold' => Icons.monetization_on,
          'silver' => Icons.circle,
          _ => Icons.currency_bitcoin,
        };
        return _ReviewCard(
          icon: assetIcon,
          iconColor: isBuy ? Colors.orange : Colors.blue,
          title: '${t.assetType} • ${isBuy ? 'شراء' : 'بيع'}',
          subtitle:
              '${t.quantity ?? '--'} ${t.unit} • ${t.date ?? 'بدون تاريخ'}',
          trailing: t.pricePerUnit != null
              ? '@ ${t.pricePerUnit!.toStringAsFixed(2)}'
              : '--',
          trailingColor: Colors.white60,
        );
      },
    );
  }
}

class _DebtsTab extends StatelessWidget {
  final List<ParsedDebt> items;
  const _DebtsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _emptyState('لا توجد ديون');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final d = items[i];
        return _ReviewCard(
          icon: Icons.person_outline,
          iconColor: Colors.amber,
          title: d.personName.isNotEmpty ? d.personName : 'شخص غير معروف',
          subtitle: d.date ?? 'بدون تاريخ',
          trailing: d.amount.toStringAsFixed(2),
          trailingColor: Colors.amber,
        );
      },
    );
  }
}

class _AmanahsTab extends StatelessWidget {
  final List<ParsedAmanah> items;
  const _AmanahsTab({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _emptyState('لا توجد أمانات');
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final a = items[i];
        return _ReviewCard(
          icon: Icons.security,
          iconColor: Colors.purple,
          title: a.personName.isNotEmpty ? a.personName : 'شخص غير معروف',
          subtitle: a.date ?? 'بدون تاريخ',
          trailing: a.amount.toStringAsFixed(2),
          trailingColor: Colors.purple,
        );
      },
    );
  }
}

class _UnclearTab extends StatelessWidget {
  final List<UnclearRow> items;
  final List<String> options;
  final void Function(int index, String value) onChanged;

  const _UnclearTab({
    required this.items,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _emptyState('ممتاز! كل البيانات واضحة ✓');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final row = items[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'صف ${row.rowIndex + 1}',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontFamily: 'Cairo',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                row.originalData,
                style: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Cairo',
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                row.reason,
                style: const TextStyle(
                  color: Colors.white38,
                  fontFamily: 'Cairo',
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: row.manualClassification,
                hint: const Text(
                  'صنّف هذا الصف يدوياً',
                  style: TextStyle(
                      color: Colors.white38, fontFamily: 'Cairo', fontSize: 13),
                ),
                dropdownColor: const Color(0xFF1A1F30),
                style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.white24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                ),
                items: options
                    .map((o) => DropdownMenuItem(
                          value: o,
                          child: Text(o,
                              style: const TextStyle(fontFamily: 'Cairo')),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) onChanged(i, val);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ────────────────────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String trailing;
  final Color trailingColor;

  const _ReviewCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontFamily: 'Cairo',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            trailing,
            style: TextStyle(
              color: trailingColor,
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _emptyState(String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inbox_rounded, size: 56, color: Colors.white24),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            color: Colors.white38,
            fontFamily: 'Cairo',
            fontSize: 15,
          ),
        ),
      ],
    ),
  );
}
