import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/blood_request_model.dart';
import '../../../models/donor_model.dart';
import '../../../models/appointment_model.dart';
import '../../../services/donor_service.dart';
import '../../../services/appointment_service.dart';
import '../../../services/blood_request_service.dart';

class FulfillmentWorkflowDialog extends StatefulWidget {
  final BloodRequestModel request;

  const FulfillmentWorkflowDialog({Key? key, required this.request}) : super(key: key);

  @override
  State<FulfillmentWorkflowDialog> createState() => _FulfillmentWorkflowDialogState();
}

class _FulfillmentWorkflowDialogState extends State<FulfillmentWorkflowDialog> {
  List<DonorModel> _eligibleDonors = [];
  Set<String> _selectedDonorIds = {};
  Map<String, DateTime> _appointmentDates = {};
  Map<String, TimeOfDay> _appointmentTimes = {};
  bool _isLoading = true;
  bool _isCreatingAppointments = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEligibleDonors();
  }

  Future<void> _loadEligibleDonors() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final allDonors = await DonorService.listDonors();
      
      // Filter for matching blood type and eligibility
      final eligible = allDonors.where((donor) {
        return donor.bloodType == widget.request.bloodType &&
               donor.isEligible == true;
      }).toList();

      // Sort by last donation date
      eligible.sort((a, b) {
        if (a.lastDonation == null && b.lastDonation == null) return 0;
        if (a.lastDonation == null) return -1;
        if (b.lastDonation == null) return 1;
        return a.lastDonation!.compareTo(b.lastDonation!);
      });

      if (mounted) {
        setState(() {
          _eligibleDonors = eligible;
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

  Future<void> _createAppointments() async {
    if (_selectedDonorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one donor'),
          backgroundColor: orangeAccent,
        ),
      );
      return;
    }

    // Validate all selected donors have dates and times
    for (final donorId in _selectedDonorIds) {
      if (!_appointmentDates.containsKey(donorId) || !_appointmentTimes.containsKey(donorId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please set appointment date and time for all selected donors'),
            backgroundColor: orangeAccent,
          ),
        );
        return;
      }
    }

    setState(() {
      _isCreatingAppointments = true;
    });

    try {
      int successCount = 0;
      
      for (final donorId in _selectedDonorIds) {
        final date = _appointmentDates[donorId]!;
        final time = _appointmentTimes[donorId]!;
        
        final appointmentDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        await AppointmentService.createAppointment(
          donorId: donorId,
          hospitalId: widget.request.hospitalId,
          appointmentDate: appointmentDateTime,
          bloodType: widget.request.bloodType.toString().split('.').last,
          bloodRequestId: widget.request.id,
        );
        
        successCount++;
      }

      // Update blood request status to fulfilled
      await BloodRequestService.updateBloodRequest(
        id: widget.request.id,
        status: BloodRequestModel.statusToString(RequestStatus.FULFILLED),
        fulfilledAt: DateTime.now(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully created $successCount appointment(s) and marked request as fulfilled'),
            backgroundColor: tealAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreatingAppointments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating appointments: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Future<void> _selectDate(String donorId) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _appointmentDates[donorId] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _appointmentDates[donorId] = picked;
        // Set default time if not set
        if (!_appointmentTimes.containsKey(donorId)) {
          _appointmentTimes[donorId] = TimeOfDay(hour: 9, minute: 0);
        }
      });
    }
  }

  Future<void> _selectTime(String donorId) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _appointmentTimes[donorId] ?? TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(primary: primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _appointmentTimes[donorId] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 800,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [tealAccent, tealAccent.withOpacity(0.8)],
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
                    padding: EdgeInsets.all(isMobile ? 8 : 12),
                    child: Icon(Icons.event_available, color: Colors.white, size: isMobile ? 24 : 32),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fulfill Blood Request',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Schedule appointments with eligible donors',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
            ),

            // Request Info
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                children: [
                  _buildInfoChip('Blood Type', widget.request.bloodTypeDisplay, primaryColor, isMobile),
                  _buildInfoChip('Units Needed', '${widget.request.unitsNeeded}', Colors.blue, isMobile),
                  _buildInfoChip('Patient', widget.request.patientName, Colors.purple, isMobile),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: tealAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Found ${_eligibleDonors.length} eligible donor(s)',
                      style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.w600, color: tealAccent),
                    ),
                  ),
                ],
              ),
            ),

            // Donors List
            Flexible(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: tealAccent))
                  : _errorMessage != null
                      ? _buildErrorWidget()
                      : _eligibleDonors.isEmpty
                          ? _buildEmptyWidget()
                          : ListView.builder(
                              padding: EdgeInsets.all(16),
                              itemCount: _eligibleDonors.length,
                              itemBuilder: (context, index) {
                                final donor = _eligibleDonors[index];
                                final isSelected = _selectedDonorIds.contains(donor.id);
                                return _buildDonorTile(donor, isSelected);
                              },
                            ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: isMobile
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedDonorIds.length} appointment(s) to create',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        if (_selectedDonorIds.isNotEmpty)
                          Text(
                            'This will mark the request as FULFILLED',
                            style: TextStyle(fontSize: 11, color: grayColor),
                          ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: _isCreatingAppointments ? null : () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: (_selectedDonorIds.isEmpty || _isCreatingAppointments) 
                                    ? null 
                                    : _createAppointments,
                                icon: _isCreatingAppointments
                                    ? SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(Icons.check_circle, size: 16),
                                label: Text(
                                  _isCreatingAppointments ? 'Creating...' : 'Create',
                                  style: TextStyle(fontSize: 13),
                                ),
                                style: FilledButton.styleFrom(
                                  backgroundColor: tealAccent,
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedDonorIds.length} appointment(s) to create',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                            if (_selectedDonorIds.isNotEmpty)
                              Text(
                                'This will mark the request as FULFILLED',
                                style: TextStyle(fontSize: 12, color: grayColor),
                              ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: _isCreatingAppointments ? null : () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: (_selectedDonorIds.isEmpty || _isCreatingAppointments) 
                                  ? null 
                                  : _createAppointments,
                              icon: _isCreatingAppointments
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.check_circle, size: 18),
                              label: Text(_isCreatingAppointments ? 'Creating...' : 'Create Appointments'),
                              style: FilledButton.styleFrom(
                                backgroundColor: tealAccent,
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, Color color, bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: isMobile ? 10 : 12, color: grayColor, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: isMobile ? 4 : 6),
          Text(
            value,
            style: TextStyle(fontSize: isMobile ? 11 : 13, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorTile(DonorModel donor, bool isSelected) {
    final hasDateTime = _appointmentDates.containsKey(donor.id) && _appointmentTimes.containsKey(donor.id);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? tealAccent : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? tealAccent.withOpacity(0.05) : Colors.white,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedDonorIds.remove(donor.id);
                } else {
                  _selectedDonorIds.add(donor.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedDonorIds.add(donor.id);
                        } else {
                          _selectedDonorIds.remove(donor.id);
                        }
                      });
                    },
                    activeColor: tealAccent,
                  ),
                  SizedBox(width: 12),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: tealAccent.withOpacity(0.2),
                    child: Text(
                      donor.bloodTypeDisplay,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tealAccent,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          donor.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: grayColor),
                            SizedBox(width: 4),
                            Text(
                              donor.phone ?? 'No phone',
                              style: TextStyle(fontSize: 12, color: grayColor),
                            ),
                            if (donor.lastDonation != null) ...[
                              SizedBox(width: 12),
                              Icon(Icons.calendar_today, size: 12, color: grayColor),
                              SizedBox(width: 4),
                              Text(
                                'Last: ${DateTime.parse(donor.lastDonation!.format()).toLocal().toString().split(' ')[0]}',
                                style: TextStyle(fontSize: 12, color: grayColor),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: tealAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: tealAccent),
                        SizedBox(width: 4),
                        Text(
                          'Eligible',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tealAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Date/Time Picker (shown when selected)
          if (isSelected)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: tealAccent.withOpacity(0.05),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: tealAccent.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.event, size: 18, color: tealAccent),
                  SizedBox(width: 8),
                  Text(
                    'Appointment:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectDate(donor.id),
                      icon: Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _appointmentDates.containsKey(donor.id)
                            ? _appointmentDates[donor.id]!.toLocal().toString().split(' ')[0]
                            : 'Select Date',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasDateTime ? tealAccent : grayColor,
                        side: BorderSide(
                          color: hasDateTime ? tealAccent : Colors.grey[400]!,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _selectTime(donor.id),
                      icon: Icon(Icons.access_time, size: 16),
                      label: Text(
                        _appointmentTimes.containsKey(donor.id)
                            ? _appointmentTimes[donor.id]!.format(context)
                            : 'Select Time',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: hasDateTime ? tealAccent : grayColor,
                        side: BorderSide(
                          color: hasDateTime ? tealAccent : Colors.grey[400]!,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: primaryColor),
            SizedBox(height: 16),
            Text(
              'Error loading donors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: grayColor)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadEligibleDonors,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_off, size: 64, color: grayColor),
            SizedBox(height: 16),
            Text(
              'No eligible donors found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No donors match the blood type ${widget.request.bloodTypeDisplay}',
              style: TextStyle(color: grayColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
