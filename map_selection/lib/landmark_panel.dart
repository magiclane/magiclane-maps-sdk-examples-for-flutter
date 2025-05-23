// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:gem_kit/core.dart';

import 'package:flutter/material.dart';

class LandmarkPanel extends StatelessWidget {
  final VoidCallback onCancelTap;

  final Landmark landmark;

  const LandmarkPanel({
    super.key,
    required this.onCancelTap,
    required this.landmark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      width: MediaQuery.of(context).size.width,
      color: Colors.white,
      child: ListTile(
        leading: Container(
          height: 70,
          width: 70,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: landmark.getImage() != null
              ? Image.memory(
                  landmark.getImage(size: Size(128, 128))!,
                  width: 128,
                  height: 128,
                )
              : SizedBox(),
        ),
        title: Text(
          landmark.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          landmark.categories.isNotEmpty ? landmark.categories.first.name : '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onCancelTap,
          icon: const Icon(Icons.cancel, size: 30),
        ),
      ),
    );
  }
}
