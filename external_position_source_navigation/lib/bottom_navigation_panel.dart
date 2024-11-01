// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:flutter/material.dart';

class NavigationBottomPanel extends StatelessWidget {
  final String remainingDuration;
  final String remainingDistance;
  final String eta;

  const NavigationBottomPanel({
    super.key,
    required this.remainingDuration,
    required this.remainingDistance,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 5,
            blurRadius: 7,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      width: MediaQuery.of(context).size.width - 20,
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            remainingDuration,
            style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.w500),
          ),
          Text(
            eta,
            style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.w500),
          ),
          Text(
            remainingDistance,
            style: const TextStyle(
                color: Colors.black, fontSize: 24, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
