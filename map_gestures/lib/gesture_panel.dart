// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';

class GesturePanel extends StatelessWidget {
  final String gesture;
  const GesturePanel({super.key, required this.gesture});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.04,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [Text(gesture), const SizedBox(width: 10)],
      ),
    );
  }
}
