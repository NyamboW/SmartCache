import 'package:smartcache/models/budget.dart';
import 'package:smartcache/services/local_storage_service.dart';

class BudgetService {
  BudgetService();

  /// Get all budgets from Hive, with optional month/year filter.
  Future<List<Budget>> getBudgets({int? month, int? year}) async {
    var budgets = LocalStorageService.budgetsBox.values.toList();

    if (month != null) {
      budgets = budgets.where((b) => b.month == month).toList();
    }
    if (year != null) {
      budgets = budgets.where((b) => b.year == year).toList();
    }

    return budgets;
  }

  /// Create or update a budget in Hive.
  /// If a budget for the same category/month/year exists, it is replaced.
  Future<Budget?> createOrUpdateBudget({
    required String category,
    required double limitAmount,
    required int month,
    required int year,
  }) async {
    // Check if a budget already exists for this category/month/year
    final existing = LocalStorageService.budgetsBox.values.where(
      (b) => b.category == category && b.month == month && b.year == year,
    );

    final String id;
    final DateTime createdAt;

    if (existing.isNotEmpty) {
      id = existing.first.id;
      createdAt = existing.first.createdAt;
    } else {
      id = 'BUD_${DateTime.now().millisecondsSinceEpoch}';
      createdAt = DateTime.now();
    }

    final budget = Budget(
      id: id,
      userId: '',
      category: category,
      limitAmount: limitAmount,
      month: month,
      year: year,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );

    await LocalStorageService.budgetsBox.put(id, budget);
    return budget;
  }

  /// Delete a budget from Hive.
  Future<bool> deleteBudget(String id) async {
    await LocalStorageService.budgetsBox.delete(id);
    return true;
  }
}
