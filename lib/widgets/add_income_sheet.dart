import 'package:flutter/material.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:intl/intl.dart';
import 'package:smartcache/models/income.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/providers/income_provider.dart';
import 'package:smartcache/theme.dart';
import 'package:smartcache/constants/income_categories.dart';

class AddIncomeSheet extends StatefulWidget {
  final Income? income;

  const AddIncomeSheet({super.key, this.income});

  @override
  State<AddIncomeSheet> createState() => _AddIncomeSheetState();
}

class _AddIncomeSheetState extends State<AddIncomeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _selectedCategory = IncomeCategory.all.first;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditing => widget.income != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final i = widget.income!;
      _amountController.text = i.amount.toString();
      _noteController.text = i.note;
      _selectedCategory = i.category;
      _selectedDate = i.incomeDate;
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

    final incomeProvider = context.read<IncomeProvider>();
    bool success;

    if (_isEditing) {
      success = await incomeProvider.updateIncome(
        id: widget.income!.id,
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        note: _noteController.text,
        incomeDate: _selectedDate,
      );
    } else {
      success = await incomeProvider.addIncome(
        category: _selectedCategory,
        amount: double.parse(_amountController.text),
        note: _noteController.text,
        incomeDate: _selectedDate,
      );
    }

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Income updated successfully'
                : 'Income added successfully',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            incomeProvider.errorMessage ??
                (_isEditing
                    ? 'Failed to update income'
                    : 'Failed to add income'),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Income' : 'Add Income',
                    style: context.textStyles.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(FluentIcons.dismiss_24_regular),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AMOUNT
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

              // CATEGORY
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Income Category',
                  prefixIcon: Icon(FluentIcons.tag_24_regular),
                ),
                items: IncomeCategory.all.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(IncomeCategory.getIcon(category), size: 20),
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

              // DATE PICKER
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

              // NOTE
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

              // SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
                  child: Text(_isEditing ? 'Update Income' : 'Add Income'),
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
