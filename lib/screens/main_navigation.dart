import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:smartcache/screens/income_screen.dart';
import 'package:smartcache/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/providers/expense_provider.dart';
import 'package:smartcache/providers/budget_provider.dart';
import 'package:smartcache/screens/dashboard_screen.dart';
import 'package:smartcache/screens/expenses_screen.dart';
import 'package:smartcache/screens/budgets_screen.dart';


class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final PageController _pageController;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ExpensesScreen(),
    IncomeScreen(),
    BudgetsScreen(),
    //ProfileScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    await Future.wait([
      expenseProvider.loadExpenses(),
      budgetProvider.loadBudgets(
        month: DateTime.now().month,
        year: DateTime.now().year,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(FluentIcons.home_24_regular),
            selectedIcon: Icon(FluentIcons.home_24_filled),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(FluentIcons.receipt_24_regular),
            selectedIcon: Icon(FluentIcons.receipt_24_filled),
            label: 'Expenses',
          ),

          //add Income Screen
          NavigationDestination(
            icon: Icon(FluentIcons.money_24_regular),
            selectedIcon: Icon(FluentIcons.money_24_filled),
            label: 'Income',
          ),

          NavigationDestination(
            icon: Icon(FluentIcons.chart_multiple_24_regular),
            selectedIcon: Icon(FluentIcons.chart_multiple_24_filled),
            label: 'Budgets',
          ),
          NavigationDestination(
            icon: Icon(FluentIcons.settings_24_regular),
            selectedIcon: Icon(FluentIcons.settings_24_filled),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
