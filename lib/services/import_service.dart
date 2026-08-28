import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:smartcache/models/budget.dart';
import 'package:smartcache/models/expense.dart';
import 'package:smartcache/models/income.dart';
import 'package:smartcache/services/local_storage_service.dart';

class ImportService {
  Future<void> importData(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled
      }

      File file = File(result.files.single.path!);
      var bytes = file.readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      int incomesImported = 0;
      int expensesImported = 0;
      int budgetsImported = 0;

      // Import Income
      if (excel.tables.keys.contains('Income')) {
        var sheet = excel.tables['Income']!;
        for (var i = 1; i < sheet.maxRows; i++) {
          var row = sheet.row(i);
          if (row.isEmpty || row[0] == null) continue;

          final income = Income(
            id: row[0]?.value?.toString() ?? '',
            userId: '',
            incomeDate: _parseDate(row[1]?.value),
            category: row[2]?.value?.toString() ?? '',
            amount: double.tryParse(row[3]?.value?.toString() ?? '') ?? 0.0,
            paymentMethod: row[4]?.value?.toString() ?? '',
            note: row[5]?.value?.toString() ?? '',
            isRecurring: row[6]?.value?.toString().toLowerCase() == 'yes',
            recurrenceInterval: _parseStringOrNull(row[7]?.value),
            nextRecurrenceDate: _parseDateOrNull(row[8]?.value),
            createdAt: _parseDate(row[9]?.value, fallback: DateTime.now()),
            updatedAt: _parseDate(row[10]?.value, fallback: DateTime.now()),
          );
          await LocalStorageService.incomesBox.put(income.id, income);
          incomesImported++;
        }
      }

      // Import Expenses
      if (excel.tables.keys.contains('Expenses')) {
        var sheet = excel.tables['Expenses']!;
        for (var i = 1; i < sheet.maxRows; i++) {
          var row = sheet.row(i);
          if (row.isEmpty || row[0] == null) continue;

          final expense = Expense(
            id: row[0]?.value?.toString() ?? '',
            userId: '',
            expenseDate: _parseDate(row[1]?.value),
            category: row[2]?.value?.toString() ?? '',
            amount: double.tryParse(row[3]?.value?.toString() ?? '') ?? 0.0,
            paymentMethod: row[4]?.value?.toString() ?? '',
            note: row[5]?.value?.toString() ?? '',
            isRecurring: row[6]?.value?.toString().toLowerCase() == 'yes',
            recurrenceInterval: _parseStringOrNull(row[7]?.value),
            nextRecurrenceDate: _parseDateOrNull(row[8]?.value),
            createdAt: _parseDate(row[9]?.value, fallback: DateTime.now()),
            updatedAt: _parseDate(row[10]?.value, fallback: DateTime.now()),
          );
          await LocalStorageService.expensesBox.put(expense.id, expense);
          expensesImported++;
        }
      }

      // Import Budgets
      if (excel.tables.keys.contains('Budgets')) {
        var sheet = excel.tables['Budgets']!;
        for (var i = 1; i < sheet.maxRows; i++) {
          var row = sheet.row(i);
          if (row.isEmpty || row[0] == null) continue;

          final periodStr = row[1]?.value?.toString() ?? '';
          int year = DateTime.now().year;
          int month = DateTime.now().month;
          if (periodStr.contains('-')) {
            final parts = periodStr.split('-');
            if (parts.length >= 2) {
              year = int.tryParse(parts[0]) ?? year;
              month = int.tryParse(parts[1]) ?? month;
            }
          }

          final budget = Budget(
            id: row[0]?.value?.toString() ?? '',
            userId: '',
            category: row[2]?.value?.toString() ?? '',
            limitAmount: double.tryParse(row[3]?.value?.toString() ?? '') ?? 0.0,
            year: year,
            month: month,
            createdAt: _parseDate(row[4]?.value, fallback: DateTime.now()),
            updatedAt: _parseDate(row[5]?.value, fallback: DateTime.now()),
          );
          await LocalStorageService.budgetsBox.put(budget.id, budget);
          budgetsImported++;
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported $incomesImported incomes, $expensesImported expenses, $budgetsImported budgets successfully.')),
        );
      }
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import data: $e')),
        );
      }
    }
  }

  DateTime _parseDate(dynamic value, {DateTime? fallback}) {
    final parsed = _parseDateOrNull(value);
    return parsed ?? fallback ?? DateTime.now();
  }

  DateTime? _parseDateOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    try {
      // Clean up string that might have been exported as yyyy-MM-dd HH:mm
      return DateTime.parse(str);
    } catch (_) {
      try {
        // Fallback for some common Excel formats
        if (str.contains(' ')) {
          return DateTime.parse(str.replaceAll(' ', 'T'));
        }
      } catch (e) {
        // Ignore
      }
      return null;
    }
  }

  String? _parseStringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    return str;
  }
}
