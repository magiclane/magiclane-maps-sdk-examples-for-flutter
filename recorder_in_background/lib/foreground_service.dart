// SPDX-FileCopyrightText: 1995-2025 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: Apache-2.0
//
// Contact Magic Lane at <info@magiclane.com> for SDK licensing options.

import 'dart:io';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
class AndroidForegroundService {
  static final service = FlutterBackgroundService();
  static final notificationsPlugin = FlutterLocalNotificationsPlugin();
  static final notificationId = 888;
  static bool hasGrantedNotificationsPermission = false;
  static late final AndroidNotificationChannel channel;

  @pragma('vm:entry-point')
  static Future<void> initialize(bool isForegroundMode) async {
    if (!Platform.isAndroid) return;

    const initSettingsAndroid = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const initSettings = InitializationSettings(android: initSettingsAndroid);

    await notificationsPlugin.initialize(initSettings);

    channel = AndroidNotificationChannel(
      notificationId.toString(),
      'MY FOREGROUND SERVICE',
      description: 'This channel is used for background location.',
      importance: Importance.low,
    );

    hasGrantedNotificationsPermission = await notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false;

    if (!hasGrantedNotificationsPermission) {
      return;
    }

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await service.configure(
      iosConfiguration: IosConfiguration(),
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        autoStartOnBoot: false,
        isForegroundMode: isForegroundMode,
        notificationChannelId: notificationId.toString(),
        foregroundServiceNotificationId: notificationId,
        initialNotificationTitle: 'Background location',
        initialNotificationContent: 'Background location is active',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
    );
  }

  @pragma('vm:entry-point')
  static Future<bool> hasGrantedPermission() async {
    if (!Platform.isAndroid) return false;

    return hasGrantedNotificationsPermission = await notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.areNotificationsEnabled() ??
        false;
  }

  @pragma('vm:entry-point')
  static Future<bool> start() async {
    if (!Platform.isAndroid) return false;
    final service = FlutterBackgroundService();
    return await service.startService();
  }

  @pragma('vm:entry-point')
  static Future<void> stop() async {
    if (!Platform.isAndroid) return;
    service.invoke("stopService");

    await notificationsPlugin.cancelAll();
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return false;
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    if (!Platform.isAndroid) return;
    service.on("stopService").listen((event) {
      service.stopSelf();
    });
  }

  static Future<void> updateNotification({
    required String title,
    int? progress,
  }) async {
    if (!Platform.isAndroid) return;
    if (!(await service.isRunning())) {
      await start();
    }

    notificationsPlugin.show(
      notificationId,
      title,
      '',
      NotificationDetails(
        android: AndroidNotificationDetails(
          notificationId.toString(),
          channel.name,
          showProgress: progress != null,
          progress: progress ?? 0,
          maxProgress: 100,
          channelShowBadge: false,
          importance: Importance.max,
          priority: Priority.high,
          onlyAlertOnce: true,
          icon: 'ic_bg_service_small',
          // color: Color(0xFF754EFF),
        ),
      ),
    );
  }
}
