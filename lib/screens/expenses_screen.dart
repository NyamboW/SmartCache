import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:smartcache/constants/cartegories.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartcache/providers/expense_provider.dart';
import 'package:smartcache/providers/category_provider.dart';
import 'package:smartcache/theme.dart';
import 'package:smartcache/widgets/add_expense_sheet.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {


  @override
  Widget build(BuildContext context) {
    final expenseProvider = context.watch<ExpenseProvider>();

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.filter_24_regular),
            onPressed: () => _showFilterSheet(context),
          ),
          IconButton(
            icon: const Icon(FluentIcons.add_24_regular),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddExpenseSheet(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger sync and then reload expenses
          await expenseProvider.loadExpenses();
        },
        child: expenseProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : expenseProvider.filteredExpenses.isEmpty
            ? _buildEmptyState(context)
            : Column(
                children: [
                  if (expenseProvider.selectedCategory != null ||
                      expenseProvider.selectedPaymentMethod != null ||
                      expenseProvider.startDate != null ||
                      expenseProvider.endDate != null)
                    _buildFilterBanner(context, expenseProvider),

                  // ─── Summary Card ───────────────────────────
                  _buildSummaryCard(context, expenseProvider),

                  // ─── Transaction List ───────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                          left: 12, right: 12, top: 8, bottom: 80),
                      itemCount: expenseProvider.filteredExpenses.length,
                      itemBuilder: (context, index) {
                        final expense =
                            expenseProvider.filteredExpenses[index];
                        return _ExpenseCard(
                          expense: expense,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                AddExpenseSheet(expense: expense),
                          ),
                          onDelete: () =>
                              _confirmDelete(context, expense.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.receipt_24_regular,
              size: 56,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No expenses found',
            style: context.textStyles.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const AddExpenseSheet(),
            ),
            icon: const Icon(FluentIcons.add_24_regular, size: 18),
            label: const Text('Add your first expense'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBanner(
      BuildContext context, ExpenseProvider expenseProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(
            FluentIcons.filter_24_filled,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filters active',
              style: context.textStyles.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: expenseProvider.clearFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, ExpenseProvider expenseProvider) {
    final count = expenseProvider.filteredExpenses.length;
    final total = expenseProvider.totalExpenses;
    final average = count > 0 ? total / count : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      padding: const EdgeInsets.all(16),
      decoration: AppCardDecoration.elevated(context),
      child: Row(
        children: [
          // Total
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Expenses',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '\$').format(total),
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.error,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.15),
          ),
          const SizedBox(width: 16),
          // Count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Count',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  count.toString(),
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Average
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Average',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.compactCurrency(symbol: '\$').format(average),
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    final expenseProvider = context.read<ExpenseProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterSheet(
        initialCategory: expenseProvider.selectedCategory,
        initialPaymentMethod: expenseProvider.selectedPaymentMethod,
        initialStartDate: expenseProvider.startDate,
        initialEndDate: expenseProvider.endDate,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String expenseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: const Text('Are you sure you want to delete this expense?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final expenseProvider = context.read<ExpenseProvider>();
              final success = await expenseProvider.deleteExpense(expenseId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Expense deleted' : 'Failed to delete expense',
                    ),
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EXPENSE CARD
// ═════════════════════════════════════════════════════════════════════════════

class _ExpenseCard extends StatelessWidget {
  final dynamic expense;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ExpenseCard({
    required this.expense,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryColors.get(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: AppCardDecoration.surface(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Category icon
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
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            expense.category,
                            style: context.textStyles.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(symbol: '\$')
                              .format(expense.amount),
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    if (expense.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        expense.note,
                        style: context.textStyles.bodySmall?.withColor(
                          Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          PaymentMethod.getIcon(expense.paymentMethod),
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          PaymentMethod.getLabel(expense.paymentMethod),
                          style: context.textStyles.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          FluentIcons.calendar_24_regular,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y')
                              .format(expense.expenseDate),
                          style: context.textStyles.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Delete button
              IconButton(
                icon: const Icon(FluentIcons.delete_24_regular, size: 18),
                color: Theme.of(context).colorScheme.error.withOpacity(0.7),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILTER SHEET
// ═════════════════════════════════════════════════════════════════════════════

class FilterSheet extends StatefulWidget {
  final String? initialCategory;
  final String? initialPaymentMethod;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const FilterSheet({
    super.key,
    this.initialCategory,
    this.initialPaymentMethod,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _selectedCategory;
  String? _selectedPaymentMethod;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
    _selectedPaymentMethod = widget.initialPaymentMethod;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  void _applyFilters() {
    final expenseProvider = context.read<ExpenseProvider>();
    expenseProvider.setFilters(
      category: _selectedCategory,
      paymentMethod: _selectedPaymentMethod,
      startDate: _startDate,
      endDate: _endDate,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Expenses',
                  style: context.textStyles.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(FluentIcons.dismiss_24_regular),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Category', style: context.textStyles.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedCategory == null,
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                ...() {
                  final providerCats = context.watch<CategoryProvider>().expenseCategories;
                  final categories = [...providerCats];
                  if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
                    categories.add(_selectedCategory!);
                  }
                  return categories.map((category) {
                    return ChoiceChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    );
                  }).toList();
                }(),
              ],
            ),
            const SizedBox(height: 24),
            Text('Payment Method', style: context.textStyles.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedPaymentMethod == null,
                  onSelected: (_) =>
                      setState(() => _selectedPaymentMethod = null),
                ),
                ...PaymentMethod.all.map((method) {
                  return ChoiceChip(
                    label: Text(PaymentMethod.getLabel(method)),
                    selected: _selectedPaymentMethod == method,
                    onSelected: (_) =>
                        setState(() => _selectedPaymentMethod = method),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
            Text('Date Range', style: context.textStyles.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectStartDate(context),
                    child: Text(
                      _startDate != null
                          ? DateFormat('MMM d, y').format(_startDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _selectEndDate(context),
                    child: Text(
                      _endDate != null
                          ? DateFormat('MMM d, y').format(_endDate!)
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply Filters'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
