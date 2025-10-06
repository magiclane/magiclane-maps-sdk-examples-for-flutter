// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';

class CustomDialog extends StatelessWidget {
  final String title;
  final String content;
  final String positiveButtonText;
  final String negativeButtonText;
  final VoidCallback onPositivePressed;
  final VoidCallback onNegativePressed;

  const CustomDialog({
    super.key,
    required this.title,
    required this.content,
    required this.positiveButtonText,
    required this.negativeButtonText,
    required this.onPositivePressed,
    required this.onNegativePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Center(child: Text(title)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [Text(content)],
      ),
      actions: [
        TextButton(
          child: Text(negativeButtonText),
          onPressed: () {
            onNegativePressed();
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: Text(positiveButtonText),
          onPressed: () {
            onPositivePressed();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
