// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:intl/intl.dart';

class SocialEventPanel extends StatelessWidget {
  final OverlayItem overlayItem;
  final VoidCallback onClose;
  const SocialEventPanel({
    super.key,
    required this.overlayItem,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final overlayImg = overlayItem.img;
    return Container(
      width: MediaQuery.of(context).size.width - 40,
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: overlayImg.isValid
                        ? Image.memory(
                            overlayImg.getRenderableImageBytes(
                              size: Size(50, 50),
                              format: ImageFileFormat.png,
                            )!,
                          )
                        : const SizedBox(),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(overlayItem.name),
                      Text(
                        "Date: ${formatTimestamp(overlayItem.previewDataJson["parameters"]["create_stamp_utc"] as String)}",
                      ),
                      Text(
                        "Upvotes: ${overlayItem.previewDataJson["parameters"]["score"]}",
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(onPressed: onClose, icon: Icon(Icons.close)),
            ],
          ),
        ],
      ),
    );
  }

  String formatTimestamp(String timestampStr) {
    final timestamp = int.tryParse(timestampStr);
    if (timestamp == null) return "Invalid date";

    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('MM/dd/yyyy').format(date);
  }
}
