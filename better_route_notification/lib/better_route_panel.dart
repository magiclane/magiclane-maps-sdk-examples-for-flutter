// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';

class BetterRoutePanel extends StatelessWidget {
  final Duration travelTime;
  final Duration delay;
  final Duration timeGain;
  final VoidCallback onDismiss;

  const BetterRoutePanel({
    super.key,
    required this.travelTime,
    required this.delay,
    required this.timeGain,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(16),
        bottom: Radius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width - 20,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(16),
            bottom: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Better Route Detected',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Inline info row: Total travel time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total travel time:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text('${travelTime.inMinutes} min'),
              ],
            ),
            const SizedBox(height: 4),

            // Inline info row: Traffic delay
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Traffic delay:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text('${delay.inMinutes} min'),
              ],
            ),
            const SizedBox(height: 4),

            // Inline info row: Time gain
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Time gain:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Text('${timeGain.inMinutes} min'),
              ],
            ),
            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onDismiss,
                icon: const Icon(Icons.close),
                label: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
