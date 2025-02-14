// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

class Section {
  final Enum type;
  int length;
  double percent;

  Section({required this.type}) : length = 0, percent = 0;
}
