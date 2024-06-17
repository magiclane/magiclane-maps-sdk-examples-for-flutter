// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

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
          child: Image.memory(
            landmark.getImage(),
          ),
        ),
        title: Text(
          landmark.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          landmark.categories.isNotEmpty ? landmark.categories.first.name : '',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800),
        ),
        trailing: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onCancelTap,
          icon: const Icon(
            Icons.cancel,
            size: 30,
          ),
        ),
      ),
    );
  }
}
