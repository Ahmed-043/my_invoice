import 'dart:async';
import 'package:flutter/material.dart';

class DeleteConfirmationDialog extends StatefulWidget {
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({super.key, required this.onConfirm});

  @override
  State<DeleteConfirmationDialog> createState() => _DeleteConfirmationDialogState();
}

class _DeleteConfirmationDialogState extends State<DeleteConfirmationDialog> {
  int _secondsRemaining = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _secondsRemaining == 0;

    return AlertDialog(
      title: const Text('Delete Invoice?'),
      content: const Text('This action cannot be undone. All services linked to this invoice will be removed.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: canDelete ? widget.onConfirm : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canDelete ? Colors.red : Colors.grey.shade300,
            foregroundColor: Colors.white,
          ),
          child: Text(canDelete ? 'Delete Now' : 'Wait ($_secondsRemaining)'),
        ),
      ],
    );
  }
}
