import 'package:smartcache/models/income.dart';
import 'package:smartcache/services/local_storage_service.dart';

class IncomeService {
  IncomeService();

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

  /// Process recurring incomes, generating new ones if their date has passed
  Future<void> processRecurrences() async {
    final now = DateTime.now();
    final incomes = LocalStorageService.incomesBox.values.toList();
    
    for (var income in incomes) {
      if (income.isRecurring && income.nextRecurrenceDate != null && income.recurrenceInterval != null) {
        var currentTemplate = income;
        var nextDate = currentTemplate.nextRecurrenceDate!;
        
        while (nextDate.isBefore(now) || nextDate.isAtSameMomentAs(now)) {
          final newNextDate = _calculateNextDate(nextDate, currentTemplate.recurrenceInterval!);
          
          // Mark current template as NOT recurring
          final updatedTemplate = currentTemplate.copyWith(
            isRecurring: false,
            nextRecurrenceDate: null,
          );
          await LocalStorageService.incomesBox.put(updatedTemplate.id, updatedTemplate);
          
          // Create the new child which becomes the active recurring template
          final newId = 'INC_${DateTime.now().microsecondsSinceEpoch}';
          final newIncome = currentTemplate.copyWith(
            id: newId,
            incomeDate: nextDate,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isRecurring: true,
            recurrenceInterval: currentTemplate.recurrenceInterval,
            nextRecurrenceDate: newNextDate,
          );
          await LocalStorageService.incomesBox.put(newId, newIncome);
          
          currentTemplate = newIncome;
          if (newNextDate == null) break;
          nextDate = newNextDate;
        }
      }
    }
  }

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
    bool isRecurring = false,
    String? recurrenceInterval,
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
      isRecurring: isRecurring,
      recurrenceInterval: recurrenceInterval,
      nextRecurrenceDate: isRecurring && recurrenceInterval != null 
          ? _calculateNextDate(incomeDate, recurrenceInterval)
          : null,
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
    bool? isRecurring,
    String? recurrenceInterval,
  }) async {
    final existing = LocalStorageService.incomesBox.get(id);
    if (existing == null) return null;

    DateTime? nextRecurrence;
    if (isRecurring != null) {
      if (isRecurring && recurrenceInterval != null) {
        nextRecurrence = _calculateNextDate(incomeDate ?? existing.incomeDate, recurrenceInterval);
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
      incomeDate: incomeDate,
      updatedAt: DateTime.now(),
      isRecurring: isRecurring,
      recurrenceInterval: recurrenceInterval,
      nextRecurrenceDate: nextRecurrence,
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
