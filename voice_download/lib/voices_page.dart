// Copyright (C) 2019-2024, Magic Lane B.V.
// All rights reserved.
//
// This software is confidential and proprietary information of Magic Lane
// ("Confidential Information"). You shall not disclose such Confidential
// Information and shall use it only in accordance with the terms of the
// license agreement you entered into with Magic Lane.

import 'package:gem_kit/content_store.dart';
import 'package:gem_kit/core.dart';

import 'voices_item.dart';

import 'package:flutter/material.dart';

import 'dart:async';

class VoicesPage extends StatefulWidget {
  const VoicesPage({super.key});

  @override
  State<VoicesPage> createState() => _VoicesPageState();
}

class _VoicesPageState extends State<VoicesPage> {
  List<ContentStoreItem> voicesList = [];

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
          "Voices List",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple[900],
      ),
      body: FutureBuilder<List<ContentStoreItem>>(
          future: _getVoices(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return Scrollbar(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: snapshot.data!.length,
                separatorBuilder: (context, index) => const Divider(
                  indent: 50,
                  height: 0,
                ),
                itemBuilder: (context, index) {
                  final voice = snapshot.data!.elementAt(index);
                  return VoicesItem(voice: voice);
                },
              ),
            );
          }),
    );
  }

  // Method to load the voices
  Future<List<ContentStoreItem>> _getVoices() async {
    Completer<List<ContentStoreItem>> voicesList =
        Completer<List<ContentStoreItem>>();
    await ContentStore.asyncGetStoreContentList(ContentType.humanVoice,
        (err, items, isCached) {
      if (err == GemError.success && items != null) {
        voicesList.complete(items);
      }
    });
    return voicesList.future;
  }
}
