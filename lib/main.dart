import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/screens/splash_screen.dart';
import 'package:smartcache/services/expense_service.dart';
import 'package:smartcache/services/budget_service.dart';
import 'package:smartcache/services/income_service.dart';
import 'package:smartcache/services/security_service.dart';
import 'package:smartcache/providers/expense_provider.dart';
import 'package:smartcache/providers/budget_provider.dart';
import 'package:smartcache/providers/income_provider.dart';
import 'package:smartcache/providers/user_provider.dart';
import 'package:smartcache/theme.dart';
import 'package:smartcache/services/local_storage_service.dart';
import 'package:smartcache/widgets/app_lifecycle_observer.dart';
import 'package:smartcache/providers/theme_provider.dart';

void main() async {
  // Ensure binding before setting system UI overlays
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Storage
  await LocalStorageService.init();

  // Initialize Theme Provider with saved preferences
  final themeProvider = await ThemeProvider.initialize();

  // Optional: Force transparent status bar globally on app start
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;

  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    final expenseService = ExpenseService();
    final budgetService = BudgetService();
    final incomeService = IncomeService();
    final securityService = SecurityService();

    return MultiProvider(
      providers: [
        // Security Service for biometrics/PIN lock
        Provider<SecurityService>.value(value: securityService),

        // Theme Provider for app-wide theme management (pre-initialized)
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),

        ChangeNotifierProvider(
          create: (_) => ExpenseProvider(expenseService),
        ),
        ChangeNotifierProvider(
          create: (_) => BudgetProvider(budgetService),
        ),
        ChangeNotifierProvider(
          create: (_) => IncomeProvider(incomeService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'SmartCache',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeProvider.flutterThemeMode,
          home: const SplashScreen(),

          // GLOBAL STATUS BAR FIX
          builder: (context, child) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return AnnotatedRegion<SystemUiOverlayStyle>(
              value: SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                // Android: Dark icons for light mode, Light icons for dark mode
                statusBarIconBrightness: isDark
                    ? Brightness.light
                    : Brightness.dark,
                // iOS: Light brightness (dark content) for light mode, Dark brightness (light content) for dark mode
                statusBarBrightness: isDark
                    ? Brightness.dark
                    : Brightness.light,
              ),
              child: AppLifecycleObserver(child: child!),
            );
          },
        ),
      ),
    );
  }
}
