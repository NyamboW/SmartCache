import 'package:smartcache/models/expense.dart';
import 'package:smartcache/services/local_storage_service.dart';

class ExpenseService {
  ExpenseService();

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
  }) async {
    final existing = LocalStorageService.expensesBox.get(id);
    if (existing == null) return null;

    final updated = existing.copyWith(
      category: category,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod,
      expenseDate: expenseDate,
      updatedAt: DateTime.now(),
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
