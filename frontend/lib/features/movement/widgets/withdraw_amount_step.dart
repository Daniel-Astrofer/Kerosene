import 'package:flutter/material.dart';

/// A wrapper component that encapsulates the keystroke state for the withdraw amount steps.
/// It prevents the entire withdraw screen from rebuilding on every keystroke.
class WithdrawAmountStepWrapper extends StatefulWidget {
  final String initialAmount;
  final Widget Function(
    BuildContext context,
    String amount,
    ValueChanged<String> onAmountChanged,
  ) builder;

  const WithdrawAmountStepWrapper({
    super.key,
    required this.initialAmount,
    required this.builder,
  });

  @override
  State<WithdrawAmountStepWrapper> createState() =>
      _WithdrawAmountStepWrapperState();
}

class _WithdrawAmountStepWrapperState extends State<WithdrawAmountStepWrapper> {
  late String _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount;
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _amount, (newAmount) {
      setState(() {
        _amount = newAmount;
      });
    });
  }
}
