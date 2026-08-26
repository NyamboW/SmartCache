import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:smartcache/constants/income_categories.dart'; // NEW
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartcache/providers/income_provider.dart'; // NEW
import 'package:smartcache/providers/category_provider.dart';
import 'package:smartcache/theme.dart';
import 'package:smartcache/widgets/add_income_sheet.dart'; // NEW

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  @override
  void initState() {
    super.initState();
    // Clear any filters that may have been set by the dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IncomeProvider>().clearFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final incomeProvider = context.watch<IncomeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income'),
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
              builder: (_) => const AddIncomeSheet(),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Trigger sync and then reload incomes
          await incomeProvider.loadIncomes();
        },
        child: incomeProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : incomeProvider.filteredIncomes.isEmpty
            ? _buildEmptyState(context)
            : Column(
                children: [
                  if (incomeProvider.selectedCategory != null ||
                      incomeProvider.startDate != null ||
                      incomeProvider.endDate != null)
                    _buildFilterBanner(context, incomeProvider),

                  // ─── Summary Card ───────────────────────────
                  _buildSummaryCard(context, incomeProvider),

                  // ─── Income List ────────────────────────────
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      itemCount: incomeProvider.filteredIncomes.length,
                      itemBuilder: (context, index) {
                        final income =
                            incomeProvider.filteredIncomes[index];
                        return _IncomeCard(
                          income: income,
                          onTap: () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) =>
                                AddIncomeSheet(income: income),
                          ),
                          onDelete: () =>
                              _confirmDelete(context, income.id),
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
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FluentIcons.money_24_regular,
              size: 56,
              color: const Color(0xFF10B981).withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No income records found',
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
              builder: (_) => const AddIncomeSheet(),
            ),
            icon: const Icon(FluentIcons.add_24_regular, size: 18),
            label: const Text('Add your first income'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBanner(
      BuildContext context, IncomeProvider incomeProvider) {
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
            onPressed: incomeProvider.clearFilters,
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
      BuildContext context, IncomeProvider incomeProvider) {
    final count = incomeProvider.filteredIncomes.length;
    final total = incomeProvider.totalIncome;
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
                  'Total Income',
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
                    color: const Color(0xFF10B981),
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
    final incomeProvider = context.read<IncomeProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => IncomeFilterSheet(
        initialCategory: incomeProvider.selectedCategory,
        initialStartDate: incomeProvider.startDate,
        initialEndDate: incomeProvider.endDate,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String incomeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Income'),
        content: const Text(
          'Are you sure you want to delete this income entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final incomeProvider = context.read<IncomeProvider>();
              final success = await incomeProvider.deleteIncome(incomeId);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Income deleted' : 'Failed to delete income',
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
// INCOME CARD
// ═════════════════════════════════════════════════════════════════════════════

class _IncomeCard extends StatelessWidget {
  final dynamic income;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _IncomeCard({
    required this.income,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = CategoryColors.get(income.category);

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
                  IncomeCategory.getIcon(income.category),
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
                            income.category,
                            style: context.textStyles.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+${NumberFormat.currency(symbol: '\$').format(income.amount)}',
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    if (income.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        income.note,
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
                          FluentIcons.calendar_24_regular,
                          size: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y')
                              .format(income.incomeDate),
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

// ----------------------------------------------------------------------
// FILTER SHEET FOR INCOME
// ----------------------------------------------------------------------

class IncomeFilterSheet extends StatefulWidget {
  final String? initialCategory;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const IncomeFilterSheet({
    super.key,
    this.initialCategory,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<IncomeFilterSheet> createState() => _IncomeFilterSheetState();
}

class _IncomeFilterSheetState extends State<IncomeFilterSheet> {
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
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
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _applyFilters() {
    final provider = context.read<IncomeProvider>();
    provider.setFilters(
      category: _selectedCategory,
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
                Text('Filter Income', style: context.textStyles.headlineSmall),
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
                  final providerCats = context.watch<CategoryProvider>().incomeCategories;
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
