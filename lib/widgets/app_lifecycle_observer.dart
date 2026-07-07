import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartcache/services/security_service.dart';

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;

  const AppLifecycleObserver({super.key, required this.child});

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  bool _showPrivacyScreen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final securityService = context.read<SecurityService>();
    // Fast synchronous check using the cached getter
    final isSecurityEnabled = securityService.isSecurityEnabled;

    if (!isSecurityEnabled) {
      if (_showPrivacyScreen) {
        setState(() => _showPrivacyScreen = false);
      }
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Show privacy screen immediately to hide content in Recents
      if (!_showPrivacyScreen) {
        setState(() => _showPrivacyScreen = true);
      }
    } else if (state == AppLifecycleState.resumed) {
      _checkDeviceSecurity();
    }
  }

  Future<void> _checkDeviceSecurity() async {
    final securityService = context.read<SecurityService>();

    // Check if we are already authenticating or just finished
    if (securityService.isAuthenticating) return;

    final lastAuth = securityService.lastAuthTime;
    if (lastAuth != null) {
      final diff = DateTime.now().difference(lastAuth);
      if (diff < const Duration(seconds: 3)) {
        // Recently authenticated, remove overlay
        if (_showPrivacyScreen) {
          setState(() => _showPrivacyScreen = false);
        }
        return;
      }
    }

    final enabled = await securityService.getDeviceSecurityEnabled();
    if (enabled) {
      // Ensure overlay is shown
      if (!_showPrivacyScreen) {
        setState(() => _showPrivacyScreen = true);
      }

      // Trigger authentication
      final authenticated = await securityService.authenticateWithBiometrics();
      if (mounted) {
        if (authenticated) {
          setState(() => _showPrivacyScreen = false);
        }
        // If failed/cancelled, keep privacy screen shown
      }
    } else {
      if (_showPrivacyScreen) {
        setState(() => _showPrivacyScreen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showPrivacyScreen)
          Positioned.fill(
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/logo_matic.png',
                      width: 80,
                      height: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Locked',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
