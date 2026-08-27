import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 1)
class Expense {
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
  final DateTime expenseDate;
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

  Expense({
    required this.id,
    required this.userId,
    required this.category,
    required this.amount,
    required this.note,
    required this.paymentMethod,
    required this.expenseDate,
    required this.createdAt,
    required this.updatedAt,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.nextRecurrenceDate,
  });

  factory Expense.fromJson(Map<String, dynamic> json) => Expense(
    id: json['id'].toString(),
    userId: json['user_id'].toString(),
    category: json['category'] as String,
    amount: double.parse(json['amount'].toString()),
    note: json['note'] as String? ?? '',
    paymentMethod: json['payment_method'] as String,
    expenseDate: DateTime.parse(json['expense_date'] as String),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
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
    'expense_date': expenseDate.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'is_recurring': isRecurring,
    'recurrence_interval': recurrenceInterval,
    'next_recurrence_date': nextRecurrenceDate?.toIso8601String(),
  };

  Expense copyWith({
    String? id,
    String? userId,
    String? category,
    double? amount,
    String? note,
    String? paymentMethod,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRecurring,
    String? recurrenceInterval,
    DateTime? nextRecurrenceDate,
  }) => Expense(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    note: note ?? this.note,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    expenseDate: expenseDate ?? this.expenseDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isRecurring: isRecurring ?? this.isRecurring,
    recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
    nextRecurrenceDate: nextRecurrenceDate ?? this.nextRecurrenceDate,
  );
}
