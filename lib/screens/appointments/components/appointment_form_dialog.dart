import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../constants.dart';
import '../../../models/appointment_model.dart';
import '../../../models/donor_model.dart';
import '../../../services/appointment_service.dart';
import '../../../services/donor_service.dart';
import '../../../services/hospital_service.dart';

class AppointmentFormDialog extends StatefulWidget {
  final AppointmentModel? appointment;

  const AppointmentFormDialog({Key? key, this.appointment}) : super(key: key);

  @override
  State<AppointmentFormDialog> createState() => _AppointmentFormDialogState();
}

class _AppointmentFormDialogState extends State<AppointmentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  
  String? _selectedDonorId;
  String? _selectedHospitalId;
  DateTime _appointmentDate = DateTime.now().add(Duration(days: 1));
  AppointmentStatus _status = AppointmentStatus.SCHEDULED;
  bool _isLoading = false;
  
  List<Map<String, String>> _donors = [];
  List<Map<String, String>> _hospitals = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _selectedDonorId = widget.appointment!.donorId;
      _selectedHospitalId = widget.appointment!.hospitalId;
      _appointmentDate = DateTime.parse(widget.appointment!.appointmentDate.format());
      _status = widget.appointment!.status;
      _notesController.text = widget.appointment!.notes ?? '';
    }
    _loadData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final donors = await DonorService.listDonors();
      final hospitals = await HospitalService.listHospitals();

      if (mounted) {
        setState(() {
          _donors = donors.map((d) => {'id': d.id, 'name': d.name}).toList();
          _hospitals = hospitals.map((h) => {'id': h.id, 'name': h.name}).toList();
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: primaryColor,
          ),
        );
      }
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDonorId == null || _selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select both donor and hospital'),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.appointment == null) {
        // Create new appointment
        await AppointmentService.createAppointment(
          donorId: _selectedDonorId!,
          hospitalId: _selectedHospitalId!,
          appointmentDate: _appointmentDate,
          bloodType: 'O_POSITIVE', // This should be fetched from donor
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );
      } else {
        // Check if status is being changed to COMPLETED
        final String statusString = AppointmentModel.statusToString(_status);
        final bool isCompletingAppointment = 
            statusString == 'COMPLETED' && 
            AppointmentModel.statusToString(widget.appointment!.status) != 'COMPLETED';
        
        if (isCompletingAppointment) {
          // Use completeAppointment to create donation history
          await AppointmentService.completeAppointment(
            appointmentId: widget.appointment!.id,
            donorId: widget.appointment!.donorId,
            hospitalId: widget.appointment!.hospitalId,
            bloodType: widget.appointment!.bloodType.name,
            appointmentDate: widget.appointment!.appointmentDate,
            unitsGiven: 1,
            bloodRequestId: widget.appointment!.bloodRequestId,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
          
          // Update notes and date if changed
          if (_notesController.text.trim().isNotEmpty || 
              _appointmentDate != widget.appointment!.appointmentDate.getDateTimeInUtc()) {
            await AppointmentService.updateAppointment(
              id: widget.appointment!.id,
              appointmentDate: _appointmentDate,
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            );
          }
        } else {
          // Regular update for other status changes
          await AppointmentService.updateAppointment(
            id: widget.appointment!.id,
            appointmentDate: _appointmentDate,
            status: statusString,
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Appointment ${widget.appointment == null ? 'created' : 'updated'} successfully!'),
            backgroundColor: tealAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_appointmentDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: primaryColor,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _appointmentDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        width: 500,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.event, color: Colors.white, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.appointment == null ? 'Create Appointment' : 'Edit Appointment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.appointment == null 
                              ? 'Schedule a new donation appointment'
                              : 'Update appointment details',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Form
            Flexible(
              child: _isLoadingData
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Donor Selection
                            if (widget.appointment == null)
                              DropdownButtonFormField<String>(
                                value: _selectedDonorId,
                                decoration: InputDecoration(
                                  labelText: 'Donor *',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _donors.map((donor) {
                                  return DropdownMenuItem(
                                    value: donor['id'],
                                    child: Text(donor['name']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedDonorId = value);
                                },
                                validator: (value) {
                                  if (value == null) return 'Please select a donor';
                                  return null;
                                },
                              ),
                            if (widget.appointment == null) SizedBox(height: 16),

                            // Hospital Selection
                            if (widget.appointment == null)
                              DropdownButtonFormField<String>(
                                value: _selectedHospitalId,
                                decoration: InputDecoration(
                                  labelText: 'Hospital *',
                                  prefixIcon: Icon(Icons.local_hospital),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: _hospitals.map((hospital) {
                                  return DropdownMenuItem(
                                    value: hospital['id'],
                                    child: Text(hospital['name']!),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => _selectedHospitalId = value);
                                },
                                validator: (value) {
                                  if (value == null) return 'Please select a hospital';
                                  return null;
                                },
                              ),
                            if (widget.appointment == null) SizedBox(height: 16),

                            // Appointment Date & Time
                            InkWell(
                              onTap: _selectDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Appointment Date & Time *',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  '${_appointmentDate.year}-'
                                  '${_appointmentDate.month.toString().padLeft(2, '0')}-'
                                  '${_appointmentDate.day.toString().padLeft(2, '0')} '
                                  '${_appointmentDate.hour.toString().padLeft(2, '0')}:'
                                  '${_appointmentDate.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Status
                            if (widget.appointment != null)
                              DropdownButtonFormField<AppointmentStatus>(
                                value: _status,
                                decoration: InputDecoration(
                                  labelText: 'Status *',
                                  prefixIcon: Icon(Icons.info),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: AppointmentStatus.values.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status.toString().split('.').last),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _status = value);
                                  }
                                },
                              ),
                            if (widget.appointment != null) SizedBox(height: 16),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: 'Notes',
                                prefixIcon: Icon(Icons.notes),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                helperText: 'Optional appointment notes',
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightGrayColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _saveAppointment,
                      style: FilledButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(widget.appointment == null ? 'Create' : 'Update'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
