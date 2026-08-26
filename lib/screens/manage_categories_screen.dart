import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/providers/category_provider.dart';
import 'package:smartcache/theme.dart';

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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: InputDecoration(
                      labelText: 'New Category Name',
                      prefixIcon: const Icon(FluentIcons.tag_24_regular),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    onSubmitted: (_) => _addCategory(),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton.filled(
                  icon: const Icon(FluentIcons.add_24_regular),
                  onPressed: _addCategory,
                  padding: const EdgeInsets.all(16),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: customCategories.isEmpty
                ? Center(
                    child: Text(
                      'No custom categories added.',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: customCategories.length,
                    itemBuilder: (context, index) {
                      final category = customCategories[index];
                      return ListTile(
                        leading: const Icon(FluentIcons.tag_24_regular),
                        title: Text(category),
                        trailing: IconButton(
                          icon: const Icon(FluentIcons.delete_24_regular, color: Colors.red),
                          onPressed: () {
                            if (widget.isExpense) {
                              provider.removeCustomExpenseCategory(category);
                            } else {
                              provider.removeCustomIncomeCategory(category);
                            }
                          },
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
