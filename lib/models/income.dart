import 'package:hive/hive.dart';

part 'income.g.dart';

@HiveType(typeId: 3)
class Income {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String category;
  @HiveField(3)
  final double amount;
  @HiveField(4)
  final String note;
  @HiveField(5)
  final String paymentMethod;
  @HiveField(6)
  final DateTime incomeDate;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;
  @HiveField(9)
  final bool isRecurring;
  @HiveField(10)
  final String? recurrenceInterval;
  @HiveField(11)
  final DateTime? nextRecurrenceDate;

  Income({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.note,
    required this.paymentMethod,
    required this.incomeDate,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.nextRecurrenceDate,
  });

  factory Income.fromJson(Map<String, dynamic> json) => Income(
    id: json['id'].toString(),
    userId: json['user_id']?.toString() ?? '',
    category: json['category'] as String? ?? json['source'] as String? ?? '',
    amount: double.tryParse(json['amount'].toString()) ?? 0.0,
    note: json['note'] as String? ?? '',
    paymentMethod: json['payment_method'] as String? ?? '',
    incomeDate: DateTime.parse(json['income_date'] as String),
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'] as String)
        : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : DateTime.now(),
    isRecurring: json['is_recurring'] as bool? ?? false,
    recurrenceInterval: json['recurrence_interval'] as String?,
    nextRecurrenceDate: json['next_recurrence_date'] != null 
        ? DateTime.parse(json['next_recurrence_date'] as String) 
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'category': category,
    'amount': amount,
    'note': note,
    'payment_method': paymentMethod,
    'income_date': incomeDate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_recurring': isRecurring,
    'recurrence_interval': recurrenceInterval,
    'next_recurrence_date': nextRecurrenceDate?.toIso8601String(),
  };

  Income copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    String? note,
    String? paymentMethod,
    DateTime? incomeDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurrenceInterval,
    DateTime? nextRecurrenceDate,
  }) => Income(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    note: note ?? this.note,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    incomeDate: incomeDate ?? this.incomeDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isRecurring: isRecurring ?? this.isRecurring,
    recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
    nextRecurrenceDate: nextRecurrenceDate ?? this.nextRecurrenceDate,
  );
}
