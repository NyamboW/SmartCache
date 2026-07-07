import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:smartcache/constants/cartegories.dart';
import 'package:smartcache/models/expense.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smartcache/providers/expense_provider.dart';
import 'package:smartcache/theme.dart';

class AddExpenseSheet extends StatefulWidget {
  final Expense? expense;

  const AddExpenseSheet({super.key, this.expense});

  @override
  State<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends State<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = ExpenseCategory.all.first;
  String _selectedPaymentMethod = PaymentMethod.cash;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final e = widget.expense!;
      _amountController.text = e.amount.toString();
      _noteController.text = e.note;
      _selectedCategory = e.category;
      _selectedPaymentMethod = e.paymentMethod;
      _selectedDate = e.expenseDate;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final expenseProvider = context.read<ExpenseProvider>();
    bool success;

    if (_isEditing) {
      success = await expenseProvider.updateExpense(
        id: widget.expense!.id,
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        note: _noteController.text,
        paymentMethod: _selectedPaymentMethod,
        expenseDate: _selectedDate,
      );
    } else {
      success = await expenseProvider.addExpense(
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        note: _noteController.text,
        paymentMethod: _selectedPaymentMethod,
        expenseDate: _selectedDate,
      );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Expense updated successfully'
                  : 'Expense added successfully',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              expenseProvider.errorMessage ??
                  (_isEditing
                      ? 'Failed to update expense'
                      : 'Failed to add expense'),
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
                    _isEditing ? 'Edit Expense' : 'Add Expense',
                    style: context.textStyles.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(FluentIcons.money_24_regular),
                  prefixText: '\$ ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(FluentIcons.tag_24_regular),
                ),
                items: ExpenseCategory.all.map((category) {
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
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  prefixIcon: Icon(FluentIcons.payment_24_regular),
                ),
                items: PaymentMethod.all.map((method) {
                  return DropdownMenuItem(
                    value: method,
                    child: Row(
                      children: [
                        Icon(PaymentMethod.getIcon(method), size: 20),
                        const SizedBox(width: 12),
                        Text(PaymentMethod.getLabel(method)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null)
                    setState(() => _selectedPaymentMethod = value);
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    prefixIcon: Icon(FluentIcons.calendar_24_regular),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM d, y').format(_selectedDate)),
                      const Icon(FluentIcons.chevron_down_24_regular, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  hintText: 'Add a note...',
                  prefixIcon: Icon(FluentIcons.note_24_regular),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(_isEditing ? 'Update Expense' : 'Add Expense'),
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
