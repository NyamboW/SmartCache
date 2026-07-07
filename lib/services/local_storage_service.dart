import 'package:hive_flutter/hive_flutter.dart';
import 'package:smartcache/models/expense.dart';
import 'package:smartcache/models/budget.dart';
import 'package:smartcache/models/income.dart';

class LocalStorageService {
  static const String expensesBoxName = 'expenses';
  static const String budgetsBoxName = 'budgets';
  static const String incomesBoxName = 'incomes';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(BudgetAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(IncomeAdapter());

    // Open Boxes
    await Hive.openBox<Expense>(expensesBoxName);
    await Hive.openBox<Budget>(budgetsBoxName);
    await Hive.openBox<Income>(incomesBoxName);
  }

  // Generic methods to access boxes
  static Box<Expense> get expensesBox => Hive.box<Expense>(expensesBoxName);
  static Box<Budget> get budgetsBox => Hive.box<Budget>(budgetsBoxName);
  static Box<Income> get incomesBox => Hive.box<Income>(incomesBoxName);

  // Clear all data
  static Future<void> clearAll() async {
    await expensesBox.clear();
    await budgetsBox.clear();
    await incomesBox.clear();
  }
}
