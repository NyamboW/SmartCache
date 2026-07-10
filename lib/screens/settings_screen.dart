import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/services/security_service.dart';
import 'package:smartcache/services/budget_service.dart';
import 'package:smartcache/services/expense_service.dart';
import 'package:smartcache/services/income_service.dart';
import 'package:smartcache/services/export_service.dart';
import 'package:smartcache/providers/theme_provider.dart';

import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool useDeviceSecurity = false;
  String appVersion = '';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final securityService = context.read<SecurityService>();
    final enabled = await securityService.getDeviceSecurityEnabled();
    if (mounted) {
      setState(() {
        useDeviceSecurity = enabled;
      });
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _toggleDeviceSecurity(bool value) async {
    final securityService = context.read<SecurityService>();

    if (value) {
      // Enabling security: Verify identity first
      final authenticated = await securityService.authenticateWithBiometrics();
      if (!authenticated) {
        _showMessage('Authentication failed or not available');
        return;
      }
    }

    // Save setting
    await securityService.setDeviceSecurityEnabled(value);

    if (mounted) {
      setState(() => useDeviceSecurity = value);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPrivacyPolicy() async {
    const url = 'https://attomaticsystems.com/privacy-policy';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final incomeService = IncomeService();
      final expenseService = ExpenseService();
      final budgetService = BudgetService();

      final exportService = ExportService(
        incomeService: incomeService,
        expenseService: expenseService,
        budgetService: budgetService,
      );

      await exportService.exportData(context);
    } catch (e) {
      if (mounted) {
        _showMessage('Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: context.textStyles.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Appearance
          _buildSectionHeader(context, 'Appearance'),
          Container(
            decoration: AppCardDecoration.surface(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: AppThemeMode.values.asMap().entries.map((entry) {
                final index = entry.key;
                final mode = entry.value;
                final isSelected = themeProvider.isCurrentMode(mode);
                return Column(
                  children: [
                    if (index > 0)
                      Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
                    ListTile(
                      leading: Icon(
                        mode.icon,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      title: Text(
                        mode.label,
                        style: context.textStyles.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: Radio<AppThemeMode>(
                        value: mode,
                        groupValue: themeProvider.themeMode,
                        onChanged: (value) {
                          if (value != null) {
                            themeProvider.setThemeMode(value);
                          }
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                      onTap: () {
                        themeProvider.setThemeMode(mode);
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // Security
          _buildSectionHeader(context, 'Security'),
          Container(
            decoration: AppCardDecoration.surface(context),
            clipBehavior: Clip.antiAlias,
            child: SwitchListTile(
              title: Text('Use device security', style: context.textStyles.bodyLarge),
              subtitle: Text('PIN, fingerprint, or face unlock', style: context.textStyles.bodySmall),
              value: useDeviceSecurity,
              onChanged: _toggleDeviceSecurity,
              secondary: Icon(
                FluentIcons.lock_closed_24_regular,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              activeColor: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 32),

          // Data Management
          _buildSectionHeader(context, 'Data Management'),
          Container(
            decoration: AppCardDecoration.surface(context),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                FluentIcons.arrow_download_24_regular,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              title: Text('Export Data to Excel', style: context.textStyles.bodyLarge),
              subtitle: Text('Backup budgets, income, and expenses', style: context.textStyles.bodySmall),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      FluentIcons.chevron_right_24_regular,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
              onTap: _isExporting ? null : _exportData,
            ),
          ),

          const SizedBox(height: 32),

          // Privacy
          _buildSectionHeader(context, 'Privacy & About'),
          Container(
            decoration: AppCardDecoration.surface(context),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    FluentIcons.shield_24_regular,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text('Privacy Policy', style: context.textStyles.bodyLarge),
                  trailing: Icon(
                    FluentIcons.open_24_regular,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: _openPrivacyPolicy,
                ),
                Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
                ListTile(
                  leading: Icon(
                    FluentIcons.info_24_regular,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text('App Version', style: context.textStyles.bodyLarge),
                  trailing: Text(
                    appVersion.isEmpty ? 'Loading…' : appVersion,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 48),

          // 🏷 Footer
          Center(
            child: Text(
              'SmartCache – Offline Budget Tracker',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
