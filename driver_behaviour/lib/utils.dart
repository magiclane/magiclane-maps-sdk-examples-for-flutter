// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  return [
    if (hours > 0) '${hours}h',
    if (minutes > 0) '${minutes}m',
    '${seconds}s',
  ].join(' ');
}

String formatPercent(double value) => '${value.toStringAsFixed(1)}%';
