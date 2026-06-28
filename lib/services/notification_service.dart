import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/notification_model.dart';
import 'backend_config.dart';
import 'local_backend_store.dart';

class NotificationService {
  /// List all notifications (Admin view)
  static Future<List<NotificationModel>> listAllNotifications() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final notifications = List<NotificationModel>.from(
        store.notifications,
      );
      notifications.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return notifications;
    }

    try {
      const graphQLDocument = '''
        query ListNotifications {
          listNotifications(limit: 1000) {
            items {
              id
              userId
              type
              priority
              title
              message
              isRead
              readAt
              actionUrl
              metadata
              expiresAt
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null) {
        throw Exception('Failed to fetch notifications');
      }

      final data = jsonDecode(response.data!);
      if (data == null || data['listNotifications'] == null) {
        return [];
      }

      final items = (data['listNotifications']['items'] ?? []) as List;

      return items
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      safePrint('Error listing notifications: $e');
      rethrow;
    }
  }

  /// List notifications for current user (filters from listNotifications)
  static Future<List<NotificationModel>> listMyNotifications() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final notifications = store.notifications
          .where((notification) => notification.userId == store.currentUserId)
          .toList();
      notifications.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return notifications;
    }

    try {
      // Get current user ID
      final currentUser = await Amplify.Auth.getCurrentUser();
      final userId = currentUser.userId;

      const graphQLDocument = '''
        query ListNotifications(\$filter: ModelNotificationFilterInput, \$limit: Int) {
          listNotifications(filter: \$filter, limit: \$limit) {
            items {
              id
              userId
              type
              priority
              title
              message
              isRead
              readAt
              actionUrl
              metadata
              expiresAt
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'filter': {
            'userId': {
              'eq': userId,
            },
          },
          'limit': 1000,
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      safePrint('Querying notifications for userId: $userId');

      final response = await Amplify.API.query(request: request).response;

      safePrint('Response data: ${response.data}');
      safePrint('Response errors: ${response.errors}');

      if (response.data == null) {
        if (response.errors.isNotEmpty) {
          final errorMessages =
              response.errors.map((e) => e.message).join(', ');
          throw Exception('GraphQL errors: $errorMessages');
        }
        throw Exception('Failed to fetch notifications - no data returned');
      }

      final data = jsonDecode(response.data!);
      if (data == null || data['listNotifications'] == null) {
        safePrint('No listNotifications data in response');
        return [];
      }

      final items = (data['listNotifications']['items'] ?? []) as List;
      safePrint('Found ${items.length} notifications');

      // Sort by createdAt DESC
      final notifications = items
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList();

      notifications.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return notifications;
    } catch (e) {
      safePrint('Error listing my notifications: $e');
      rethrow;
    }
  }

  /// Create a new notification
  static Future<NotificationModel> createNotification({
    required String userId,
    required String type,
    required String priority,
    required String title,
    required String message,
    String? actionUrl,
    String? metadata,
    DateTime? expiresAt,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final notification = NotificationModel(
        id: store.nextId('notification'),
        userId: userId,
        type: _typeFromString(type),
        priority: _priorityFromString(priority),
        title: title,
        message: message,
        isRead: false,
        actionUrl: actionUrl,
        metadata: metadata,
        expiresAt: expiresAt != null ? TemporalDateTime(expiresAt) : null,
        createdAt: store.now(),
        updatedAt: store.now(),
      );
      store.notifications.add(notification);
      await store.persist();
      return notification;
    }

    try {
      const graphQLDocument = '''
        mutation CreateNotification(\$input: CreateNotificationInput!) {
          createNotification(input: \$input) {
            id
            userId
            type
            priority
            title
            message
            isRead
            readAt
            actionUrl
            metadata
            expiresAt
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = {
        'input': {
          'userId': userId,
          'type': type,
          'priority': priority,
          'title': title,
          'message': message,
          'isRead': false,
          if (actionUrl != null && actionUrl.isNotEmpty) 'actionUrl': actionUrl,
          if (metadata != null && metadata.isNotEmpty) 'metadata': metadata,
          if (expiresAt != null)
            'expiresAt': TemporalDateTime(expiresAt).format(),
        }
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      safePrint('Creating notification with variables: $variables');

      final response = await Amplify.API.mutate(request: request).response;

      safePrint('Response data: ${response.data}');
      safePrint('Response errors: ${response.errors}');

      if (response.data == null || response.errors.isNotEmpty) {
        final errorMessages =
            response.errors.map((e) => '${e.message}').join(", ");
        safePrint('Create notification errors: $errorMessages');
        throw Exception('Failed to create notification: $errorMessages');
      }

      final data = jsonDecode(response.data!);
      if (data['createNotification'] == null) {
        throw Exception('createNotification returned null');
      }
      return NotificationModel.fromJson(
          data['createNotification'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error creating notification: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  static Future<NotificationModel> markAsRead(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index = store.notifications.indexWhere((item) => item.id == id);
      if (index == -1) throw Exception('Notification not found');
      final existing = store.notifications[index];
      final updated = NotificationModel(
        id: existing.id,
        userId: existing.userId,
        type: existing.type,
        priority: existing.priority,
        title: existing.title,
        message: existing.message,
        isRead: true,
        readAt: store.now(),
        actionUrl: existing.actionUrl,
        metadata: existing.metadata,
        expiresAt: existing.expiresAt,
        createdAt: existing.createdAt,
        updatedAt: store.now(),
      );
      store.notifications[index] = updated;
      await store.persist();
      return updated;
    }

    try {
      const graphQLDocument = '''
        mutation UpdateNotification(\$input: UpdateNotificationInput!) {
          updateNotification(input: \$input) {
            id
            userId
            type
            priority
            title
            message
            isRead
            readAt
            actionUrl
            metadata
            expiresAt
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = {
        'input': {
          'id': id,
          'isRead': true,
          'readAt': TemporalDateTime.now().format(),
        }
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null || response.errors.isNotEmpty) {
        throw Exception('Failed to mark notification as read');
      }

      final data = jsonDecode(response.data!);
      return NotificationModel.fromJson(
          data['updateNotification'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  static Future<void> deleteNotification(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.notifications.removeWhere((notification) => notification.id == id);
      await store.persist();
      return;
    }

    try {
      const graphQLDocument = '''
        mutation DeleteNotification(\$input: DeleteNotificationInput!) {
          deleteNotification(input: \$input) {
            id
          }
        }
      ''';

      final variables = {
        'input': {
          'id': id,
        }
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      safePrint('Error deleting notification: $e');
      rethrow;
    }
  }

  static Future<int> markAllMineAsRead() async {
    final notifications = await listMyNotifications();
    final unread = notifications.where((notification) => !notification.isRead);
    var updatedCount = 0;

    for (final notification in unread) {
      await markAsRead(notification.id);
      updatedCount += 1;
    }

    return updatedCount;
  }

  static NotificationType _typeFromString(String value) {
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
      default:
        return NotificationType.SYSTEM;
    }
  }

  static NotificationPriority _priorityFromString(String value) {
    switch (value) {
      case 'LOW':
        return NotificationPriority.LOW;
      case 'HIGH':
        return NotificationPriority.HIGH;
      case 'URGENT':
        return NotificationPriority.URGENT;
      case 'MEDIUM':
      default:
        return NotificationPriority.MEDIUM;
    }
  }
}
