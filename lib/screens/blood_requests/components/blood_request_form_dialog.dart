import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../constants.dart';
import '../../../models/blood_request_model.dart';
import '../../../models/donor_model.dart';
import '../../../services/blood_request_service.dart';
import '../../../services/hospital_service.dart';

class BloodRequestFormDialog extends StatefulWidget {
  final BloodRequestModel? request;

  const BloodRequestFormDialog({Key? key, this.request}) : super(key: key);

  @override
  State<BloodRequestFormDialog> createState() => _BloodRequestFormDialogState();
}

class _BloodRequestFormDialogState extends State<BloodRequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _unitsNeededController = TextEditingController();
  
  String? _selectedHospitalId;
  BloodType _selectedBloodType = BloodType.O_POSITIVE;
  HospitalUrgency _urgency = HospitalUrgency.MEDIUM;
  RequestStatus _status = RequestStatus.PENDING;
  DateTime? _expiresAt;
  bool _isLoading = false;
  
  List<Map<String, String>> _hospitals = [];
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    if (widget.request != null) {
      _selectedHospitalId = widget.request!.hospitalId;
      _selectedBloodType = widget.request!.bloodType;
      _unitsNeededController.text = widget.request!.unitsNeeded.toString();
      _urgency = widget.request!.urgency;
      _patientNameController.text = widget.request!.patientName;
      _contactPersonController.text = widget.request!.contactPerson ?? '';
      _contactPhoneController.text = widget.request!.contactPhone ?? '';
      _status = widget.request!.status;
      _notesController.text = widget.request!.notes ?? '';
      _expiresAt = widget.request!.expiresAt != null 
          ? DateTime.parse(widget.request!.expiresAt!.format())
          : null;
    } else {
      _unitsNeededController.text = '1';
    }
    _loadData();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _notesController.dispose();
    _unitsNeededController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final hospitals = await HospitalService.listHospitals();

      if (mounted) {
        setState(() {
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

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a hospital'),
          backgroundColor: primaryColor,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.request == null) {
        // Create new request
        await BloodRequestService.createBloodRequest(
          hospitalId: _selectedHospitalId!,
          bloodType: DonorModel.bloodTypeToGraphQL(_selectedBloodType),
          unitsNeeded: int.parse(_unitsNeededController.text),
          urgency: BloodRequestModel.urgencyToString(_urgency),
          patientName: _patientNameController.text.trim(),
          contactPerson: _contactPersonController.text.trim().isEmpty 
              ? null 
              : _contactPersonController.text.trim(),
          contactPhone: _contactPhoneController.text.trim().isEmpty 
              ? null 
              : _contactPhoneController.text.trim(),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          expiresAt: _expiresAt,
        );
      } else {
        // Update existing request
        await BloodRequestService.updateBloodRequest(
          id: widget.request!.id,
          unitsNeeded: int.parse(_unitsNeededController.text),
          urgency: BloodRequestModel.urgencyToString(_urgency),
          patientName: _patientNameController.text.trim(),
          contactPerson: _contactPersonController.text.trim().isEmpty 
              ? null 
              : _contactPersonController.text.trim(),
          contactPhone: _contactPhoneController.text.trim().isEmpty 
              ? null 
              : _contactPhoneController.text.trim(),
          status: BloodRequestModel.statusToString(_status),
          notes: _notesController.text.trim().isEmpty 
              ? null 
              : _notesController.text.trim(),
          expiresAt: _expiresAt,
          fulfilledAt: _status == RequestStatus.FULFILLED ? DateTime.now() : null,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blood request ${widget.request == null ? 'created' : 'updated'} successfully!'),
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

  Future<void> _selectExpiryDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(Duration(days: 1)),
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

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _expiresAt != null 
            ? TimeOfDay.fromDateTime(_expiresAt!)
            : TimeOfDay(hour: 23, minute: 59),
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
          _expiresAt = DateTime(
            picked.year,
            picked.month,
            picked.day,
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
                    child: Icon(Icons.water_drop, color: Colors.white, size: 28),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request == null ? 'Create Blood Request' : 'Edit Blood Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.request == null 
                              ? 'Request blood from donors'
                              : 'Update request details',
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
                            // Hospital Selection
                            if (widget.request == null)
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
                            if (widget.request == null) SizedBox(height: 16),

                            // Patient Name
                            TextFormField(
                              controller: _patientNameController,
                              decoration: InputDecoration(
                                labelText: 'Patient Name *',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter patient name';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Blood Type & Units
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<BloodType>(
                                    value: _selectedBloodType,
                                    decoration: InputDecoration(
                                      labelText: 'Blood Type *',
                                      prefixIcon: Icon(Icons.water_drop),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    items: BloodType.values.map((type) {
                                      final donor = DonorModel(
                                        id: '',
                                        userId: '',
                                        name: '',
                                        email: '',
                                        bloodType: type,
                                        isEligible: true,
                                        notificationsEnabled: true,
                                      );
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(donor.bloodTypeDisplay),
                                      );
                                    }).toList(),
                                    onChanged: widget.request == null
                                        ? (value) {
                                            if (value != null) {
                                              setState(() => _selectedBloodType = value);
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _unitsNeededController,
                                    decoration: InputDecoration(
                                      labelText: 'Units *',
                                      prefixIcon: Icon(Icons.opacity),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      if (int.tryParse(value) == null || int.parse(value) < 1) {
                                        return 'Invalid';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Urgency
                            DropdownButtonFormField<HospitalUrgency>(
                              value: _urgency,
                              decoration: InputDecoration(
                                labelText: 'Urgency *',
                                prefixIcon: Icon(Icons.priority_high),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: HospitalUrgency.values.map((urgency) {
                                return DropdownMenuItem(
                                  value: urgency,
                                  child: Text(urgency.toString().split('.').last),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _urgency = value);
                                }
                              },
                            ),
                            SizedBox(height: 16),

                            // Status (only for edit)
                            if (widget.request != null) ...[
                              DropdownButtonFormField<RequestStatus>(
                                value: _status,
                                decoration: InputDecoration(
                                  labelText: 'Status *',
                                  prefixIcon: Icon(Icons.info),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                items: RequestStatus.values.map((status) {
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
                              SizedBox(height: 16),
                            ],

                            // Contact Person
                            TextFormField(
                              controller: _contactPersonController,
                              decoration: InputDecoration(
                                labelText: 'Contact Person',
                                prefixIcon: Icon(Icons.contact_phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Contact Phone
                            TextFormField(
                              controller: _contactPhoneController,
                              decoration: InputDecoration(
                                labelText: 'Contact Phone',
                                prefixIcon: Icon(Icons.phone),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: 16),

                            // Expiry Date
                            InkWell(
                              onTap: _selectExpiryDate,
                              borderRadius: BorderRadius.circular(12),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Expires At',
                                  prefixIcon: Icon(Icons.calendar_today),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  _expiresAt != null
                                      ? '${_expiresAt!.year}-${_expiresAt!.month.toString().padLeft(2, '0')}-${_expiresAt!.day.toString().padLeft(2, '0')} ${_expiresAt!.hour.toString().padLeft(2, '0')}:${_expiresAt!.minute.toString().padLeft(2, '0')}'
                                      : 'None',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            // Notes
                            TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: 'Notes',
                                prefixIcon: Icon(Icons.notes),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
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
                      onPressed: _isLoading ? null : _saveRequest,
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
                          : Text(widget.request == null ? 'Create' : 'Update'),
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
