import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:smartcache/constants/cartegories.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartcache/providers/budget_provider.dart';
import 'package:smartcache/providers/expense_provider.dart';
import 'package:smartcache/providers/category_provider.dart';
import 'package:smartcache/theme.dart';
import 'package:smartcache/models/budget.dart';

class BudgetsScreen extends StatelessWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.watch<BudgetProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();

    final now = DateTime.now();
    final thisMonthExpenses = expenseProvider.expenses
        .where(
          (e) =>
              e.expenseDate.month == now.month &&
              e.expenseDate.year == now.year,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(FluentIcons.add_24_regular),
            onPressed: () => _showAddBudgetSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger sync and then reload budgets
          await budgetProvider.loadBudgets(month: now.month, year: now.year);
        },
        child: budgetProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : budgetProvider.budgets.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      FluentIcons.target_24_regular,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No budgets set',
                      style: context.textStyles.titleMedium?.withColor(
                        Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showAddBudgetSheet(context),
                      child: const Text('Set your first budget'),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: AppSpacing.paddingSm,
                itemCount: budgetProvider.budgets.length,
                itemBuilder: (context, index) {
                  final budget = budgetProvider.budgets[index];
                  final spent = budgetProvider.calculateSpent(
                    budget,
                    thisMonthExpenses,
                  );
                  final progress = budgetProvider.calculateProgress(
                    budget,
                    thisMonthExpenses,
                  );

                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: AppAnimations.normal,
                    child: _BudgetCard(
                      budget: budget,
                      spent: spent,
                      progress: progress,
                      onTap: () => _showAddBudgetSheet(context, budget: budget),
                      onDelete: () => _confirmDelete(context, budget.id),
                    ),
                  );
                },
              ),
      ),
    );
  }

  void _showAddBudgetSheet(BuildContext context, {Budget? budget}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddBudgetSheet(budget: budget),
    );
  }

  void _confirmDelete(BuildContext context, String budgetId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Budget'),
        content: const Text('Are you sure you want to delete this budget?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<BudgetProvider>().deleteBudget(budgetId);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class AddBudgetSheet extends StatefulWidget {
  final Budget? budget;

  const AddBudgetSheet({super.key, this.budget});

  @override
  State<AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<AddBudgetSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();

  String? _selectedCategory;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  bool get _isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final b = widget.budget!;
      _limitController.text = b.limitAmount.toString();
      _selectedCategory = b.category;
      _selectedMonth = b.month;
      _selectedYear = b.year;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedCategory == null) {
      if (_isEditing) {
        _selectedCategory = widget.budget!.category;
      } else {
        _selectedCategory = context.read<CategoryProvider>().expenseCategories.first;
      }
    }
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final budgetProvider = context.read<BudgetProvider>();
    // For budgets, createOrUpdateBudget handles both cases
    // typically by upserting based on category/month/year
    final success = await budgetProvider.createOrUpdateBudget(
      category: _selectedCategory!,
      limitAmount: double.parse(_limitController.text),
      month: _selectedMonth,
      year: _selectedYear,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Budget updated successfully'
                  : 'Budget saved successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              budgetProvider.errorMessage ?? 'Failed to save budget',
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Budget' : 'Set Budget',
                    style: context.textStyles.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(FluentIcons.tag_24_regular),
                ),
                items: () {
                  final providerCats = context.read<CategoryProvider>().expenseCategories;
                  final categories = [...providerCats];
                  if (_selectedCategory != null && !categories.contains(_selectedCategory)) {
                    categories.add(_selectedCategory!);
                  }
                  return categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(ExpenseCategory.getIcon(category), size: 20),
                          const SizedBox(width: 12),
                          Text(category),
                        ],
                      ),
                    );
                  }).toList();
                }(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              // Limit
              TextFormField(
                controller: _limitController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Budget Limit',
                  hintText: '0.00',
                  prefixIcon: Icon(FluentIcons.money_24_regular),
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Budget limit is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Limit must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Month / Year
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Month',
                        prefixIcon: Icon(
                          FluentIcons.calendar_24_regular,
                          size: 20,
                        ),
                      ),
                      items: List.generate(12, (index) {
                        final month = index + 1;
                        return DropdownMenuItem<int>(
                          value: month,
                          child: Text(
                            DateFormat('MMMM').format(DateTime(2024, month)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedMonth = value);
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: List.generate(5, (index) {
                        final year = DateTime.now().year - 2 + index;
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(_isEditing ? 'Update Budget' : 'Save Budget'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetCard extends StatefulWidget {
  final Budget budget;
  final double spent;
  final double progress;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BudgetCard({
    required this.budget,
    required this.spent,
    required this.progress,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<_BudgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.slow,
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress > 1.0 ? 1.0 : widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void didUpdateWidget(_BudgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: _progressAnimation.value,
            end: widget.progress > 1.0 ? 1.0 : widget.progress,
          ).animate(
            CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
          );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOver = widget.progress > 1.0;
    final statusColor = isOver
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer,
                          Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      ExpenseCategory.getIcon(widget.budget.category),
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.budget.category,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Limit: \$${widget.budget.limitAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.delete_24_regular, size: 22),
                    color: Theme.of(context).colorScheme.error,
                    onPressed: widget.onDelete,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${widget.spent.toStringAsFixed(2)} spent',
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                      Text(
                        '${(widget.progress * 100).toStringAsFixed(1)}%',
                        style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 10,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation(statusColor),
                        ),
                      );
                    },
                  ),
                  if (isOver) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentIcons.warning_24_filled,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Over budget by \$${(widget.spent - widget.budget.limitAmount).toStringAsFixed(2)}',
                            style: context.textStyles.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
