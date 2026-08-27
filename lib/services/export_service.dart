import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smartcache/models/budget.dart';
import 'package:smartcache/models/expense.dart';
import 'package:smartcache/models/income.dart';
import 'package:smartcache/services/budget_service.dart';
import 'package:smartcache/services/expense_service.dart';
import 'package:smartcache/services/income_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  final IncomeService _incomeService;
  final ExpenseService _expenseService;
  final BudgetService _budgetService;

  ExportService({
    required IncomeService incomeService,
    required ExpenseService expenseService,
    required BudgetService budgetService,
  }) : _incomeService = incomeService,
       _expenseService = expenseService,
       _budgetService = budgetService;

  Future<void> exportData(BuildContext context) async {
    try {
      // 1. Fetch Data
      final incomes = await _incomeService.getIncome();
      final expenses = await _expenseService.getExpenses();
      final budgets = await _budgetService.getBudgets();

      // 2. Create Excel
      var excel = Excel.createExcel();

      // 3. Add Sheets
      _addIncomeSheet(excel, incomes);
      _addExpenseSheet(excel, expenses);
      _addBudgetSheet(excel, budgets);

      // Remove default "Sheet1" if it exists and we added others
      if (excel.sheets.keys.length > 1 && excel.sheets.containsKey('Sheet1')) {
        excel.delete('Sheet1');
      }

      // 4. Save and Share Options
      bool? saveToDevice = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Export Options'),
            content: const Text('How would you like to export your data?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Share File'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save to Device'),
              ),
            ],
          );
        },
      );

      if (saveToDevice == null) return; // User cancelled

      final fileBytes = excel.save();
      if (fileBytes == null) {
        throw Exception("Failed to generate Excel file");
      }

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'smartcache_export_$dateStr';

      if (saveToDevice) {
        final bytes = Uint8List.fromList(fileBytes);
        final path = await FileSaver.instance.saveAs(
          name: fileName,
          bytes: bytes,
          fileExtension: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
        if (context.mounted && path != null && path.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File saved to $path')),
          );
        }
      } else {
        // Share
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/$fileName.xlsx';

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        final result = await Share.shareXFiles([
          XFile(filePath),
        ], text: 'Here is your SmartCache financial data export.');

        if (result.status == ShareResultStatus.dismissed) {
          debugPrint('Share dismissed');
        }
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export data: $e')));
      }
    }
  }

  void _addIncomeSheet(Excel excel, List<Income> incomes) {
    var sheet = excel['Income'];

    // Header
    List<String> headers = [
      'ID',
      'Date',
      'Category',
      'Amount',
      'Payment Method',
      'Note',
      'Is Recurring',
      'Recurrence Interval',
      'Next Recurrence Date',
      'Created At',
      'Updated At',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data
    for (var income in incomes) {
      List<CellValue> row = [
        TextCellValue(income.id),
        TextCellValue(DateFormat('yyyy-MM-dd').format(income.incomeDate)),
        TextCellValue(income.category),
        DoubleCellValue(income.amount),
        TextCellValue(income.paymentMethod),
        TextCellValue(income.note),
        TextCellValue(income.isRecurring ? 'Yes' : 'No'),
        TextCellValue(income.recurrenceInterval ?? ''),
        TextCellValue(income.nextRecurrenceDate != null ? DateFormat('yyyy-MM-dd').format(income.nextRecurrenceDate!) : ''),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(income.createdAt)),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(income.updatedAt)),
      ];
      sheet.appendRow(row);
    }
  }

  void _addExpenseSheet(Excel excel, List<Expense> expenses) {
    var sheet = excel['Expenses'];

    // Header
    List<String> headers = [
      'ID',
      'Date',
      'Category',
      'Amount',
      'Payment Method',
      'Note',
      'Is Recurring',
      'Recurrence Interval',
      'Next Recurrence Date',
      'Created At',
      'Updated At',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data
    for (var expense in expenses) {
      List<CellValue> row = [
        TextCellValue(expense.id),
        TextCellValue(DateFormat('yyyy-MM-dd').format(expense.expenseDate)),
        TextCellValue(expense.category),
        DoubleCellValue(expense.amount),
        TextCellValue(expense.paymentMethod),
        TextCellValue(expense.note),
        TextCellValue(expense.isRecurring ? 'Yes' : 'No'),
        TextCellValue(expense.recurrenceInterval ?? ''),
        TextCellValue(expense.nextRecurrenceDate != null ? DateFormat('yyyy-MM-dd').format(expense.nextRecurrenceDate!) : ''),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(expense.createdAt)),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(expense.updatedAt)),
      ];
      sheet.appendRow(row);
    }
  }

  void _addBudgetSheet(Excel excel, List<Budget> budgets) {
    var sheet = excel['Budgets'];

    // Header
    List<String> headers = [
      'ID',
      'Period',
      'Category',
      'Limit Amount',
      'Created At',
      'Updated At',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    // Data
    for (var budget in budgets) {
      List<CellValue> row = [
        TextCellValue(budget.id),
        TextCellValue(
          '${budget.year}-${budget.month.toString().padLeft(2, '0')}',
        ),
        TextCellValue(budget.category),
        DoubleCellValue(budget.limitAmount),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(budget.createdAt)),
        TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(budget.updatedAt)),
      ];
      sheet.appendRow(row);
    }
  }
}
