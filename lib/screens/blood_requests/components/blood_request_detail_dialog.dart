import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/blood_request_model.dart';
import '../../../models/appointment_model.dart';
import '../../../services/appointment_service.dart';

class BloodRequestDetailDialog extends StatefulWidget {
  final BloodRequestModel request;

  const BloodRequestDetailDialog({Key? key, required this.request}) : super(key: key);

  @override
  State<BloodRequestDetailDialog> createState() => _BloodRequestDetailDialogState();
}

class _BloodRequestDetailDialogState extends State<BloodRequestDetailDialog> {
  List<AppointmentModel> _relatedAppointments = [];
  bool _isLoadingAppointments = true;

  @override
  void initState() {
    super.initState();
    _loadRelatedAppointments();
  }

  Future<void> _loadRelatedAppointments() async {
    try {
      final allAppointments = await AppointmentService.listAppointments();
      final related = allAppointments
          .where((apt) => apt.bloodRequestId == widget.request.id)
          .toList();
      
      if (mounted) {
        setState(() {
          _relatedAppointments = related;
          _isLoadingAppointments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  Color _getUrgencyColor() {
    switch (widget.request.urgency) {
      case HospitalUrgency.CRITICAL:
        return Color(0xFFDC143C);
      case HospitalUrgency.HIGH:
        return orangeAccent;
      case HospitalUrgency.MEDIUM:
        return Color(0xFFFCD34D);
      case HospitalUrgency.LOW:
        return tealAccent;
      case HospitalUrgency.WELL_STOCKED:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, urgencyColor.withOpacity(0.03)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [urgencyColor, urgencyColor.withOpacity(0.8)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    padding: EdgeInsets.all(12),
                    child: Icon(Icons.bloodtype, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blood Request Details',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.request.urgencyDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection(),
                    SizedBox(height: 24),
                    _buildTimestampsSection(),
                    SizedBox(height: 24),
                    _buildContactSection(),
                    if (widget.request.notes != null && widget.request.notes!.isNotEmpty) ...[
                      SizedBox(height: 24),
                      _buildNotesSection(),
                    ],
                    SizedBox(height: 24),
                    _buildRelatedAppointmentsSection(),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Patient', widget.request.patientName),
          _buildInfoRow(Icons.bloodtype, 'Blood Type', widget.request.bloodTypeDisplay),
          _buildInfoRow(Icons.water_drop, 'Units Needed', '${widget.request.unitsNeeded} units'),
          _buildInfoRow(Icons.local_hospital, 'Hospital ID', widget.request.hospitalId),
          _buildInfoRow(
            Icons.info_outline,
            'Status',
            widget.request.statusDisplay,
            valueColor: _getStatusColor(),
          ),
          _buildInfoRow(
            Icons.priority_high,
            'Urgency',
            widget.request.urgencyDisplay,
            valueColor: _getUrgencyColor(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 16),
          _buildInfoRow(Icons.access_time, 'Created', widget.request.createdAtFormatted),
          if (widget.request.expiresAt != null)
            _buildInfoRow(
              Icons.event_busy,
              'Expires',
              DateTime.parse(widget.request.expiresAt!.format()).toLocal().toString().split('.')[0],
              valueColor: widget.request.isExpired 
                  ? primaryColor 
                  : widget.request.isExpiringSoon 
                      ? orangeAccent 
                      : null,
            ),
          if (widget.request.fulfilledAt != null)
            _buildInfoRow(
              Icons.check_circle,
              'Fulfilled',
              DateTime.parse(widget.request.fulfilledAt!.format()).toLocal().toString().split('.')[0],
              valueColor: tealAccent,
            ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    if (widget.request.contactPerson == null && widget.request.contactPhone == null) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          SizedBox(height: 16),
          if (widget.request.contactPerson != null)
            _buildInfoRow(Icons.person_outline, 'Contact Person', widget.request.contactPerson!),
          if (widget.request.contactPhone != null)
            _buildInfoRow(Icons.phone, 'Phone', widget.request.contactPhone!),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note, size: 18, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                'Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.request.notes!,
            style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedAppointmentsSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_month, size: 18, color: Colors.black87),
              SizedBox(width: 8),
              Text(
                'Related Appointments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isLoadingAppointments ? '...' : '${_relatedAppointments.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_isLoadingAppointments)
            Center(child: CircularProgressIndicator(strokeWidth: 2))
          else if (_relatedAppointments.isEmpty)
            Text(
              'No appointments linked to this request',
              style: TextStyle(fontSize: 14, color: grayColor, fontStyle: FontStyle.italic),
            )
          else
            ..._relatedAppointments.map((apt) => _buildAppointmentTile(apt)).toList(),
        ],
      ),
    );
  }

  Widget _buildAppointmentTile(AppointmentModel appointment) {
    Color statusColor;
    switch (appointment.status) {
      case AppointmentStatus.SCHEDULED:
        statusColor = Colors.blue;
        break;
      case AppointmentStatus.CONFIRMED:
        statusColor = tealAccent;
        break;
      case AppointmentStatus.COMPLETED:
        statusColor = Colors.green;
        break;
      case AppointmentStatus.CANCELLED:
        statusColor = primaryColor;
        break;
      case AppointmentStatus.NO_SHOW:
        statusColor = Colors.grey;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.event, size: 16, color: statusColor),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateTime.parse(appointment.appointmentDate.format()).toLocal().toString().split('.')[0],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Donor ID: ${appointment.donorId.substring(0, 8)}...',
                  style: TextStyle(fontSize: 11, color: grayColor),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appointment.statusDisplay,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: grayColor),
          SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: grayColor, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.request.status) {
      case RequestStatus.PENDING:
        return orangeAccent;
      case RequestStatus.FULFILLED:
        return tealAccent;
      case RequestStatus.CANCELLED:
        return primaryColor;
    }
  }
}
