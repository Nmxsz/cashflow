import 'package:flutter/material.dart';

class BankruptcyDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const BankruptcyDialog({
    Key? key,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Achtung: Bankrott!'),
      content: const Text(
        'Wenn du diese Aktion durchführst, wird dein Cashflow negativ und du gehst bankrott. '
        'Im Falle eines Bankrotts kannst du nicht mehr weiter spielen. '
        'Möchtest du diese Aktion wirklich durchführen?',
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: onConfirm,
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Trotzdem fortfahren'),
        ),
      ],
    );
  }
}
