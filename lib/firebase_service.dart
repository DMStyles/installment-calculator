import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Handles all Firebase initialization, Firestore sync, and FCM token management.
class FirebaseService {
  FirebaseService._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static FirebaseMessaging get _fcm => FirebaseMessaging.instance;

  static String? _deviceToken;
  static String? get deviceToken => _deviceToken;

  // ─── Init ─────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Firebase.initializeApp();

    // Request notification permission
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('[FCM] Permission: ${settings.authorizationStatus}');
    }

    // Get & store FCM token
    _deviceToken = await _fcm.getToken();
    if (kDebugMode) print('[FCM] Token: $_deviceToken');

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      _deviceToken = newToken;
      if (kDebugMode) print('[FCM] Token refreshed: $newToken');
    });
  }

  // ─── Firestore: Installments ───────────────────────────────────────────────

  /// The Firestore document for this device (keyed by FCM token).
  static DocumentReference? get _deviceDoc {
    if (_deviceToken == null) return null;
    return _db.collection('devices').doc(_deviceToken);
  }

  /// Saves a full installment entry to Firestore.
  static Future<void> saveInstallment(Map<String, dynamic> data) async {
    final doc = _deviceDoc;
    if (doc == null) return;
    try {
      // Convert Color objects — they can't be stored in Firestore
      final clean = _sanitizeForFirestore(data);
      await doc.collection('installments').doc(data['id']).set(clean);
    } catch (e) {
      if (kDebugMode) print('[Firestore] saveInstallment error: $e');
    }
  }

  /// Updates a single payment's isPaid status in Firestore.
  static Future<void> updatePaymentStatus(
      String installmentId, int paymentIndex, bool isPaid) async {
    final doc = _deviceDoc;
    if (doc == null) return;
    try {
      final ref =
          doc.collection('installments').doc(installmentId);
      final snapshot = await ref.get();
      if (!snapshot.exists) return;

      final List<dynamic> payments =
          List.from((snapshot.data() as Map)['payments'] ?? []);
      if (paymentIndex < payments.length) {
        payments[paymentIndex]['isPaid'] = isPaid;
        await ref.update({'payments': payments});
      }
    } catch (e) {
      if (kDebugMode) print('[Firestore] updatePaymentStatus error: $e');
    }
  }

  /// Deletes an installment from Firestore.
  static Future<void> deleteInstallment(String installmentId) async {
    final doc = _deviceDoc;
    if (doc == null) return;
    try {
      await doc.collection('installments').doc(installmentId).delete();
    } catch (e) {
      if (kDebugMode) print('[Firestore] deleteInstallment error: $e');
    }
  }

  /// Updates device preferences on Firestore.
  static Future<void> updateDeviceSettings({
    required bool enabled,
    required int leadDays,
  }) async {
    final doc = _deviceDoc;
    if (doc == null) return;
    try {
      await doc.set({
        'notificationsEnabled': enabled,
        'notificationLeadDays': leadDays,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) print('[Firestore] updateDeviceSettings error: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  /// Removes Dart-only types (Color, IconData) that Firestore can't store.
  static Map<String, dynamic> _sanitizeForFirestore(Map<String, dynamic> data) {
    final result = <String, dynamic>{};
    for (final entry in data.entries) {
      final v = entry.value;
      // Skip Flutter-only types
      if (v.runtimeType.toString().contains('Color')) continue;
      if (v.runtimeType.toString().contains('IconData')) continue;
      if (v is Map) {
        result[entry.key] = _sanitizeForFirestore(Map<String, dynamic>.from(v));
      } else if (v is List) {
        result[entry.key] = v.map((item) {
          if (item is Map) {
            return _sanitizeForFirestore(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        result[entry.key] = v;
      }
    }
    return result;
  }
}
