// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/routing.dart';

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
                    child: Image.memory(
                      overlayItem.img
                          .getRenderableImage(size: Size(50, 50))!
                          .bytes,
                      gaplessPlayback: true,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(overlayItem.name),
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
          TextButton(
            onPressed: () => _onVoteButtonPressed(context),
            child: Text("Confirm report"),
          ),
        ],
      ),
    );
  }

  void _onVoteButtonPressed(BuildContext context) {
    SocialOverlay.confirmReport(
      overlayItem,
      onComplete: (err) {
        _showSnackBar(
          context,
          message: "Confirm report status: $err",
          duration: Duration(seconds: 3),
        );
      },
    );
  }

  void _showSnackBar(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(hours: 1),
  }) {
    final snackBar = SnackBar(content: Text(message), duration: duration);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
