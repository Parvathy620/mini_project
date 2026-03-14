import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../features/service_provider/screens/sp_dashboard_screen.dart';
import '../../features/tourist/screens/tourist_dashboard_screen.dart';
import '../../features/admin/screens/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../../main.dart' show navigatorKey;
import 'package:flutter/material.dart';

// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Can initialize Firebase if necessary, but it's usually ready.
  if (kDebugMode) print("Handling a background message: ${message.messageId}");
}

class NotificationService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  StreamSubscription? _fcmSubscription;
  StreamSubscription? _fcmOpenedSubscription;
  StreamSubscription? _notificationsCountSubscription;
  
  int _unreadCount = 0;
  int get unreadCount => _unreadCount;
  String? _currentUserId;

  // Default User Settings
  Map<String, bool> _settings = {
    'newBookingAlerts': true,
    'bookingConfirmations': true,
    'bookingCancellations': true,
    'upcomingBookingReminders': true,
    'promotionalNotifications': false,
    'appUpdates': true,
  };

  Map<String, bool> get settings => _settings;

  NotificationService() {
    _initLocalNotifications();
  }

  // To be called when auth state changes to logged in
  Future<void> initializeForUser(String userId, {String? role}) async {
    if (_currentUserId == userId && role == null) return;
    _currentUserId = userId;
    
    String? finalRole = role;
    if (finalRole == null) {
      // Fetch role if not provided
      finalRole = await _fetchUserRole(userId);
    }
    
    _initializeFCM(userId, role: finalRole);
    _fetchSettings(userId);
    _listenToUnreadCount(userId);
  }

  Future<String?> _fetchUserRole(String userId) async {
    try {
      // 1. Check Admin
      final adminDoc = await _firestore.collection('admins').doc(userId).get();
      if (adminDoc.exists && (adminDoc.data() as Map<String, dynamic>)['role'] == 'admin') {
        return 'admin';
      }

      // 2. Check Service Provider
      final spDoc = await _firestore.collection('service_providers').doc(userId).get();
      if (spDoc.exists) {
        return 'provider';
      }

      // 3. Check Tourist
      final touristDoc = await _firestore.collection('tourists').doc(userId).get();
      if (touristDoc.exists) {
        return 'tourist';
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching role in NotificationService: $e');
    }
    return 'unknown';
  }

  void clearUserData() {
    _currentUserId = null;
    _fcmSubscription?.cancel();
    _fcmOpenedSubscription?.cancel();
    _notificationsCountSubscription?.cancel();
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (kDebugMode) print('Local notification tapped: ${details.payload}');
        _handleNotificationTap(details.payload);
      },
    );

    // Create High Importance Channel for Android
    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> requestPermissions() async {
    // FCM Permissions
    NotificationSettings fcmSettings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Local Notifications Permissions (specifically for Android 13+)
    if (defaultTargetPlatform == TargetPlatform.android) {
       await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    if (kDebugMode) print('User granted permission: ${fcmSettings.authorizationStatus}');
    
    // Attempt to register token once permissions are granted
    if (_currentUserId != null) {
       _saveDeviceToken(_currentUserId!);
    }
  }

  Future<void> _initializeFCM(String userId, {String? role}) async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    await _saveDeviceToken(userId, role: role);
    
    // Listen for Token Refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _updateTokenInFirestore(userId, newToken, role: role);
    });

    // Handle Foreground Messages
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) print('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Handle Background App Launch via tapped message
    _fcmOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) print('A new onMessageOpenedApp event was published!');
      _handleNotificationTap(message.data['relatedId']);
    });

    // Check for initial message (when app is launched from terminated state)
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) print('App launched from terminated state via notification');
        _handleNotificationTap(message.data['relatedId']);
      }
    });
  }

  Future<void> _handleNotificationTap(String? relatedId) async {
    if (navigatorKey.currentState == null) return;
    
    if (kDebugMode) print('Handling notification tap for relatedId: $relatedId');
    
    // Check user role and navigate to appropriate dashboard
    final prefs = await SharedPreferences.getInstance();
    final lastRoute = prefs.getString('last_route') ?? '';
    
    Widget? targetScreen;
    if (lastRoute == 'provider') targetScreen = SPDashboardScreen();
    else if (lastRoute == 'tourist') targetScreen = TouristDashboardScreen();
    else if (lastRoute == 'admin') targetScreen = DashboardScreen();
    
    if (targetScreen != null) {
      navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => targetScreen!),
        (route) => false,
      );
    }
  }

  Future<void> _saveDeviceToken(String userId, {String? role}) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenInFirestore(userId, token, role: role);
      }
    } catch (e) {
      if (kDebugMode) print("Error getting FCM token: $e");
    }
  }

  Future<void> _updateTokenInFirestore(String userId, String token, {String? role}) async {
    final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios');
    
    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
      'tokenUpdatedAt': FieldValue.serverTimestamp(),
      'userRole': role ?? 'unknown',
      'platform': platform,
      'lastUpdated': FieldValue.serverTimestamp(),
      'userId': userId,
    }, SetOptions(merge: true));
    
    if (kDebugMode) print('FCM token generated and saved for user: $userId (Role: $role)');
  }

  void _showLocalNotification(RemoteMessage message) {
    // Generate unique ID
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel', 
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      // Add more customization if needed
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final notifDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

    _localNotifications.show(
      id,
      message.notification?.title ?? 'New Notification',
      message.notification?.body,
      notifDetails,
      payload: message.data['relatedId'] ?? message.data['type'], 
    );
    
    if (kDebugMode) print('Foreground notification displayed: ${message.messageId}');
  }

  // --- Settings Management ---

  Future<void> _fetchSettings(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).collection('settings').doc('notifications').get();
    if (doc.exists && doc.data() != null) {
      _settings = Map<String, bool>.from(doc.data()!);
      notifyListeners();
    } else {
      // Save defaults
      updateSettings(userId, _settings);
    }
  }

  Future<void> updateSettings(String userId, Map<String, bool> newSettings) async {
    _settings = newSettings;
    notifyListeners();
    await _firestore.collection('users').doc(userId).collection('settings').doc('notifications').set(_settings);
  }

  Future<void> updateSettingToggle(String userId, String key, bool value) async {
    _settings[key] = value;
    notifyListeners();
    await _firestore.collection('users').doc(userId).collection('settings').doc('notifications').set({
      key: value
    }, SetOptions(merge: true));
  }

  // --- Notification Data Management ---

  void _listenToUnreadCount(String userId) {
    _notificationsCountSubscription?.cancel();
    _notificationsCountSubscription = _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      _unreadCount = snapshot.docs.length;
      notifyListeners();
    });
  }

  Stream<List<AppNotification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AppNotification.fromMap(doc.data())).toList());
  }

  Future<void> markAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }
  
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
        
    for (var doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    
    await batch.commit();
  }

  Future<void> deleteNotification(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  // Simulate a backend triggering a notification to a specific user
  Future<void> createInAppNotification({
    required String userId,
    required String title,
    required String body,
    String type = 'system',
    String? relatedId,
  }) async {
    final docRef = _firestore.collection('notifications').doc();
    final notification = AppNotification(
      id: docRef.id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      createdAt: DateTime.now(),
      isRead: false,
      relatedId: relatedId,
    );
    await docRef.set(notification.toMap());
  }

  // --- Push Notification Sending (Simulated/Client-Side) ---

  Future<void> sendPushNotification({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Fetch Target User's FCM Token
      final userDoc = await _firestore.collection('users').doc(targetUserId).get();
      if (!userDoc.exists) {
        if (kDebugMode) print('No user document found for ID: $targetUserId');
        return;
      }

      final fcmToken = userDoc.data()?['fcmToken'];
      if (fcmToken == null) {
        if (kDebugMode) print('No FCM token found for user: $targetUserId');
        return;
      }

      // 2. In a real production app, you would call a Cloud Function or your backend here.
      // For this task, we'll log the "Sending" event.
      // To actually send from client, we'd need Service Account credentials.
      
      if (kDebugMode) {
        print('--- SENDING PUSH NOTIFICATION ---');
        print('To User ID: $targetUserId');
        print('Title: $title');
        print('Body: $body');
        print('Data: $data');
        print('Using Token: $fcmToken');
        print('---------------------------------');
      }

      // We still create the in-app notification document
      await createInAppNotification(
        userId: targetUserId,
        title: title,
        body: body,
        type: data?['type'] ?? 'system',
        relatedId: data?['relatedId'],
      );

    } catch (e) {
      if (kDebugMode) print('Error sending push notification: $e');
    }
  }

  Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Fetch all admin tokens
      final adminSnapshot = await _firestore
          .collection('users')
          .where('userRole', isEqualTo: 'admin')
          .get();

      for (var doc in adminSnapshot.docs) {
        await sendPushNotification(
          targetUserId: doc.id,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      if (kDebugMode) print('Error sending notification to admins: $e');
    }
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _fcmOpenedSubscription?.cancel();
    _notificationsCountSubscription?.cancel();
    super.dispose();
  }
}
