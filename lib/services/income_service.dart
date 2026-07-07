import 'package:smartcache/models/income.dart';
import 'package:smartcache/services/local_storage_service.dart';

class IncomeService {
  IncomeService();

  /// Get all income records from Hive, with optional filters.
  Future<List<Income>> getIncome({
    String? category,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var incomes = LocalStorageService.incomesBox.values.toList();

    if (category != null) {
      incomes = incomes.where((i) => i.category == category).toList();
    }
    if (startDate != null) {
      incomes = incomes
          .where(
            (i) =>
                i.incomeDate.isAfter(startDate) ||
                i.incomeDate.isAtSameMomentAs(startDate),
          )
          .toList();
    }
    if (endDate != null) {
      incomes = incomes
          .where(
            (i) =>
                i.incomeDate.isBefore(endDate) ||
                i.incomeDate.isAtSameMomentAs(endDate),
          )
          .toList();
    }

    incomes.sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
    return incomes;
  }

  /// Create a new income record and store in Hive.
  Future<Income?> createIncome({
    required String category,
    required double amount,
    required String note,
    String? paymentMethod,
    required DateTime incomeDate,
  }) async {
    final id = 'INC_${DateTime.now().millisecondsSinceEpoch}';
    final newIncome = Income(
      id: id,
      userId: '',
      category: category,
      amount: amount,
      note: note,
      paymentMethod: paymentMethod ?? '',
      incomeDate: incomeDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await LocalStorageService.incomesBox.put(id, newIncome);
    return newIncome;
  }

  /// Update an existing income record in Hive.
  Future<Income?> updateIncome({
    required String id,
    String? category,
    double? amount,
    String? note,
    DateTime? incomeDate,
  }) async {
    final existing = LocalStorageService.incomesBox.get(id);
    if (existing == null) return null;

    final updated = existing.copyWith(
      category: category,
      amount: amount,
      note: note,
      incomeDate: incomeDate,
      updatedAt: DateTime.now(),
    );
    await LocalStorageService.incomesBox.put(id, updated);
    return updated;
  }

  /// Delete an income record from Hive.
  Future<bool> deleteIncome(String id) async {
    await LocalStorageService.incomesBox.delete(id);
    return true;
  }

  /// Clear all cached income records.
  Future<void> clearCache() async {
    await LocalStorageService.incomesBox.clear();
  }

  double calculateBalance({
    required double totalIncome,
    required double totalExpenses,
  }) {
    return totalIncome - totalExpenses;
  }
}
