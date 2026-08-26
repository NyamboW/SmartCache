import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartcache/constants/cartegories.dart';
import 'package:smartcache/constants/income_categories.dart';

class CategoryProvider with ChangeNotifier {
  static const String _customExpenseKey = 'custom_expense_categories';
  static const String _customIncomeKey = 'custom_income_categories';

  List<String> _customExpenseCategories = [];
  List<String> _customIncomeCategories = [];

  List<String> get expenseCategories => [...ExpenseCategory.all, ..._customExpenseCategories];
  List<String> get incomeCategories => [...IncomeCategory.all, ..._customIncomeCategories];

  List<String> get customExpenseCategories => _customExpenseCategories;
  List<String> get customIncomeCategories => _customIncomeCategories;

  CategoryProvider() {
    _loadCustomCategories();
  }

  Future<void> _loadCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    _customExpenseCategories = prefs.getStringList(_customExpenseKey) ?? [];
    _customIncomeCategories = prefs.getStringList(_customIncomeKey) ?? [];
    notifyListeners();
  }

  Future<void> addCustomExpenseCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty || expenseCategories.contains(trimmed)) return;
    
    _customExpenseCategories.add(trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customExpenseKey, _customExpenseCategories);
    notifyListeners();
  }

  Future<void> removeCustomExpenseCategory(String category) async {
    if (_customExpenseCategories.contains(category)) {
      _customExpenseCategories.remove(category);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customExpenseKey, _customExpenseCategories);
      notifyListeners();
    }
  }

  Future<void> addCustomIncomeCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty || incomeCategories.contains(trimmed)) return;

    _customIncomeCategories.add(trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_customIncomeKey, _customIncomeCategories);
    notifyListeners();
  }

  Future<void> removeCustomIncomeCategory(String category) async {
    if (_customIncomeCategories.contains(category)) {
      _customIncomeCategories.remove(category);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_customIncomeKey, _customIncomeCategories);
      notifyListeners();
    }
  }
}
