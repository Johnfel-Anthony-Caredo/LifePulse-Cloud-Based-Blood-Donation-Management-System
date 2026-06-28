import 'package:amplify_flutter/amplify_flutter.dart';

enum NotificationType {
  BLOOD_REQUEST,
  APPOINTMENT_REMINDER,
  ELIGIBILITY_RESTORED,
  CAMPAIGN,
  SYSTEM,
}

enum NotificationPriority {
  LOW,
  MEDIUM,
  HIGH,
  URGENT,
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final bool isRead;
  final TemporalDateTime? readAt;
  final String? actionUrl;
  final String? metadata; // JSON string
  final TemporalDateTime? expiresAt;
  final TemporalDateTime? createdAt;
  final TemporalDateTime? updatedAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.isRead,
    this.readAt,
    this.actionUrl,
    this.metadata,
    this.expiresAt,
    this.createdAt,
    this.updatedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: _parseNotificationType(json['type'] as String),
      priority: _parseNotificationPriority(json['priority'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['isRead'] as bool,
      readAt: json['readAt'] != null ? TemporalDateTime.fromString(json['readAt'] as String) : null,
      actionUrl: json['actionUrl'] as String?,
      metadata: json['metadata'] as String?,
      expiresAt: json['expiresAt'] != null ? TemporalDateTime.fromString(json['expiresAt'] as String) : null,
      createdAt: json['createdAt'] != null ? TemporalDateTime.fromString(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? TemporalDateTime.fromString(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': typeDisplay,
      'priority': priorityDisplay,
      'title': title,
      'message': message,
      'isRead': isRead,
      if (readAt != null) 'readAt': readAt!.format(),
      if (actionUrl != null) 'actionUrl': actionUrl,
      if (metadata != null) 'metadata': metadata,
      if (expiresAt != null) 'expiresAt': expiresAt!.format(),
      if (createdAt != null) 'createdAt': createdAt!.format(),
      if (updatedAt != null) 'updatedAt': updatedAt!.format(),
    };
  }

  static NotificationType _parseNotificationType(String value) {
    switch (value) {
      case 'BLOOD_REQUEST':
        return NotificationType.BLOOD_REQUEST;
      case 'APPOINTMENT_REMINDER':
        return NotificationType.APPOINTMENT_REMINDER;
      case 'ELIGIBILITY_RESTORED':
        return NotificationType.ELIGIBILITY_RESTORED;
      case 'CAMPAIGN':
        return NotificationType.CAMPAIGN;
      case 'SYSTEM':
        return NotificationType.SYSTEM;
      default:
        return NotificationType.SYSTEM;
    }
  }

  static NotificationPriority _parseNotificationPriority(String value) {
    switch (value) {
      case 'LOW':
        return NotificationPriority.LOW;
      case 'MEDIUM':
        return NotificationPriority.MEDIUM;
      case 'HIGH':
        return NotificationPriority.HIGH;
      case 'URGENT':
        return NotificationPriority.URGENT;
      default:
        return NotificationPriority.MEDIUM;
    }
  }

  String get typeDisplay {
    switch (type) {
      case NotificationType.BLOOD_REQUEST:
        return 'BLOOD_REQUEST';
      case NotificationType.APPOINTMENT_REMINDER:
        return 'APPOINTMENT_REMINDER';
      case NotificationType.ELIGIBILITY_RESTORED:
        return 'ELIGIBILITY_RESTORED';
      case NotificationType.CAMPAIGN:
        return 'CAMPAIGN';
      case NotificationType.SYSTEM:
        return 'SYSTEM';
    }
  }

  String get priorityDisplay {
    switch (priority) {
      case NotificationPriority.LOW:
        return 'LOW';
      case NotificationPriority.MEDIUM:
        return 'MEDIUM';
      case NotificationPriority.HIGH:
        return 'HIGH';
      case NotificationPriority.URGENT:
        return 'URGENT';
    }
  }

  String get typeFriendly {
    switch (type) {
      case NotificationType.BLOOD_REQUEST:
        return 'Blood Request';
      case NotificationType.APPOINTMENT_REMINDER:
        return 'Appointment Reminder';
      case NotificationType.ELIGIBILITY_RESTORED:
        return 'Eligibility Restored';
      case NotificationType.CAMPAIGN:
        return 'Campaign';
      case NotificationType.SYSTEM:
        return 'System';
    }
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.getDateTimeInUtc().isBefore(DateTime.now().toUtc());
  }

  String get timeAgo {
    if (createdAt == null) return 'Unknown';
    
    final now = DateTime.now().toUtc();
    final created = createdAt!.getDateTimeInUtc();
    final difference = now.difference(created);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
