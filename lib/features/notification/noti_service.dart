import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:asthma_app/features/personalization/screens/settings/location.dart';
import 'package:flutter/material.dart';

class NotiService {
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Callback for notification tap
  void onNotificationTap(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    if (payload != null && payload == 'navigate_to_location') {
      Get.dialog(const LocationConfirmationDialog());
    }
    // You can handle other payloads or general taps here if needed
  }

  // Request notification permission
  Future<bool> requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.notification.request();
      return status.isGranted;
    }
    return false;
  }

  // Check if notification permission is granted
  Future<bool> isNotificationPermissionGranted() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      return status.isGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return false;
  }

  //  INITIALIZE
  Future<void> initNotification() async {
    if (_isInitialized) return; // prevent re-initialization

    try {
      // Check and request permission first
      final hasPermission = await isNotificationPermissionGranted();
      if (!hasPermission) {
        final granted = await requestNotificationPermission();
        if (!granted) {
          return; // Exit if permission not granted
        }
      }

      // prepare android init settings
      const initSettingsAndroid = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // init settings
      const initSettings = InitializationSettings(android: initSettingsAndroid);

      // finally, initialize the plugin!
      await notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
      );
      _isInitialized = true;
    } catch (e) {
      print('Error initializing notifications: $e');
      _isInitialized = false;
    }
  }

  // NOTIFICATIONS DETAIL SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_channel_id',
        'Daily Notification',
        icon: 'ic_stat_notify',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
  }

  // Medication warning notification details with red color
  NotificationDetails medicationWarningDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'medication_warning_channel_id',
        'Medication Warning',
        icon: 'ic_stat_notify',
        channelDescription: 'Medication Warning Channel',
        importance: Importance.max,
        priority: Priority.high,
        color: Color(0xFFFF0000), // Red color
        colorized: true,
        styleInformation:
            BigTextStyleInformation(''), // This helps with the background color
        enableLights: true,
        ledColor: Color(0xFFFF0000), // Red LED color
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initNotification();
    }

    try {
      // Check permission before showing notification
      if (!await isNotificationPermissionGranted()) {
        return;
      }
      return notificationsPlugin.show(id, title, body, notificationDetails(),
          payload: payload);
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  // Show medication usage warning
  Future<void> showMedicationUsageWarning({required String username}) async {
    if (!_isInitialized) {
      await initNotification();
    }

    try {
      // Check permission before showing notification
      if (!await isNotificationPermissionGranted()) {
        return;
      }
      return notificationsPlugin.show(
        1, // Using a different ID for medication warnings
        'High Medication Usage Warning',
        '$username has used Blue Inhaler Salbutamol more than 4 times today. Please proceed to the hospital immediately for further evaluation.',
        medicationWarningDetails(), // Using the new red notification details
        payload: 'navigate_to_location',
      );
    } catch (e) {
      print('Error showing medication warning: $e');
    }
  }

  // Show event tomorrow notification
  Future<void> showEventTomorrowNotification(
      {required String eventNames, required int eventCount}) async {
    if (!_isInitialized) {
      await initNotification();
    }

    try {
      // Check permission before showing notification
      if (!await isNotificationPermissionGranted()) {
        return;
      }
      String title =
          eventCount > 1 ? '$eventCount Events Reminder' : 'Event Reminder';
      String body = eventCount > 1
          ? 'You have $eventCount events tomorrow:\n$eventNames'
          : 'You have an event tomorrow:\n$eventNames';

      return notificationsPlugin.show(
        2, // Using a different ID for event notifications
        title,
        body,
        notificationDetails(),
        payload: 'navigate_to_events', // Example payload
      );
    } catch (e) {
      print('Error showing event tomorrow notification: $e');
    }
  }

  // ON NOTI TAP
}
