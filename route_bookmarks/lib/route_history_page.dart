import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/routing.dart';

class RouteHistoryPage extends StatefulWidget {
  final RouteBookmarks routeBookmarks;

  const RouteHistoryPage({super.key, required this.routeBookmarks});

  @override
  State<RouteHistoryPage> createState() => _RouteHistoryPageState();
}

class _RouteHistoryPageState extends State<RouteHistoryPage> {
  @override
  Widget build(BuildContext context) {
    final routeCount = widget.routeBookmarks.size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple[900],
        foregroundColor: Colors.white,
        title: const Text('Route History', style: TextStyle(color: Colors.white)),
        actions: [
          if (routeCount > 0)
            IconButton(
              onPressed: _onClearAllPressed,
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              tooltip: 'Clear all history',
            ),
        ],
      ),
      body: routeCount == 0
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.route, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No routes in history', style: TextStyle(fontSize: 18, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Calculate some routes to see them here', style: TextStyle(fontSize: 14, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: routeCount,
              itemBuilder: (context, index) {
                final name = widget.routeBookmarks.getName(index);
                final waypoints = widget.routeBookmarks.getWaypoints(index);
                final timestamp = widget.routeBookmarks.getTimestamp(index);

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    onTap: () => _onRouteTapped(index, waypoints),
                    leading: CircleAvatar(
                      backgroundColor: Colors.deepPurple[900],
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(name ?? 'Route ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (waypoints != null && waypoints.length >= 2) ...[
                          const SizedBox(height: 4),
                          Text(
                            'From: ${_formatCoordinates(waypoints.first.coordinates)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'To: ${_formatCoordinates(waypoints.last.coordinates)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                        if (timestamp != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Saved: ${_formatDate(timestamp)}',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _onDeletePressed(index, name),
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _onRouteTapped(int index, List<Landmark>? waypoints) {
    if (waypoints != null && waypoints.length >= 2) {
      // Pop with the selected route data
      Navigator.of(context).pop({'waypoints': waypoints, 'preferences': RoutePreferences()});
    }
  }

  String _formatCoordinates(Coordinates coords) {
    return '${coords.latitude.toStringAsFixed(4)}, ${coords.longitude.toStringAsFixed(4)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _onDeletePressed(int index, String? name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Route'),
        content: Text('Are you sure you want to delete "${name ?? 'Route ${index + 1}'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              widget.routeBookmarks.remove(index);
              Navigator.of(context).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Route deleted')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onClearAllPressed() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All History'),
        content: const Text('Are you sure you want to delete all routes from history?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              widget.routeBookmarks.clear();
              Navigator.of(context).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All routes deleted')));
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
