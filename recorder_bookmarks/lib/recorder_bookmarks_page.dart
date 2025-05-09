// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: BSD-3-Clause
//
// Contact Magic Lane at <info@magiclane.com> for commercial licensing options.

import 'package:flutter/material.dart';
import 'package:gem_kit/sense.dart';

/// A simple page that displays a list of LogMetadata entries
/// in plain black text on a white background.
class RecorderBookmarksPage extends StatefulWidget {
  final RecorderBookmarks recorderBookmarks;

  const RecorderBookmarksPage({super.key, required this.recorderBookmarks});

  @override
  State<RecorderBookmarksPage> createState() => _RecorderBookmarksPageState();
}

class _RecorderBookmarksPageState extends State<RecorderBookmarksPage> {
  late List<String> _logs;

  @override
  void initState() {
    super.initState();
    _logs = widget.recorderBookmarks.getLogsList();
  }

  void _deleteLogAt(int index) {
    final removed = _logs.removeAt(index);
    widget.recorderBookmarks.deleteLog(removed);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recordings', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple[900],
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: ListView.separated(
        itemCount: _logs.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final metadata = widget.recorderBookmarks.getLogMetadata(_logs[i]);
          return LogItem(
            logMetadata: metadata,
            onDelete: () => _deleteLogAt(i),
          );
        },
      ),
    );
  }
}

class LogItem extends StatelessWidget {
  final VoidCallback onDelete;
  const LogItem({super.key, required this.logMetadata, required this.onDelete});

  final LogMetadata logMetadata;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Start: ${DateTime.fromMillisecondsSinceEpoch(logMetadata.startTimestampInMillis).toLocal()}',
              ),
              const SizedBox(height: 4),
              Text(
                'End: ${DateTime.fromMillisecondsSinceEpoch(logMetadata.endTimestampInMillis).toLocal()}',
              ),
              const SizedBox(height: 4),
              Text(
                'Duration: ${Duration(milliseconds: logMetadata.durationMillis)}',
              ),
              const SizedBox(height: 4),
              Text(
                'Start Pos: '
                '${logMetadata.startPosition.latitude.toStringAsFixed(5)}, '
                '${logMetadata.startPosition.longitude.toStringAsFixed(5)}',
              ),
              const SizedBox(height: 4),
              Text(
                'End Pos: '
                '${logMetadata.endPosition.latitude.toStringAsFixed(5)}, '
                '${logMetadata.endPosition.longitude.toStringAsFixed(5)}',
              ),
            ],
          ),
          IconButton(onPressed: onDelete, icon: Icon(Icons.delete)),
        ],
      ),
    );
  }
}
