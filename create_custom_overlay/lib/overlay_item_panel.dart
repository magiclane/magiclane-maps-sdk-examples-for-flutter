// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/map.dart';

class OverlayItemPanel extends StatelessWidget {
  final VoidCallback onCancelTap;

  final OverlayItem overlayItem;

  const OverlayItemPanel({super.key, required this.onCancelTap, required this.overlayItem});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width - 20,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: overlayItem.img.isValid
                ? Image.memory(overlayItem.img.getRenderableImageBytes(size: Size(50, 50))!)
                : SizedBox(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 150,
                child: Row(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width - 150,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            overlayItem.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 5),
                          // Show data in key-value pair structure
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(
                              overlayItem.previewDataParameterList.map((kv) => '${kv.key}: ${kv.value}').join(', '),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${overlayItem.coordinates.latitude.toString()}, ${overlayItem.coordinates.longitude.toString()}',
                            maxLines: 2,
                            overflow: TextOverflow.visible,
                            style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onCancelTap,
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
