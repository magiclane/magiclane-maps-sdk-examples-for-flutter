// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

class Section {
  final Enum type;
  int length;
  double percent;

  Section({required this.type}) : length = 0, percent = 0;
}
