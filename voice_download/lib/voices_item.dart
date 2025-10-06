// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

// ignore_for_file: avoid_print

import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

import 'package:flutter/material.dart';

class VoicesItem extends StatefulWidget {
  final ContentStoreItem voice;

  const VoicesItem({super.key, required this.voice});

  @override
  State<VoicesItem> createState() => _VoicesItemState();
}

class _VoicesItemState extends State<VoicesItem> {
  late bool _isDownloaded;

  double _downloadProgress = 0;

  @override
  void initState() {
    super.initState();

    _isDownloaded = widget.voice.isCompleted;
    _downloadProgress = widget.voice.downloadProgress.toDouble();

    //If the voice is downloading pause and start downloading again
    //so the progress indicator updates value from callback
    if (_isDownloadingOrWaiting()) {
      widget.voice.pauseDownload(
        onComplete: (err) {
          if (err == GemError.success) {
            _downloadVoice();
          } else {
            print("Download pause for item ${widget.voice.id} failed with code $err");
          }
        },
      );
    }
  }

  bool _isDownloadingOrWaiting() {
    final status = widget.voice.status;
    return [
      ContentStoreItemStatus.downloadQueued,
      ContentStoreItemStatus.downloadRunning,
      ContentStoreItemStatus.downloadWaitingNetwork,
      ContentStoreItemStatus.downloadWaitingFreeNetwork,
      ContentStoreItemStatus.downloadWaitingNetwork,
    ].contains(status);
  }

  @override
  Widget build(BuildContext context) {
    Img countryImg = _getCountryImage(widget.voice)!;
    return Row(
      children: [
        Expanded(
          child: ListTile(
            onTap: _onTileTap,
            leading: Container(
              padding: const EdgeInsets.all(8),
              width: 50,
              child: countryImg.isValid
                  ? Image.memory(countryImg.getRenderableImageBytes(size: Size(80, 80))!, gaplessPlayback: true)
                  : SizedBox(),
            ),
            title: Text(
              '${widget.voice.name} (${(widget.voice.totalSize / (1024.0 * 1024.0)).toStringAsFixed(2)} MB)',
              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${widget.voice.getContentParametersAs<VoiceParameters>()?.nativeLanguage} - ${widget.voice.getContentParametersAs<VoiceParameters>()?.gender}',
              style: const TextStyle(color: Colors.black, fontSize: 16),
            ),
            trailing: SizedBox.square(
              dimension: 50,
              child: Builder(
                builder: (context) {
                  if (_isDownloaded == true) {
                    return const Icon(Icons.download_done, color: Colors.green);
                  } else if (_isDownloadingOrWaiting()) {
                    return SizedBox(
                      height: 10,
                      child: CircularProgressIndicator(
                        value: _downloadProgress / 100,
                        color: Colors.blue,
                        backgroundColor: Colors.grey.shade300,
                      ),
                    );
                  } else if (widget.voice.status == ContentStoreItemStatus.paused) {
                    return const Icon(Icons.pause);
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
        if (_isDownloaded)
          IconButton(
            onPressed: () => _deleteVoice(widget.voice),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.delete),
          ),
      ],
    );
  }

  // Method that returns the image of the country
  Img? _getCountryImage(ContentStoreItem voice) {
    final countryCodes = voice.countryCodes;
    final countryImage = MapDetails.getCountryFlagImg(countryCodes[0]);
    return countryImage;
  }

  void _onTileTap() {
    if (_isDownloaded == true) return;

    if (_isDownloadingOrWaiting()) {
      _pauseDownload();
      return;
    }

    _downloadVoice();
  }

  void _downloadVoice() {
    // Download the voice.
    widget.voice.asyncDownload(
      _onVoiceDownloadFinished,
      onProgress: _onVoiceDownloadProgressUpdated,
      allowChargedNetworks: true,
    );
  }

  void _pauseDownload() {
    // Pause the download.
    widget.voice.pauseDownload();

    setState(() {});
  }

  void _onVoiceDownloadProgressUpdated(int progress) {
    if (mounted) {
      setState(() => _downloadProgress = progress.toDouble());
    }
  }

  void _onVoiceDownloadFinished(GemError err) {
    // If there is no error, we change the state
    if (err == GemError.success && mounted) {
      setState(() => _isDownloaded = true);
    }
  }

  void _deleteVoice(ContentStoreItem map) {
    final deletedSuccesfully = map.deleteContent() == GemError.success;
    if (deletedSuccesfully) {
      setState(() {
        _isDownloaded = false;
        _downloadProgress = 0;
      });
    }
  }
}
