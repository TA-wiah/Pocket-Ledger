import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../shell/app_shell.dart';
import 'lock_screen.dart';

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key});

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isLocked = ref.read(isPinEnabledProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && ref.read(isPinEnabledProvider)) {
      setState(() => _isLocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLocked) {
      return LockScreen(onUnlocked: () => setState(() => _isLocked = false));
    }
    return const AppShell();
  }
}
