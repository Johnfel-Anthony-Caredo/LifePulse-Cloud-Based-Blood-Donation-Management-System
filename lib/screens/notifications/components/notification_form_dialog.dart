import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/notification_model.dart';
import '../../../models/donor_model.dart';
import '../../../services/notification_service.dart';
import '../../../services/donor_service.dart';

class NotificationFormDialog extends StatefulWidget {
  const NotificationFormDialog({Key? key}) : super(key: key);

  @override
  State<NotificationFormDialog> createState() => _NotificationFormDialogState();
}

class _NotificationFormDialogState extends State<NotificationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _actionUrlController = TextEditingController();
  
  NotificationType _selectedType = NotificationType.SYSTEM;
  NotificationPriority _selectedPriority = NotificationPriority.MEDIUM;
  DateTime? _expiresAt;
  bool _isLoading = false;
  bool _isLoadingDonors = true;
  
  List<DonorModel> _donors = [];
  String? _selectedUserId;
  final TextEditingController _donorSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _actionUrlController.dispose();
    _donorSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadDonors() async {
    try {
      final donors = await DonorService.listDonors();
      if (mounted) {
        setState(() {
          _donors = donors;
          _isLoadingDonors = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDonors = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading donors: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  List<DonorModel> get _filteredDonors {
    if (_donorSearchController.text.isEmpty) return _donors;
    
    final query = _donorSearchController.text.toLowerCase();
    return _donors.where((donor) {
      return donor.name.toLowerCase().contains(query) ||
             donor.email.toLowerCase().contains(query) ||
             donor.userId.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _saveNotification() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a donor'),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await NotificationService.createNotification(
        userId: _selectedUserId!,
        type: _selectedType.name,
        priority: _selectedPriority.name,
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        actionUrl: _actionUrlController.text.trim().isNotEmpty 
            ? _actionUrlController.text.trim() 
            : null,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notification sent successfully'),
            backgroundColor: tealAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Future<void> _selectExpiryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_expiresAt ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _expiresAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Send Notification',
                    style: TextStyle(fontSize: isMobile ? 18 : 24, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Donor Selection with Search
                      Text(
                        'Select Donor *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      TextField(
                        controller: _donorSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search donors by name, email, or user ID',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      SizedBox(height: 8),
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _isLoadingDonors
                            ? Center(child: CircularProgressIndicator())
                            : _filteredDonors.isEmpty
                                ? Center(child: Text('No donors found'))
                                : ListView.builder(
                                    itemCount: _filteredDonors.length,
                                    itemBuilder: (context, index) {
                                      final donor = _filteredDonors[index];
                                      final isSelected = _selectedUserId == donor.userId;
                                      return ListTile(
                                        selected: isSelected,
                                        selectedTileColor: primaryColor.withOpacity(0.1),
                                        leading: CircleAvatar(
                                          backgroundColor: isSelected ? primaryColor : Colors.grey,
                                          child: Text(
                                            donor.name[0].toUpperCase(),
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        title: Text(donor.name),
                                        subtitle: Text('${donor.email} • ${donor.bloodTypeDisplay}'),
                                        trailing: isSelected ? Icon(Icons.check, color: primaryColor) : null,
                                        onTap: () {
                                          setState(() {
                                            _selectedUserId = donor.userId;
                                          });
                                        },
                                      );
                                    },
                                  ),
                      ),
                      SizedBox(height: 16),
                      isMobile
                          ? Column(
                              children: [
                                DropdownButtonFormField<NotificationType>(
                                  value: _selectedType,
                                  decoration: InputDecoration(
                                    labelText: 'Type',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: NotificationType.values.map((type) {
                                    String label;
                                    switch (type) {
                                      case NotificationType.BLOOD_REQUEST:
                                        label = 'Blood Request';
                                        break;
                                      case NotificationType.APPOINTMENT_REMINDER:
                                        label = 'Appointment Reminder';
                                        break;
                                      case NotificationType.ELIGIBILITY_RESTORED:
                                        label = 'Eligibility Restored';
                                        break;
                                      case NotificationType.CAMPAIGN:
                                        label = 'Campaign';
                                        break;
                                      case NotificationType.SYSTEM:
                                        label = 'System';
                                        break;
                                    }
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(label),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedType = value);
                                    }
                                  },
                                ),
                                SizedBox(height: 16),
                                DropdownButtonFormField<NotificationPriority>(
                                  value: _selectedPriority,
                                  decoration: InputDecoration(
                                    labelText: 'Priority',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: NotificationPriority.values.map((priority) {
                                    return DropdownMenuItem(
                                      value: priority,
                                      child: Text(priority.name),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedPriority = value);
                                    }
                                  },
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<NotificationType>(
                                    value: _selectedType,
                                    decoration: InputDecoration(
                                      labelText: 'Type',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: NotificationType.values.map((type) {
                                      String label;
                                      switch (type) {
                                        case NotificationType.BLOOD_REQUEST:
                                          label = 'Blood Request';
                                          break;
                                        case NotificationType.APPOINTMENT_REMINDER:
                                          label = 'Appointment Reminder';
                                          break;
                                        case NotificationType.ELIGIBILITY_RESTORED:
                                          label = 'Eligibility Restored';
                                          break;
                                        case NotificationType.CAMPAIGN:
                                          label = 'Campaign';
                                          break;
                                        case NotificationType.SYSTEM:
                                          label = 'System';
                                          break;
                                      }
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(label),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedType = value);
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<NotificationPriority>(
                                    value: _selectedPriority,
                                    decoration: InputDecoration(
                                      labelText: 'Priority',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: NotificationPriority.values.map((priority) {
                                      return DropdownMenuItem(
                                        value: priority,
                                        child: Text(priority.name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedPriority = value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title *',
                          hintText: 'Enter notification title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          labelText: 'Message *',
                          hintText: 'Enter notification message',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Message is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _actionUrlController,
                        decoration: InputDecoration(
                          labelText: 'Action URL (Optional)',
                          hintText: 'e.g., /appointments/123',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                        ),
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _selectExpiryDate,
                        icon: Icon(Icons.calendar_today),
                        label: Text(
                          _expiresAt == null 
                              ? 'Set Expiry Date (Optional)' 
                              : 'Expires: ${_expiresAt!.day}/${_expiresAt!.month}/${_expiresAt!.year} ${_expiresAt!.hour}:${_expiresAt!.minute.toString().padLeft(2, '0')}',
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                        ),
                      ),
                      if (_expiresAt != null) ...[
                        SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => setState(() => _expiresAt = null),
                          icon: Icon(Icons.clear, size: 16),
                          label: Text('Clear expiry date'),
                          style: TextButton.styleFrom(foregroundColor: primaryColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: isMobile ? 16 : 20),
            isMobile
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: FilledButton.icon(
                          onPressed: _isLoading ? null : _saveNotification,
                          icon: _isLoading 
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.send),
                          label: Text(_isLoading ? 'Sending...' : 'Send'),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        child: Text('Cancel'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(120, 45),
                        ),
                      ),
                      SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _saveNotification,
                        icon: _isLoading 
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.send),
                        label: Text(_isLoading ? 'Sending...' : 'Send'),
                        style: FilledButton.styleFrom(
                          backgroundColor: primaryColor,
                          minimumSize: Size(120, 45),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
