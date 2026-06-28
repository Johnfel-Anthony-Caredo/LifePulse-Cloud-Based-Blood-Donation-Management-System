import 'package:flutter/material.dart';
import 'package:amplify_core/amplify_core.dart';
import '../../constants.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../shared/admin_page.dart';
import 'components/notification_form_dialog.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  NotificationType? _selectedType;
  NotificationPriority? _selectedPriority;
  bool? _showOnlyUnread;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final notifications = await NotificationService.listAllNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<NotificationModel> get _filteredNotifications {
    var filtered = _notifications;

    // Filter expired
    filtered = filtered.where((n) => !n.isExpired).toList();

    // Type filter
    if (_selectedType != null) {
      filtered = filtered.where((n) => n.type == _selectedType).toList();
    }

    // Priority filter
    if (_selectedPriority != null) {
      filtered = filtered.where((n) => n.priority == _selectedPriority).toList();
    }

    // Read/Unread filter
    if (_showOnlyUnread == true) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }

    // Sort by created date (newest first)
    filtered.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));

    return filtered;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead && !n.isExpired).length;

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => NotificationFormDialog(),
    ).then((result) {
      if (result == true) {
        _loadNotifications();
      }
    });
  }

  void _deleteNotification(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Notification'),
        content: Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await NotificationService.deleteNotification(id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notification deleted successfully')),
        );
        _loadNotifications();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }

  void _markAsRead(String id) async {
    try {
      await NotificationService.markAsRead(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as read')),
      );
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking as read: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Notifications',
      subtitle: 'Send donor alerts and monitor unread or high-priority messages.',
      action: FilledButton.icon(
        onPressed: _showCreateDialog,
        icon: Icon(Icons.add),
        label: Text('Send Notification'),
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      children: [
            _buildFiltersCard(),
            SizedBox(height: defaultPadding),
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              _buildErrorWidget()
            else if (_filteredNotifications.isEmpty)
              _buildEmptyWidget()
            else
              _buildNotificationsList(),
      ],
    );
  }

  Widget _buildFiltersCard() {
    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatChip('Total', '${_notifications.length}', primaryColor),
              SizedBox(width: 8),
              _buildStatChip('Unread', '$_unreadCount', orangeAccent),
            ],
          ),
          SizedBox(height: defaultPadding),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              DropdownMenu<NotificationType>(
                width: 200,
                label: Text('Type'),
                initialSelection: _selectedType,
                dropdownMenuEntries: NotificationType.values.map((type) {
                  String label;
                  switch (type) {
                    case NotificationType.BLOOD_REQUEST:
                      label = 'Blood Request';
                      break;
                    case NotificationType.APPOINTMENT_REMINDER:
                      label = 'Appointment';
                      break;
                    case NotificationType.ELIGIBILITY_RESTORED:
                      label = 'Eligibility';
                      break;
                    case NotificationType.CAMPAIGN:
                      label = 'Campaign';
                      break;
                    case NotificationType.SYSTEM:
                      label = 'System';
                      break;
                  }
                  return DropdownMenuEntry(value: type, label: label);
                }).toList(),
                onSelected: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              DropdownMenu<NotificationPriority>(
                width: 150,
                label: Text('Priority'),
                initialSelection: _selectedPriority,
                dropdownMenuEntries: NotificationPriority.values.map((priority) {
                  return DropdownMenuEntry(value: priority, label: priority.name);
                }).toList(),
                onSelected: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                },
              ),
              DropdownMenu<String>(
                width: 150,
                label: Text('Status'),
                initialSelection: _showOnlyUnread == null ? 'all' : (_showOnlyUnread! ? 'unread' : 'read'),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 'all', label: 'All'),
                  DropdownMenuEntry(value: 'unread', label: 'Unread'),
                  DropdownMenuEntry(value: 'read', label: 'Read'),
                ],
                onSelected: (value) {
                  setState(() {
                    if (value == 'all') {
                      _showOnlyUnread = null;
                    } else if (value == 'unread') {
                      _showOnlyUnread = true;
                    } else {
                      _showOnlyUnread = false;
                    }
                  });
                },
              ),
              if (_selectedType != null || _selectedPriority != null || _showOnlyUnread != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedType = null;
                      _selectedPriority = null;
                      _showOnlyUnread = null;
                    });
                  },
                  icon: Icon(Icons.clear),
                  label: Text('Clear Filters'),
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _filteredNotifications.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: defaultPadding),
          child: _NotificationCard(
            notification: _filteredNotifications[index],
            onMarkAsRead: () => _markAsRead(_filteredNotifications[index].id),
            onDelete: () => _deleteNotification(_filteredNotifications[index].id),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 64, color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Error loading notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage ?? 'Unknown error'),
            SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadNotifications,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.notifications_none, size: 64, color: grayColor),
            SizedBox(height: 16),
            Text(
              'No notifications found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Send your first notification to users'),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onMarkAsRead;
  final VoidCallback onDelete;

  const _NotificationCard({
    required this.notification,
    required this.onMarkAsRead,
    required this.onDelete,
  });

  Color _getPriorityColor() {
    switch (notification.priority) {
      case NotificationPriority.URGENT:
        return Color(0xFFDC143C);
      case NotificationPriority.HIGH:
        return orangeAccent;
      case NotificationPriority.MEDIUM:
        return Color(0xFFFCD34D);
      case NotificationPriority.LOW:
        return tealAccent;
    }
  }

  IconData _getTypeIcon() {
    switch (notification.type) {
      case NotificationType.BLOOD_REQUEST:
        return Icons.water_drop;
      case NotificationType.APPOINTMENT_REMINDER:
        return Icons.event;
      case NotificationType.ELIGIBILITY_RESTORED:
        return Icons.verified_user;
      case NotificationType.CAMPAIGN:
        return Icons.campaign;
      case NotificationType.SYSTEM:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: notification.isRead ? Colors.white : primaryColor.withOpacity(0.02),
        border: Border.all(
          color: notification.isRead ? Colors.grey.shade200 : primaryColor.withOpacity(0.2),
          width: notification.isRead ? 1 : 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_getTypeIcon(), color: priorityColor, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: priorityColor, width: 1),
                            ),
                            child: Text(
                              notification.priority.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: priorityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          notification.typeFriendly,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        notification.message,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.person, size: 14, color: grayColor),
                              SizedBox(width: 4),
                              Text(
                                'User ID: ${notification.userId.length > 15 ? notification.userId.substring(0, 15) + '...' : notification.userId}',
                                style: TextStyle(fontSize: 12, color: grayColor),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 14, color: grayColor),
                              SizedBox(width: 4),
                              Text(
                                _formatDate(notification.createdAt),
                                style: TextStyle(fontSize: 12, color: grayColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                if (!notification.isRead) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onMarkAsRead,
                      icon: Icon(Icons.mark_email_read, size: 16),
                      label: Text('Mark as Read', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: tealAccent,
                        side: BorderSide(color: tealAccent, width: 1.5),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Delete', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryColor,
                      side: BorderSide(color: primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(TemporalDateTime? temporalDateTime) {
    if (temporalDateTime == null) return 'N/A';
    
    final dateTime = temporalDateTime.getDateTimeInUtc().toLocal();
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
