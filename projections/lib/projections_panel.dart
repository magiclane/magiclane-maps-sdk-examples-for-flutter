// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/projections.dart';

class ProjectionsPanel extends StatelessWidget {
  final WGS84Projection? wgsProjection;
  final MGRSProjection? mgrsProjection;
  final UTMProjection? utmProjection;
  final LAMProjection? lamProjection;
  final W3WProjection? w3wProjection;
  final GKProjection? gkProjection;
  final BNGProjection? bngProjection;
  final VoidCallback onClose;
  const ProjectionsPanel({
    super.key,
    this.wgsProjection,
    this.mgrsProjection,
    this.utmProjection,
    this.lamProjection,
    this.w3wProjection,
    this.gkProjection,
    this.bngProjection,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: Colors.white,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(
              bottom: 50.0,
              left: 20.0,
              right: 20.0,
              top: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WGS84: ${wgsProjection!.coordinates!.latitude.toStringAsFixed(6)}, ${wgsProjection!.coordinates!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.black, fontSize: 16),
                ),
                (bngProjection != null)
                    ? Text(
                        'BNG: ${bngProjection!.easting.toStringAsFixed(4)}, ${bngProjection!.northing.toStringAsFixed(4)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )
                    : const Text(
                        'BNG: Not available',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                (utmProjection != null)
                    ? Text(
                        'UTM: ${utmProjection!.x.toStringAsFixed(2)}, ${utmProjection!.y.toStringAsFixed(2)}, zone: ${utmProjection!.zone}, ${utmProjection!.hemisphere}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )
                    : const Text(
                        'UTM: Not available',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                (mgrsProjection != null)
                    ? Text(
                        'MGRS: ${mgrsProjection!.zone}, ${mgrsProjection!.letters}, ${mgrsProjection!.easting.toStringAsFixed(2)}, ${mgrsProjection!.northing.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )
                    : const Text(
                        'MGRS: Not available',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                (lamProjection != null)
                    ? Text(
                        'LAM: ${lamProjection!.x.toStringAsFixed(2)}, ${lamProjection!.y.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )
                    : const Text(
                        'LAM: Not available',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                (w3wProjection != null)
                    ? Text(
                        'W3W: ${w3wProjection!.words}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )
                    : const Text(
                        'W3W: Not available',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                (gkProjection != null)
                    ? Text(
                        'GK: ${gkProjection!.easting.toStringAsFixed(2)}, ${gkProjection!.northing.toStringAsFixed(2)}, zone: ${gkProjection!.zone}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      )
                    : const Text(
                        'GK: Not available',
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.black),
            onPressed: onClose,
          ),
        ),
      ],
    );
  }
}
