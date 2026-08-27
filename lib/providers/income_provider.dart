import 'package:flutter/foundation.dart';
import 'package:smartcache/models/income.dart';
import 'package:smartcache/services/income_service.dart';

class IncomeProvider with ChangeNotifier {
  final IncomeService _incomeService;
  List<Income> _incomes = [];
  bool _isLoading = false;
  String? _errorMessage;

  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  IncomeProvider(this._incomeService);

  List<Income> get incomes => _incomes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  // FILTERED LIST
  List<Income> get filteredIncomes {
    var filtered = _incomes;

    if (_selectedCategory != null) {
      filtered = filtered
          .where((i) => i.category == _selectedCategory)
          .toList();
    }

    if (_startDate != null) {
      filtered = filtered
          .where(
            (i) =>
                i.incomeDate.isAfter(_startDate!) ||
                i.incomeDate.isAtSameMomentAs(_startDate!),
          )
          .toList();
    }

    if (_endDate != null) {
      filtered = filtered
          .where(
            (i) =>
                i.incomeDate.isBefore(_endDate!) ||
                i.incomeDate.isAtSameMomentAs(_endDate!),
          )
          .toList();
    }

    return filtered..sort((a, b) => b.incomeDate.compareTo(a.incomeDate));
  }

  // TOTALS
  double get totalIncome =>
      filteredIncomes.fold(0.0, (sum, income) => sum + income.amount);

  Map<String, double> get categoryTotals {
    final totals = <String, double>{};
    for (var income in filteredIncomes) {
      totals[income.category] = (totals[income.category] ?? 0) + income.amount;
    }
    return totals;
  }

  // LOAD INCOME LIST
  Future<void> loadIncomes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _incomeService.processRecurrences();
      _incomes = await _incomeService.getIncome();
    } catch (e) {
      _errorMessage = 'Failed to load incomes';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ADD INCOME
  Future<bool> addIncome({
    required String category,
    required double amount,
    required String note,
    required DateTime incomeDate,
    bool isRecurring = false,
    String? recurrenceInterval,
  }) async {
    _errorMessage = null;

    try {
      final income = await _incomeService.createIncome(
        category: category,
        amount: amount,
        note: note,
        incomeDate: incomeDate,
        isRecurring: isRecurring,
        recurrenceInterval: recurrenceInterval,
      );

      if (income != null) {
        _incomes.add(income);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to create income';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // UPDATE INCOME
  Future<bool> updateIncome({
    required String id,
    String? category,
    double? amount,
    DateTime? incomeDate,
    String? note,
    bool? isRecurring,
    String? recurrenceInterval,
  }) async {
    _errorMessage = null;

    try {
      final updatedIncome = await _incomeService.updateIncome(
        id: id,
        category: category,
        amount: amount,
        incomeDate: incomeDate,
        note: note,
        isRecurring: isRecurring,
        recurrenceInterval: recurrenceInterval,
      );

      if (updatedIncome != null) {
        final index = _incomes.indexWhere((e) => e.id == id);
        if (index != -1) {
          _incomes[index] = updatedIncome;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = 'Failed to update income';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // DELETE INCOME
  Future<bool> deleteIncome(String id) async {
    _errorMessage = null;

    try {
      final success = await _incomeService.deleteIncome(id);

      if (success) {
        _incomes.removeWhere((i) => i.id == id);
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to delete income';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // FILTERS
  void setFilters({String? category, DateTime? startDate, DateTime? endDate}) {
    _selectedCategory = category;
    _startDate = startDate;
    _endDate = endDate;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = null;
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
