library;

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  // Unique notification ID.
  final String? id;
  // The person who should receive this alert.
  final String userId;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? type;
  final String? title;
  final String? body;
  final String? requestId;

  NotificationModel({
    this.id,
    required this.userId,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.type,
    this.title,
    this.body,
    this.requestId,
  });

  /// STEP: Reconstructs a 'NotificationModel' from database data.
  factory NotificationModel.fromMap(
    Map<String, dynamic> data,
    String documentId,
  ) {
    return NotificationModel(
      id: documentId,
      userId: data['userId'] ?? '',
      message: data['message'] ?? '',
      isRead: data['isRead'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: data['type'],
      title: data['title'],
      body: data['body'],
      requestId: data['requestId'],
    );
  }

  /// STEP: Prepares the notification for storage in the database.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'message': message,
      'isRead': isRead,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type,
      'title': title,
      'body': body,
      'requestId': requestId,
    };
  }
}

/// FILE: notification_model.dart
///
/// DESCRIPTION:
/// This file defines the 'NotificationModel', used to send alerts and updates
/// to users (e.g., "Your donation request has been approved!").
///
/// DATA FLOW OVERVIEW:
/// 1. RECEIVES DATA FROM:
///    - Firestore (via 'fromMap'): Fetches from the 'notifications' collection.
///    - System Logic: Created automatically when a blood request status changes.
/// 2. PROCESSING:
///    - Stores the 'message' text for the user.
///    - Tracks 'isRead' status to show unread badges in the UI.
/// 3. SENDS DATA TO:
///    - Firestore (via 'toMap'): Saves the alert for the user to see later.
///    - Notification UI: Displays the list of alerts to the user.
