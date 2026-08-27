import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/providers/category_provider.dart';
import 'package:smartcache/theme.dart';
import 'package:smartcache/constants/cartegories.dart';
import 'package:smartcache/constants/income_categories.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final bool isExpense;

  const ManageCategoriesScreen({super.key, required this.isExpense});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen> {
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  void _addCategory() {
    final provider = context.read<CategoryProvider>();
    final category = _categoryController.text.trim();
    if (category.isNotEmpty) {
      if (widget.isExpense) {
        if (provider.expenseCategories.contains(category)) {
          _showError('Category already exists');
          return;
        }
        provider.addCustomExpenseCategory(category);
      } else {
        if (provider.incomeCategories.contains(category)) {
          _showError('Category already exists');
          return;
        }
        provider.addCustomIncomeCategory(category);
      }
      _categoryController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CategoryProvider>();
    final customCategories = widget.isExpense 
        ? provider.customExpenseCategories 
        : provider.customIncomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isExpense ? 'Expense Categories' : 'Income Categories'),
      ),
      body: Column(
        children: [
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'New Category Name',
                      hintText: 'e.g. Subscriptions',
                      prefixIcon: Icon(FluentIcons.tag_24_regular),
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton(
                  onPressed: _addCategory,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(FluentIcons.add_24_regular),
                ),
              ],
            ),
          ),
          Expanded(
            child: customCategories.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FluentIcons.tag_24_regular,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'No Custom Categories',
                          style: context.textStyles.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Add your own categories to track your finances better.',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: AppSpacing.paddingLg,
                    itemCount: customCategories.length,
                    separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final category = customCategories[index];
                      // Use standard icon if defined, otherwise fallback
                      final iconData = widget.isExpense 
                          ? ExpenseCategory.getIcon(category) 
                          : IncomeCategory.getIcon(category);
                          
                      return Container(
                        decoration: AppCardDecoration.surface(context),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md, 
                            vertical: AppSpacing.xs
                          ),
                          leading: Container(
                            padding: AppSpacing.paddingSm,
                            decoration: BoxDecoration(
                              color: CategoryColors.background(category),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              iconData,
                              color: CategoryColors.get(category),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            category,
                            style: context.textStyles.titleMedium,
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              FluentIcons.delete_24_regular, 
                              color: Theme.of(context).colorScheme.error
                            ),
                            onPressed: () {
                              if (widget.isExpense) {
                                provider.removeCustomExpenseCategory(category);
                              } else {
                                provider.removeCustomIncomeCategory(category);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
