import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/pin_keypad.dart';
import 'lock_screen.dart' show kPinLength;

enum _Step { verifyCurrent, enterNew, confirmNew }

class SetPinScreen extends ConsumerStatefulWidget {
  /// When true, the user must enter their current PIN before setting a new one.
  final bool requireCurrentVerification;

  const SetPinScreen({super.key, this.requireCurrentVerification = false});

  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  late _Step _step;
  String _entered = '';
  String _firstPin = '';
  bool _isError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _step = widget.requireCurrentVerification ? _Step.verifyCurrent : _Step.enterNew;
  }

  String get _title {
    switch (_step) {
      case _Step.verifyCurrent:
        return 'Enter Current PIN';
      case _Step.enterNew:
        return 'Set a New PIN';
      case _Step.confirmNew:
        return 'Confirm PIN';
    }
  }

  void _onDigit(String digit) {
    if (_entered.length >= kPinLength) return;
    setState(() {
      _entered += digit;
      _isError = false;
    });
    if (_entered.length == kPinLength) {
      _handleComplete();
    }
  }

  void _onBackspace() {
    if (_entered.isEmpty) return;
    setState(() => _entered = _entered.substring(0, _entered.length - 1));
  }

  Future<void> _handleComplete() async {
    final notifier = ref.read(settingsProvider.notifier);

    switch (_step) {
      case _Step.verifyCurrent:
        if (notifier.verifyPin(_entered)) {
          setState(() {
            _step = _Step.enterNew;
            _entered = '';
          });
        } else {
          _showError('Incorrect PIN');
        }
        break;
      case _Step.enterNew:
        _firstPin = _entered;
        setState(() {
          _step = _Step.confirmNew;
          _entered = '';
        });
        break;
      case _Step.confirmNew:
        if (_entered == _firstPin) {
          await notifier.setPin(_entered);
          if (mounted) Navigator.pop(context, true);
        } else {
          _showError("PINs didn't match — try again");
          setState(() {
            _step = _Step.enterNew;
            _firstPin = '';
          });
        }
        break;
    }
  }

  void _showError(String message) {
    setState(() {
      _isError = true;
      _errorMessage = message;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _entered = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Lock')),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            Text(_title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            PinDots(length: kPinLength, filled: _entered.length, color: _isError ? Colors.red : null),
            const SizedBox(height: 8),
            SizedBox(
              height: 20,
              child: _isError
                  ? Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13))
                  : null,
            ),
            const Spacer(flex: 1),
            NumericKeypad(onDigit: _onDigit, onBackspace: _onBackspace),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }
}
