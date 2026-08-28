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
import 'package:quick_actions/quick_actions.dart';
import 'package:smartcache/widgets/add_expense_sheet.dart';
import 'package:smartcache/widgets/add_income_sheet.dart';


class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  late final PageController _pageController;

  late final List<Widget> _screens = [
    DashboardScreen(
      onViewAllTransactions: () {
        setState(() => _currentIndex = 1);
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
    ),
    const ExpensesScreen(),
    const IncomeScreen(),
    const BudgetsScreen(),
    const SettingsScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(
      icon: FluentIcons.home_24_regular,
      selectedIcon: FluentIcons.home_24_filled,
      label: 'Home',
    ),
    _NavItem(
      icon: FluentIcons.receipt_24_regular,
      selectedIcon: FluentIcons.receipt_24_filled,
      label: 'Expenses',
    ),
    _NavItem(
      icon: FluentIcons.money_24_regular,
      selectedIcon: FluentIcons.money_24_filled,
      label: 'Income',
    ),
    _NavItem(
      icon: FluentIcons.chart_multiple_24_regular,
      selectedIcon: FluentIcons.chart_multiple_24_filled,
      label: 'Budgets',
    ),
    _NavItem(
      icon: FluentIcons.settings_24_regular,
      selectedIcon: FluentIcons.settings_24_filled,
      label: 'Settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadData();
    _setupQuickActions();
  }

  void _setupQuickActions() {
    const QuickActions quickActions = QuickActions();
    
    quickActions.initialize((String shortcutType) {
      // Small delay to ensure the widget is built if launched from cold start
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        
        if (shortcutType == 'action_add_expense') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddExpenseSheet(),
          );
        } else if (shortcutType == 'action_add_income') {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddIncomeSheet(),
          );
        }
      });
    });

    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_add_expense',
        localizedTitle: 'Add Expense',
        icon: 'ic_remove',
      ),
      const ShortcutItem(
        type: 'action_add_income',
        localizedTitle: 'Add Income',
        icon: 'ic_add',
      ),
    ]);
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
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.fromLTRB(8, 0, 8, 8 + MediaQuery.of(context).padding.bottom),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_navItems.length, (index) {
            final isSelected = _currentIndex == index;
            final item = _navItems[index];
            final colorScheme = Theme.of(context).colorScheme;

            return GestureDetector(
              onTap: () {
                setState(() => _currentIndex = index);
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48,
                padding: isSelected
                    ? const EdgeInsets.only(left: 6, right: 16, top: 6, bottom: 6)
                    : const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? colorScheme.secondaryContainer 
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: isSelected ? 36 : 24,
                        height: isSelected ? 36 : 24,
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isSelected ? item.selectedIcon : item.icon,
                            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Text(
                          item.label,
                          style: TextStyle(
                            color: colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      ),
    );
  }
}
