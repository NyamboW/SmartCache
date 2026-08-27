import 'package:smartcache/models/expense.dart';
import 'package:smartcache/services/local_storage_service.dart';

class ExpenseService {
  ExpenseService();

  DateTime? _calculateNextDate(DateTime current, String interval) {
    switch (interval.toLowerCase()) {
      case 'daily':
        return DateTime(current.year, current.month, current.day + 1);
      case 'weekly':
        return DateTime(current.year, current.month, current.day + 7);
      case 'monthly':
        return DateTime(current.year, current.month + 1, current.day);
      case 'yearly':
        return DateTime(current.year + 1, current.month, current.day);
      default:
        return null;
    }
  }

  /// Process recurring expenses, generating new ones if their date has passed
  Future<void> processRecurrences() async {
    final now = DateTime.now();
    final expenses = LocalStorageService.expensesBox.values.toList();
    
    for (var expense in expenses) {
      if (expense.isRecurring && expense.nextRecurrenceDate != null && expense.recurrenceInterval != null) {
        var currentTemplate = expense;
        var nextDate = currentTemplate.nextRecurrenceDate!;
        
        while (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
          final newNextDate = _calculateNextDate(nextDate, currentTemplate.recurrenceInterval!);
          
          // Mark current template as NOT recurring
          final updatedTemplate = currentTemplate.copyWith(
            isRecurring: false,
            nextRecurrenceDate: null,
          );
          await LocalStorageService.expensesBox.put(updatedTemplate.id, updatedTemplate);
          
          // Create the new child which becomes the active recurring template
          final newId = 'EXP_${DateTime.now().microsecondsSinceEpoch}';
          final newExpense = currentTemplate.copyWith(
            id: newId,
            expenseDate: nextDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isRecurring: true,
            recurrenceInterval: currentTemplate.recurrenceInterval,
            nextRecurrenceDate: newNextDate,
          );
          await LocalStorageService.expensesBox.put(newId, newExpense);
          
          currentTemplate = newExpense;
          if (newNextDate == null) break;
          nextDate = newNextDate;
        }
      }
    }
  }

  /// Get all expenses from Hive, with optional filters.
  Future<List<Expense>> getExpenses({
    String? category,
    String? paymentMethod,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var expenses = LocalStorageService.expensesBox.values.toList();

    if (category != null) {
      expenses = expenses.where((e) => e.category == category).toList();
    }
    if (paymentMethod != null) {
      expenses = expenses
          .where((e) => e.paymentMethod == paymentMethod)
          .toList();
    }
    if (startDate != null) {
      expenses = expenses
          .where(
            (e) =>
                e.expenseDate.isAfter(startDate) ||
                e.expenseDate.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      expenses = expenses
          .where(
            (e) =>
                e.expenseDate.isBefore(endDate) ||
                e.expenseDate.isAtSameMomentAs(endDate),
          )
          .toList();
    }

    // Sort by date DESC
    expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
    return expenses;
  }

  /// Create a new expense and store in Hive.
  Future<Expense?> createExpense({
    required String category,
    required double amount,
    required String note,
    required String paymentMethod,
    required DateTime expenseDate,
    bool isRecurring = false,
    String? recurrenceInterval,
  }) async {
    final id = 'EXP_${DateTime.now().millisecondsSinceEpoch}';
    final newExpense = Expense(
      id: id,
      userId: '',
      category: category,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isRecurring: isRecurring,
      recurrenceInterval: recurrenceInterval,
      nextRecurrenceDate: isRecurring && recurrenceInterval != null 
          ? _calculateNextDate(expenseDate, recurrenceInterval)
          : null,
    );

    await LocalStorageService.expensesBox.put(id, newExpense);
    return newExpense;
  }

  /// Update an existing expense in Hive.
  Future<Expense?> updateExpense({
    required String id,
    String? category,
    double? amount,
    String? note,
    String? paymentMethod,
    DateTime? expenseDate,
    bool? isRecurring,
    String? recurrenceInterval,
  }) async {
    final existing = LocalStorageService.expensesBox.get(id);
    if (existing == null) return null;

    DateTime? nextRecurrence;
    if (isRecurring != null) {
      if (isRecurring && recurrenceInterval != null) {
        nextRecurrence = _calculateNextDate(expenseDate ?? existing.expenseDate, recurrenceInterval);
      } else if (!isRecurring) {
        nextRecurrence = null;
      }
    } else {
      nextRecurrence = existing.nextRecurrenceDate;
    }

    final updated = existing.copyWith(
      category: category,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      updatedAt: DateTime.now(),
      isRecurring: isRecurring,
      recurrenceInterval: recurrenceInterval,
      nextRecurrenceDate: nextRecurrence,
    );
    await LocalStorageService.expensesBox.put(id, updated);
    return updated;
  }

  /// Delete an expense from Hive.
  Future<bool> deleteExpense(String id) async {
    await LocalStorageService.expensesBox.delete(id);
    return true;
  }

  /// Clear all cached expenses.
  Future<void> clearCache() async {
    await LocalStorageService.expensesBox.clear();
  }
}
