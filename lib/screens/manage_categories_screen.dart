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
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _categoryController.dispose();
    _focusNode.dispose();
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
                    focusNode: _focusNode,
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
                            FluentIcons.tag_24_regular,
                            size: 56,
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          widget.isExpense ? 'No Custom Categories' : 'No Custom Income',
                          style: context.textStyles.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _focusNode.requestFocus(),
                          icon: const Icon(FluentIcons.add_24_regular, size: 18),
                          label: const Text('Add your first category'),
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
