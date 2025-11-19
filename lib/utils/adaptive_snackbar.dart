import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Адаптивная функция для показа уведомлений
/// На iOS показывает CupertinoAlertDialog с автоматическим закрытием, на Android - SnackBar
void showAdaptiveSnackBar(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration duration = const Duration(seconds: 2),
}) {
  if (Platform.isIOS) {
    // Для iOS показываем CupertinoAlertDialog как уведомление
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    // Автоматически закрываем через duration
    Future.delayed(duration, () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
  } else {
    // Для Android используем стандартный SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }
}

