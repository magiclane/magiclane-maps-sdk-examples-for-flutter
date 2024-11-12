// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:flutter/material.dart';
import 'package:gem_kit/core.dart';
import 'package:gem_kit/map.dart';
import 'package:location_wikipedia/location_wikipedia_page.dart';

const projectApiToken = String.fromEnvironment('GEM_TOKEN');

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Location Wikipedia',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void dispose() {
    GemKit.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        title: const Text('Location Wikipedia',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
              onPressed: () => _onLocationWikipediaTap(context),
              icon: Icon(
                Icons.search,
                color: Colors.white,
              ))
        ],
      ),
      body: const GemMap(
        appAuthorization: projectApiToken,
      ),
    );
  }

  void _onLocationWikipediaTap(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<dynamic>(
      builder: (context) => const LocationWikipediaPage(),
    ));
  }
}
