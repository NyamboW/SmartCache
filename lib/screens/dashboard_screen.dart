import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:smartcache/constants/cartegories.dart';
import 'package:smartcache/providers/income_provider.dart';
import 'package:smartcache/widgets/add_income_sheet.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smartcache/providers/expense_provider.dart';
import 'package:smartcache/providers/budget_provider.dart';
import 'package:smartcache/theme.dart';
import 'package:smartcache/widgets/add_expense_sheet.dart';
import 'package:smartcache/widgets/spending_line_chart.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _chartController = PageController();
  int _currentChartIndex = 0;

  String _selectedFilter = 'This Month';
  final List<String> _filterOptions = [
    'This Month',
    'Last 3 Months',
    'Last 6 Months',
    'All',
  ];

  @override
  void initState() {
    super.initState();
    // Defer the initial filter setup to after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter(_selectedFilter);
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();
    final budgetProvider = context.read<BudgetProvider>();

    // Load data from APIs
    await Future.wait([
      expenseProvider.loadExpenses(),
      incomeProvider.loadIncomes(),
    ]);

    // Load budgets for current month (budgets are usually monthly)
    // We might want to adjust this if we assume budgets adapt to filters,
    // but typically budgets are "this month". Keeping as is for now.
    final now = DateTime.now();
    await budgetProvider.loadBudgets(month: now.month, year: now.year);
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
    });

    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    if (filter == 'This Month') {
      startDate = DateTime(now.year, now.month, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'Last 3 Months') {
      startDate = DateTime(now.year, now.month - 2, 1); // Current + 2 prev
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'Last 6 Months') {
      startDate = DateTime(now.year, now.month - 5, 1);
      endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    } else if (filter == 'All') {
      startDate = null;
      endDate = null;
    }

    final expenseProvider = context.read<ExpenseProvider>();
    final incomeProvider = context.read<IncomeProvider>();

    expenseProvider.setFilters(startDate: startDate, endDate: endDate);
    incomeProvider.setFilters(startDate: startDate, endDate: endDate);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final incomeProvider = context.watch<IncomeProvider>();

    final filteredExpenses = expenseProvider.filteredExpenses;
    final totalExpenses = expenseProvider.totalExpenses;
    final totalIncome = incomeProvider.totalIncome;
    final netIncome = totalIncome - totalExpenses;

    final recentExpenses = filteredExpenses.take(5).toList();

    // Quick stats calculations
    final daysInPeriod = _getDaysInPeriod();
    final dailyAverage = daysInPeriod > 0 ? totalExpenses / daysInPeriod : 0.0;
    final largestExpense = filteredExpenses.isNotEmpty
        ? filteredExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Header ─────────────────────────────────────────
                _buildHeader(context, userProvider),
                const SizedBox(height: 20),

                // ─── Filter Chips ───────────────────────────────────
                _buildFilterChips(context),
                const SizedBox(height: 20),

                // ─── Hero Balance Card ──────────────────────────────
                _buildHeroCard(
                    context, netIncome, totalIncome, totalExpenses),
                const SizedBox(height: 20),

                // ─── Quick Stats ────────────────────────────────────
                _buildQuickStats(
                  context,
                  dailyAverage: dailyAverage,
                  largestExpense: largestExpense,
                  transactionCount: filteredExpenses.length,
                ),
                const SizedBox(height: 28),

                // ─── Top Spending Categories ────────────────────────
                if (expenseProvider.categoryTotals.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Top Spending'),
                  const SizedBox(height: 12),
                  _buildTopCategories(
                      context, expenseProvider.categoryTotals, totalExpenses),
                  const SizedBox(height: 28),
                ],

                // ─── Charts ─────────────────────────────────────────
                if (expenseProvider.categoryTotals.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (_currentChartIndex == 0
                            ? 'Spending by Category'
                            : (_selectedFilter == 'This Month'
                                  ? 'Daily Spending'
                                  : 'Monthly Spending')).toUpperCase(),
                        style: context.textStyles.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      // Swipe indicator dots
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(2, (index) {
                          return AnimatedContainer(
                            duration: AppAnimations.fast,
                            margin: const EdgeInsets.only(left: 6),
                            width: _currentChartIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                              color: _currentChartIndex == index
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.2),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 350,
                    child: PageView(
                      controller: _chartController,
                      onPageChanged: (index) =>
                          setState(() => _currentChartIndex = index),
                      children: [
                        CategoryChart(
                          categoryTotals: expenseProvider.categoryTotals,
                        ),
                        SpendingLineChart(
                          dailySpending: _selectedFilter == 'This Month'
                              ? expenseProvider.dailySpending
                              : expenseProvider.monthlySpending,
                          isMonthly: _selectedFilter != 'This Month',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // ─── Budget Overview ────────────────────────────────
                if (budgetProvider.budgets.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Budget Overview'),
                  const SizedBox(height: 12),
                  ...budgetProvider.budgets.map((budget) {
                    // Always calculate budget progress based on CURRENT MONTH only
                    // regardless of the broader dashboard filter.
                    final now = DateTime.now();
                    final budgetExpenses = filteredExpenses
                        .where(
                          (e) =>
                              e.expenseDate.month == now.month &&
                              e.expenseDate.year == now.year,
                        )
                        .toList();

                    final spent = budgetProvider.calculateSpent(
                      budget,
                      budgetExpenses,
                    );
                    final progress = budgetProvider.calculateProgress(
                      budget,
                      budgetExpenses,
                    );
                    final isOver = progress > 1.0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BudgetProgressCard(
                        category: budget.category,
                        spent: spent,
                        limit: budget.limitAmount,
                        progress: progress,
                        isOverBudget: isOver,
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                ],

                // ─── Recent Transactions ────────────────────────────
                _buildSectionHeader(context, 'Recent Transactions',
                    trailing: recentExpenses.isNotEmpty
                        ? TextButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          )
                        : null),
                const SizedBox(height: 12),
                if (recentExpenses.isEmpty)
                  _buildEmptyState(context)
                else
                  _buildGroupedTransactions(context, recentExpenses),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),

      floatingActionButton: SpeedDial(
        icon: FluentIcons.add_24_filled,
        activeIcon: FluentIcons.dismiss_24_filled,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        spacing: 12,
        spaceBetweenChildren: 8,
        elevation: 6,

        children: [
          SpeedDialChild(
            child: const Icon(FluentIcons.add_24_regular, color: Colors.white),
            label: 'Add Income',
            backgroundColor: Colors.green,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddIncomeSheet(),
              );
            },
          ),

          SpeedDialChild(
            child: Icon(FluentIcons.subtract_20_regular, color: Colors.white),
            label: 'Add Expense',
            backgroundColor: Colors.red,
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const AddExpenseSheet(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  int _getDaysInPeriod() {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'This Month':
        return now.day;
      case 'Last 3 Months':
        return DateTime(now.year, now.month + 1, 0).day + 60;
      case 'Last 6 Months':
        return DateTime(now.year, now.month + 1, 0).day + 150;
      case 'All':
        return 365;
      default:
        return now.day;
    }
  }

  Widget _buildHeader(BuildContext context, UserProvider userProvider) {
    final userName = userProvider.name;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  userName,
                  style: context.textStyles.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      FluentIcons.calendar_ltr_24_regular,
                      size: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: context.textStyles.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Profile Button (Click to edit name)
          GestureDetector(
            onTap: () => _showEditNameDialog(context, userProvider),
            child: CircleAvatar(
              radius: 22,
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: context.textStyles.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditNameDialog(
      BuildContext context, UserProvider userProvider) async {
    final controller = TextEditingController(
        text: userProvider.name == 'User' ? '' : userProvider.name);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Your Name',
              hintText: 'e.g. Alice',
            ),
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                userProvider.setName(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filterOptions.map((filter) {
          final isSelected = filter == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              child: ChoiceChip(
                label: Text(
                  filter,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                selected: isSelected,
                selectedColor: Theme.of(context).colorScheme.primary,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                showCheckmark: false,
                onSelected: (_) => _applyFilter(filter),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, double netIncome,
      double totalIncome, double totalExpenses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF003D5C),
                  const Color(0xFF00293D),
                ]
              : [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.85),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Balance label
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Text(
                    'Net Balance',
                    style: context.textStyles.labelMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  netIncome >= 0
                      ? FluentIcons.arrow_trending_24_regular
                      : FluentIcons.arrow_trending_down_24_regular,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Net balance amount
            Text(
              NumberFormat.currency(symbol: '\$').format(netIncome),
              style: context.textStyles.displaySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 24),
            // Income and Expense inline rows
            Row(
              children: [
                Expanded(
                  child: _buildHeroStat(
                    context,
                    icon: FluentIcons.arrow_up_24_filled,
                    label: 'Income',
                    amount: totalIncome,
                    color: const Color(0xFF34D399),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.15),
                ),
                Expanded(
                  child: _buildHeroStat(
                    context,
                    icon: FluentIcons.arrow_down_24_filled,
                    label: 'Expenses',
                    amount: totalExpenses,
                    color: const Color(0xFFF87171),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroStat(BuildContext context,
      {required IconData icon,
      required String label,
      required double amount,
      required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  NumberFormat.compactCurrency(symbol: '\$').format(amount),
                  style: context.textStyles.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context,
      {required double dailyAverage,
      required double largestExpense,
      required int transactionCount}) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(
            icon: FluentIcons.calendar_day_24_regular,
            label: 'Daily Avg',
            value: NumberFormat.compactCurrency(symbol: '\$')
                .format(dailyAverage),
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickStatCard(
            icon: FluentIcons.arrow_maximize_24_regular,
            label: 'Largest',
            value: NumberFormat.compactCurrency(symbol: '\$')
                .format(largestExpense),
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickStatCard(
            icon: FluentIcons.receipt_24_regular,
            label: 'Transactions',
            value: transactionCount.toString(),
            color: const Color(0xFF8B5CF6),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: context.textStyles.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildTopCategories(
      BuildContext context, Map<String, double> categoryTotals, double total) {
    // Sort by amount descending, take top 5
    final sorted = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategories = sorted.take(5).toList();

    return Container(
      decoration: AppCardDecoration.surface(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: topCategories.asMap().entries.map((entry) {
            final i = entry.key;
            final data = entry.value;
            final percentage = total > 0 ? data.value / total : 0.0;
            final catColor = CategoryColors.get(data.key);

            return Column(
              children: [
                if (i > 0)
                  Divider(
                    height: 1,
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withOpacity(0.08),
                  ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(vertical: i == 0 ? 4 : 12),
                  child: Row(
                    children: [
                      // Category icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          ExpenseCategory.getIcon(data.key),
                          size: 18,
                          color: catColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Name + progress bar
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    data.key,
                                    style: context.textStyles.bodyMedium
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  NumberFormat.currency(symbol: '\$')
                                      .format(data.value),
                                  style: context.textStyles.bodyMedium
                                      ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 6,
                                      backgroundColor: catColor
                                          .withOpacity(0.1),
                                      valueColor:
                                          AlwaysStoppedAnimation(
                                              catColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(1)}%',
                                  style: context.textStyles.labelSmall
                                      ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingXl,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentIcons.receipt_24_regular,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No expenses yet',
              style: context.textStyles.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap + to add your first expense',
              style: context.textStyles.bodySmall?.withColor(
                Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedTransactions(
      BuildContext context, List<dynamic> expenses) {
    // Group by date
    final groups = <String, List<dynamic>>{};
    for (final expense in expenses) {
      final dateKey = _getDateLabel(expense.expenseDate);
      groups.putIfAbsent(dateKey, () => []).add(expense);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groups.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Text(
                entry.key,
                style: context.textStyles.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            // Transactions in that date group
            ...entry.value
                .map((expense) => _ModernExpenseTile(expense: expense)),
          ],
        );
      }).toList(),
    );
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today';
    if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    }
    return DateFormat('MMM d, y').format(date);
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EXTRACTED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _QuickStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: AppCardDecoration.surface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernExpenseTile extends StatelessWidget {
  final dynamic expense;

  const _ModernExpenseTile({required this.expense});

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryColors.get(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppCardDecoration.surface(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Category icon with colored background
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: catColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                ExpenseCategory.getIcon(expense.category),
                color: catColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Category name + note
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (expense.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      expense.note,
                      style: context.textStyles.bodySmall?.withColor(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Amount
            Text(
              '-${NumberFormat.currency(symbol: '\$').format(expense.amount)}',
              style: context.textStyles.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChart extends StatelessWidget {
  final Map<String, double> categoryTotals;

  const CategoryChart({super.key, required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold(0.0, (sum, val) => sum + val);

    return Container(
      decoration: AppCardDecoration.surface(context),
      child: Padding(
        padding: AppSpacing.paddingLg,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections:
                      categoryTotals.entries.toList().asMap().entries.map(
                    (entry) {
                      final data = entry.value;
                      final percentage = (data.value / total * 100);
                      final catColor = CategoryColors.get(data.key);

                      return PieChartSectionData(
                        value: data.value,
                        title: '${percentage.toStringAsFixed(1)}%',
                        color: catColor,
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    },
                  ).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children:
                      categoryTotals.entries.toList().asMap().entries.map(
                    (entry) {
                      final data = entry.value;
                      final catColor = CategoryColors.get(data.key);

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: catColor,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(data.key,
                              style: context.textStyles.bodySmall),
                        ],
                      );
                    },
                  ).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetProgressCard extends StatelessWidget {
  final String category;
  final double spent;
  final double limit;
  final double progress;
  final bool isOverBudget;

  const BudgetProgressCard({
    super.key,
    required this.category,
    required this.spent,
    required this.limit,
    required this.progress,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryColors.get(category);
    final statusColor =
        isOverBudget ? Theme.of(context).colorScheme.error : catColor;

    return Container(
      decoration: AppCardDecoration.surface(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Icon(
                    ExpenseCategory.getIcon(category),
                    size: 18,
                    color: catColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      NumberFormat.currency(symbol: '\$').format(spent),
                      style: context.textStyles.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                    Text(
                      'of ${NumberFormat.currency(symbol: '\$').format(limit)}',
                      style: context.textStyles.labelSmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress > 1.0 ? 1.0 : progress,
                minHeight: 6,
                backgroundColor: statusColor.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    FluentIcons.warning_24_filled,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Over by ${NumberFormat.currency(symbol: '\$').format(spent - limit)}',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExpenseListTile extends StatelessWidget {
  final dynamic expense;

  const ExpenseListTile({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryColors.get(expense.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: catColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            ExpenseCategory.getIcon(expense.category),
            color: catColor,
            size: 22,
          ),
        ),
        title: Text(expense.category, style: context.textStyles.titleMedium),
        subtitle: Text(
          DateFormat('MMM d, y').format(expense.expenseDate),
          style: context.textStyles.bodySmall?.withColor(
            Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          NumberFormat.currency(symbol: '\$').format(expense.amount),
          style: context.textStyles.titleMedium?.bold.withColor(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
