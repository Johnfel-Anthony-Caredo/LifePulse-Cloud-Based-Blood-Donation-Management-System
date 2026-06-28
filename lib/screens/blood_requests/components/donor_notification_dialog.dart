import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/blood_request_model.dart';
import '../../../models/donor_model.dart';
import '../../../services/donor_service.dart';
import '../../../services/notification_service.dart';

class DonorNotificationDialog extends StatefulWidget {
  final BloodRequestModel request;

  const DonorNotificationDialog({Key? key, required this.request}) : super(key: key);

  @override
  State<DonorNotificationDialog> createState() => _DonorNotificationDialogState();
}

class _DonorNotificationDialogState extends State<DonorNotificationDialog> {
  List<DonorModel> _eligibleDonors = [];
  Set<String> _selectedDonorIds = {};
  bool _isLoading = true;
  String? _errorMessage;
  int _radiusKm = 10;

  @override
  void initState() {
    super.initState();
    _findEligibleDonors();
  }

  Future<void> _findEligibleDonors() async {
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

      // Sort by last donation date (donors who donated longer ago first)
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

  Future<void> _sendNotifications() async {
    if (_selectedDonorIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select at least one donor'),
          backgroundColor: orangeAccent,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Create notifications for each selected donor
      int successCount = 0;
      int failCount = 0;

      for (final donorId in _selectedDonorIds) {
        try {
          await NotificationService.createNotification(
            userId: donorId,
            type: 'BLOOD_REQUEST',
            priority: widget.request.urgency == 'critical' ? 'URGENT' : 
                     widget.request.urgency == 'high' ? 'HIGH' : 'MEDIUM',
            title: 'Blood Donation Request - ${widget.request.bloodType}',
            message: 'We urgently need ${widget.request.bloodType} blood. '
                    '${widget.request.unitsNeeded} unit(s) needed for ${widget.request.patientName ?? "a patient"}. '
                    'Please consider donating.',
            metadata: '{"bloodRequestId":"${widget.request.id}","bloodType":"${widget.request.bloodType}"}',
            expiresAt: widget.request.expiresAt?.getDateTimeInUtc(),
          );
          successCount++;
        } catch (e) {
          print('Failed to create notification for donor $donorId: $e');
          failCount++;
        }
      }

      setState(() => _isLoading = false);
      Navigator.pop(context, _selectedDonorIds);

      if (failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully sent notifications to $successCount donor(s)'),
            backgroundColor: tealAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sent $successCount notification(s), $failCount failed'),
            backgroundColor: orangeAccent,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending notifications: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: isMobile ? screenWidth * 0.95 : 700,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.8)],
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
                    child: Icon(Icons.notifications_active, color: Colors.white, size: isMobile ? 24 : 32),
                  ),
                  SizedBox(width: isMobile ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notify Eligible Donors',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Blood Type: ${widget.request.bloodTypeDisplay} • ${widget.request.unitsNeeded} units needed',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

            // Search/Filter Section
            Container(
              padding: EdgeInsets.all(isMobile ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Found ${_eligibleDonors.length} eligible donor(s)',
                          style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                  if (_eligibleDonors.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          if (_selectedDonorIds.length == _eligibleDonors.length) {
                            _selectedDonorIds.clear();
                          } else {
                            _selectedDonorIds = _eligibleDonors.map((d) => d.id).toSet();
                          }
                        });
                      },
                      icon: Icon(
                        _selectedDonorIds.length == _eligibleDonors.length
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 18,
                      ),
                      label: Text('Select All', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                    ),
                ],
              ),
            ),

            // Donors List
            Flexible(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
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
                      children: [
                        Text(
                          '${_selectedDonorIds.length} donor(s) selected',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _selectedDonorIds.isEmpty ? null : _sendNotifications,
                                icon: Icon(Icons.send, size: 16),
                                label: Text('Send', style: TextStyle(fontSize: 13)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: primaryColor,
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
                        Text(
                          '${_selectedDonorIds.length} donor(s) selected',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Cancel'),
                            ),
                            SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _selectedDonorIds.isEmpty ? null : _sendNotifications,
                              icon: Icon(Icons.send, size: 18),
                              label: Text('Send Notifications'),
                              style: FilledButton.styleFrom(
                                backgroundColor: primaryColor,
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

  Widget _buildDonorTile(DonorModel donor, bool isSelected) {
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
      child: InkWell(
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
                radius: 28,
                backgroundColor: tealAccent.withOpacity(0.2),
                child: Text(
                  donor.bloodTypeDisplay,
                  style: TextStyle(
                    fontSize: 16,
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
              onPressed: _findEligibleDonors,
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
