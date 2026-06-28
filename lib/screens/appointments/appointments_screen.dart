import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/appointment_model.dart';
import '../../models/donor_model.dart';
import '../../services/appointment_service.dart';
import '../../responsive.dart';
import '../shared/admin_page.dart';
import 'components/appointment_form_dialog.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({Key? key}) : super(key: key);

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<AppointmentModel> _appointments = [];
  bool _isLoading = true;
  String? _errorMessage;
  AppointmentStatus? _selectedStatus;
  bool? _filterToday;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final appointments = await AppointmentService.listAppointments();

      if (mounted) {
        setState(() {
          _appointments = appointments;
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

  List<AppointmentModel> get _filteredAppointments {
    var filtered = _appointments;

    if (_selectedStatus != null) {
      filtered = filtered.where((a) => a.status == _selectedStatus).toList();
    }

    if (_filterToday == true) {
      filtered = filtered.where((a) => a.isToday).toList();
    }

    // Sort by appointment date, newest first
    filtered.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

    return filtered;
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => AppointmentFormDialog(),
    ).then((result) {
      if (result == true) {
        _loadAppointments();
      }
    });
  }

  void _showEditDialog(AppointmentModel appointment) {
    showDialog(
      context: context,
      builder: (context) => AppointmentFormDialog(appointment: appointment),
    ).then((result) {
      if (result == true) {
        _loadAppointments();
      }
    });
  }

  void _deleteAppointment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Appointment'),
        content: Text('Are you sure you want to delete this appointment?'),
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
        await AppointmentService.deleteAppointment(id);
        _loadAppointments();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Appointment deleted successfully'),
              backgroundColor: tealAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting appointment: $e'),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(AppointmentModel appointment, AppointmentStatus newStatus) async {
    try {
      // If marking as completed, use the comprehensive completion logic
      if (newStatus == AppointmentStatus.COMPLETED) {
        final success = await AppointmentService.completeAppointment(
          appointmentId: appointment.id,
          donorId: appointment.donorId,
          hospitalId: appointment.hospitalId,
          bloodType: DonorModel.bloodTypeToGraphQL(appointment.bloodType),
          appointmentDate: appointment.appointmentDate,
          bloodRequestId: appointment.bloodRequestId,
          unitsGiven: 1,
          notes: 'Donation completed',
        );

        if (!success) {
          throw Exception('Failed to complete appointment');
        }
      } else {
        // For other status changes, use regular update
        await AppointmentService.updateAppointment(
          id: appointment.id,
          status: AppointmentModel.statusToString(newStatus),
          confirmedAt: newStatus == AppointmentStatus.CONFIRMED ? DateTime.now() : null,
          completedAt: newStatus == AppointmentStatus.COMPLETED ? DateTime.now() : null,
          cancelledAt: newStatus == AppointmentStatus.CANCELLED ? DateTime.now() : null,
        );
      }

      _loadAppointments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == AppointmentStatus.COMPLETED
                  ? 'Donation completed successfully! ✓'
                  : 'Status updated to ${AppointmentModel.statusFromString(AppointmentModel.statusToString(newStatus)).toString().split('.').last}'
            ),
            backgroundColor: tealAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Appointment Management',
      subtitle: 'Schedule, confirm, complete, and review donor appointments.',
      action: FilledButton.icon(
        onPressed: () => _showCreateDialog(),
        icon: Icon(Icons.add, size: 18),
        label: Text('Create Appointment'),
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildFilterSection(),
                      SizedBox(height: defaultPadding),
                      
                      if (_isLoading)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: primaryColor),
                          ),
                        )
                      else if (_errorMessage != null)
                        _buildErrorWidget()
                      else if (_filteredAppointments.isEmpty)
                        _buildEmptyWidget()
                      else
                        Responsive(
                          mobile: _buildAppointmentsGrid(crossAxisCount: 1),
                          tablet: _buildAppointmentsGrid(crossAxisCount: 2),
                          desktop: _buildAppointmentsGrid(crossAxisCount: 3),
                        ),
                    ],
                  ),
                ),
              ],
            ),
      ],
    );
  }

  Widget _buildFilterSection() {
    final todayCount = _appointments.where((a) => a.isToday).length;
    final scheduledCount = _appointments.where((a) => a.status == AppointmentStatus.SCHEDULED).length;
    final completedCount = _appointments.where((a) => a.status == AppointmentStatus.COMPLETED).length;

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip('Total', _appointments.length.toString(), Colors.blue),
              _buildStatChip('Today', todayCount.toString(), orangeAccent),
              _buildStatChip('Scheduled', scheduledCount.toString(), Colors.purple),
              _buildStatChip('Completed', completedCount.toString(), tealAccent),
            ],
          ),
          SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DropdownMenu<AppointmentStatus?>(
                width: 150,
                label: Text('Status'),
                dropdownMenuEntries: [
                  DropdownMenuEntry<AppointmentStatus?>(value: null, label: 'All'),
                  ...AppointmentStatus.values.map((status) {
                    return DropdownMenuEntry(
                      value: status,
                      label: status.toString().split('.').last,
                    );
                  }),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
              ),
              FilterChip(
                label: Text('Today Only'),
                selected: _filterToday == true,
                onSelected: (selected) {
                  setState(() {
                    _filterToday = selected ? true : null;
                  });
                },
              ),
              if (_selectedStatus != null || _filterToday != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _filterToday = null;
                    });
                  },
                  icon: Icon(Icons.clear),
                  label: Text('Clear Filters'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsGrid({required int crossAxisCount}) {
    final isMobile = crossAxisCount == 1;
    final isTablet = crossAxisCount == 2;
    
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: isMobile ? 0.85 : (isTablet ? 0.9 : 1.1),
      ),
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        return _AppointmentCard(
          appointment: _filteredAppointments[index],
          onEdit: () => _showEditDialog(_filteredAppointments[index]),
          onDelete: () => _deleteAppointment(_filteredAppointments[index].id),
          onStatusChange: (status) => _updateStatus(_filteredAppointments[index], status),
        );
      },
    );
  }

  Widget _buildAppointmentsList() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _filteredAppointments.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: defaultPadding),
          child: _AppointmentCard(
            appointment: _filteredAppointments[index],
            onEdit: () => _showEditDialog(_filteredAppointments[index]),
            onDelete: () => _deleteAppointment(_filteredAppointments[index].id),
            onStatusChange: (status) => _updateStatus(_filteredAppointments[index], status),
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
              'Error loading appointments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: grayColor)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAppointments,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
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
            Icon(Icons.event_busy, size: 64, color: grayColor),
            SizedBox(height: 16),
            Text(
              'No appointments found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No appointments match the selected filters',
              style: TextStyle(color: grayColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(AppointmentStatus) onStatusChange;

  const _AppointmentCard({
    required this.appointment,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  Color _getStatusColor() {
    switch (appointment.status) {
      case AppointmentStatus.SCHEDULED:
        return Colors.blue;
      case AppointmentStatus.CONFIRMED:
        return tealAccent;
      case AppointmentStatus.COMPLETED:
        return Colors.green;
      case AppointmentStatus.CANCELLED:
        return primaryColor;
      case AppointmentStatus.NO_SHOW:
        return orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            statusColor.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: statusColor.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large centered blood type avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor,
                      statusColor.withOpacity(0.8),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    appointment.bloodTypeDisplay,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  appointment.statusDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              
              if (appointment.isToday) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: orangeAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: orangeAccent.withOpacity(0.3)),
                  ),
                  child: Text(
                    'TODAY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: orangeAccent,
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 12),
              
              // Appointment Date & Time
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event, size: 16, color: statusColor),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      appointment.appointmentDateFormatted,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 10),
              
              // Donor Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 16, color: statusColor),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      appointment.donorName ?? 'Donor: ${appointment.donorId.substring(0, 8)}...',
                      style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 6),
              
              // Hospital Info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_hospital, size: 16, color: statusColor),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      appointment.hospitalName ?? 'Hospital: ${appointment.hospitalId.substring(0, 8)}...',
                      style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
                SizedBox(height: 10),
                Text(
                  appointment.notes!,
                  style: TextStyle(fontSize: 12, color: grayColor, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              Spacer(),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: Icon(Icons.edit, size: 16),
                      label: Text('Edit', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: statusColor,
                        side: BorderSide(color: statusColor, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDelete,
                      icon: Icon(Icons.delete_outline, size: 16),
                      label: Text('Delete', style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
