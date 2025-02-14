// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/search.dart';

class LocationWikipediaPage extends StatefulWidget {
  const LocationWikipediaPage({super.key});

  @override
  State<LocationWikipediaPage> createState() => _LocationWikipediaPageState();
}

class _LocationWikipediaPageState extends State<LocationWikipediaPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        foregroundColor: Colors.white,
        title: const Text(
          "Location Wikipedia",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder(
        future: _getLocationWikipedia(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Text(
                snapshot.data!.$1,
                style: TextStyle(
                  overflow: TextOverflow.fade,
                  fontSize: 25.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(child: Text(snapshot.data!.$2)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<(String, String)> _getLocationWikipedia() async {
    final searchCompleter = Completer<List<Landmark>>();
    SearchService.search(
      "Statue of Liberty",
      Coordinates(latitude: 0.0, longitude: 0.0),
      (err, lmks) {
        searchCompleter.complete(lmks);
      },
    );

    final lmk = (await searchCompleter.future).first;

    final completer = Completer<ExternalInfo?>();

    ExternalInfo.getExternalInfo(
      lmk,
      onWikiDataAvailable: (externalInfo) => completer.complete(externalInfo),
    );

    final externalInfo = await completer.future;
    final title = externalInfo!.getWikiPageTitle();
    final content = externalInfo.getWikiPageDescription();

    return (title, content);
  }
}
