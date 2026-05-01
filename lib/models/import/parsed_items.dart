// DTOs مؤقتة بدون Hive — تُستخدم للعرض ثم تُحوَّل لـ Hive models عند الحفظ

class ParsedTransaction {
  final String? date;
  final double amount;

  /// 'income' | 'expense'
  final String type;

  /// مثل: salary | food | transport | ...
  final String category;
  final String description;

  const ParsedTransaction({
    this.date,
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
  });

  factory ParsedTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedTransaction(
      date: json['date'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'expense',
      category: json['category'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
    );
  }
}

class ParsedAssetTransaction {
  final String? date;

  /// 'gold' | 'silver' | 'crypto'
  final String assetType;

  /// 'buy' | 'sell'
  final String transactionType;
  final double? quantity;
  final double? pricePerUnit;

  /// 'gram' | 'USDT'
  final String unit;
  final String description;

  const ParsedAssetTransaction({
    this.date,
    required this.assetType,
    required this.transactionType,
    this.quantity,
    this.pricePerUnit,
    required this.unit,
    required this.description,
  });

  factory ParsedAssetTransaction.fromJson(Map<String, dynamic> json) {
    return ParsedAssetTransaction(
      date: json['date'] as String?,
      assetType: json['asset_type'] as String? ?? 'gold',
      transactionType: json['transaction_type'] as String? ?? 'buy',
      quantity: (json['quantity'] as num?)?.toDouble(),
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble(),
      unit: json['unit'] as String? ?? 'gram',
      description: json['description'] as String? ?? '',
    );
  }
}

class ParsedDebt {
  final String? date;
  final String personName;
  final double amount;
  final String notes;

  const ParsedDebt({
    this.date,
    required this.personName,
    required this.amount,
    required this.notes,
  });

  factory ParsedDebt.fromJson(Map<String, dynamic> json) {
    return ParsedDebt(
      date: json['date'] as String?,
      personName: json['person_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class ParsedAmanah {
  final String? date;
  final String personName;
  final double amount;
  final String notes;

  const ParsedAmanah({
    this.date,
    required this.personName,
    required this.amount,
    required this.notes,
  });

  factory ParsedAmanah.fromJson(Map<String, dynamic> json) {
    return ParsedAmanah(
      date: json['date'] as String?,
      personName: json['person_name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }
}

class UnclearRow {
  final int rowIndex;
  final String originalData;
  final String reason;

  /// يُعيَّن يدوياً من المستخدم في شاشة المراجعة
  String? manualClassification;

  UnclearRow({
    required this.rowIndex,
    required this.originalData,
    required this.reason,
    this.manualClassification,
  });

  factory UnclearRow.fromJson(Map<String, dynamic> json) {
    return UnclearRow(
      rowIndex: json['row_index'] as int? ?? 0,
      originalData: json['original_data'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
    );
  }
}
