import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/pin_keypad.dart';

const int kPinLength = 4;

class LockScreen extends ConsumerStatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with SingleTickerProviderStateMixin {
  String _entered = '';
  bool _isError = false;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigit(String digit) {
    if (_entered.length >= kPinLength) return;
    setState(() {
      _entered += digit;
      _isError = false;
    });
    if (_entered.length == kPinLength) {
      _checkPin();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  void _checkPin() {
    final notifier = ref.read(settingsProvider.notifier);
    if (notifier.verifyPin(_entered)) {
      widget.onUnlocked();
    } else {
      setState(() => _isError = true);
      _shakeController.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _entered = '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/branding/logo.png', width: 72, height: 72),
            ),
            const SizedBox(height: 12),
            const Text('Pocket Ledger', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Enter PIN',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.65),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final offset = _isError
                    ? (16 * (1 - _shakeController.value)) *
                        ((_shakeController.value * 10).floor().isEven ? 1 : -1)
                    : 0.0;
                return Transform.translate(offset: Offset(offset, 0), child: child);
              },
              child: PinDots(
                length: kPinLength,
                filled: _entered.length,
                color: _isError ? Colors.red : null,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: _isError
                  ? const Text('Incorrect PIN', style: TextStyle(color: Colors.red, fontSize: 13))
                  : null,
            ),
            const Spacer(flex: 1),
            NumericKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
            const Spacer(flex: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              child: Text(
                'Forgot your PIN? It cannot be recovered — Pocket Ledger never stores or transmits it anywhere.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
