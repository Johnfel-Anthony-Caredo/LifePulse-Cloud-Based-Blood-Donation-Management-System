import 'package:flutter/material.dart';
import 'package:amplify_core/amplify_core.dart';
import '../../constants.dart';
import '../../models/blood_request_model.dart';
import '../../models/donor_model.dart';
import '../../services/blood_request_service.dart';
import '../../responsive.dart';
import '../shared/admin_page.dart';
import 'components/blood_request_form_dialog.dart';
import 'components/blood_request_detail_dialog.dart';
import 'components/donor_notification_dialog.dart';
import 'components/fulfillment_workflow_dialog.dart';
import 'components/blood_request_analytics.dart';

class BloodRequestsScreenNew extends StatefulWidget {
  const BloodRequestsScreenNew({Key? key}) : super(key: key);

  @override
  State<BloodRequestsScreenNew> createState() => _BloodRequestsScreenNewState();
}

class _BloodRequestsScreenNewState extends State<BloodRequestsScreenNew> {
  List<BloodRequestModel> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  RequestStatus? _selectedStatus;
  HospitalUrgency? _selectedUrgency;
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'urgency', 'units'
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final requests = await BloodRequestService.listBloodRequests();

      if (mounted) {
        setState(() {
          _requests = requests;
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

  List<BloodRequestModel> get _filteredRequests {
    var filtered = _requests;

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((r) {
        final query = _searchQuery.toLowerCase();
        return r.patientName.toLowerCase().contains(query) ||
               r.hospitalId.toLowerCase().contains(query) ||
               r.bloodTypeDisplay.toLowerCase().contains(query) ||
               (r.notes?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((r) => r.status == _selectedStatus).toList();
    }

    // Urgency filter
    if (_selectedUrgency != null) {
      filtered = filtered.where((r) => r.urgency == _selectedUrgency).toList();
    }

    // Sorting
    switch (_sortBy) {
      case 'urgency':
        filtered.sort((a, b) {
          // Critical first, then descending urgency
          final urgencyOrder = {
            HospitalUrgency.CRITICAL: 0,
            HospitalUrgency.HIGH: 1,
            HospitalUrgency.MEDIUM: 2,
            HospitalUrgency.LOW: 3,
            HospitalUrgency.WELL_STOCKED: 4,
          };
          return urgencyOrder[a.urgency]!.compareTo(urgencyOrder[b.urgency]!);
        });
        break;
      case 'units':
        filtered.sort((a, b) => b.unitsNeeded.compareTo(a.unitsNeeded));
        break;
      case 'date':
      default:
        filtered.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
    }

    return filtered;
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => BloodRequestFormDialog(),
    ).then((result) {
      if (result == true) {
        _loadRequests();
      }
    });
  }

  void _showEditDialog(BloodRequestModel request) {
    showDialog(
      context: context,
      builder: (context) => BloodRequestFormDialog(request: request),
    ).then((result) {
      if (result == true) {
        _loadRequests();
      }
    });
  }

  void _deleteRequest(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Blood Request'),
        content: Text('Are you sure you want to delete this blood request?'),
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
        await BloodRequestService.deleteBloodRequest(id);
        _loadRequests();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Blood request deleted successfully'),
              backgroundColor: tealAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting blood request: $e'),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _updateStatus(BloodRequestModel request, RequestStatus newStatus) async {
    try {
      await BloodRequestService.updateBloodRequest(
        id: request.id,
        status: BloodRequestModel.statusToString(newStatus),
        fulfilledAt: newStatus == RequestStatus.FULFILLED ? DateTime.now() : null,
      );
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.toString().split('.').last}'),
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
      title: 'Blood Requests',
      subtitle: 'Track urgent requests, donor outreach, and fulfillment progress.',
      action: FilledButton.icon(
        onPressed: () => _showCreateDialog(),
        icon: Icon(Icons.add, size: 18),
        label: Text('Create Request'),
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
                      else if (_filteredRequests.isEmpty)
                        _buildEmptyWidget()
                      else
                        Responsive(
                          mobile: _buildRequestsGrid(crossAxisCount: 1),
                          tablet: _buildRequestsGrid(crossAxisCount: 2),
                          desktop: _buildRequestsGrid(crossAxisCount: 3),
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
    final criticalCount = _requests.where((r) => r.urgency == HospitalUrgency.CRITICAL).length;
    final pendingCount = _requests.where((r) => r.status == RequestStatus.PENDING).length;
    final fulfilledCount = _requests.where((r) => r.status == RequestStatus.FULFILLED).length;
    final expiredCount = _requests.where((r) => r.isExpired).length;

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatChip('Total', _requests.length.toString(), Colors.blue),
              _buildStatChip('Critical', criticalCount.toString(), Color(0xFFDC143C)),
              _buildStatChip('Pending', pendingCount.toString(), orangeAccent),
              _buildStatChip('Fulfilled', fulfilledCount.toString(), tealAccent),
              if (expiredCount > 0)
                _buildStatChip('Expired', expiredCount.toString(), primaryColor),
            ],
          ),
          SizedBox(height: 16),
          
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by patient name, hospital ID, blood type...',
              prefixIcon: Icon(Icons.search, color: grayColor),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: grayColor),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          SizedBox(height: 16),
          
          // Filters and Sorting Row
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DropdownMenu<RequestStatus?>(
                width: 150,
                label: Text('Status'),
                dropdownMenuEntries: [
                  DropdownMenuEntry<RequestStatus?>(value: null, label: 'All'),
                  ...RequestStatus.values.map((status) {
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
              DropdownMenu<HospitalUrgency?>(
                width: 150,
                label: Text('Urgency'),
                dropdownMenuEntries: [
                  DropdownMenuEntry<HospitalUrgency?>(value: null, label: 'All'),
                  ...HospitalUrgency.values.map((urgency) {
                    return DropdownMenuEntry(
                      value: urgency,
                      label: urgency.toString().split('.').last,
                    );
                  }),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedUrgency = value;
                  });
                },
              ),
              DropdownMenu<String>(
                width: 150,
                label: Text('Sort By'),
                initialSelection: _sortBy,
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 'date', label: 'Date'),
                  DropdownMenuEntry(value: 'urgency', label: 'Urgency'),
                  DropdownMenuEntry(value: 'units', label: 'Units'),
                ],
                onSelected: (value) {
                  if (value != null) {
                    setState(() {
                      _sortBy = value;
                    });
                  }
                },
              ),
              if (_selectedStatus != null || _selectedUrgency != null || _searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedStatus = null;
                      _selectedUrgency = null;
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  icon: Icon(Icons.clear),
                  label: Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                  ),
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

  Widget _buildRequestsGrid({required int crossAxisCount}) {
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
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        return _BloodRequestCard(
          request: _filteredRequests[index],
          onEdit: () => _showEditDialog(_filteredRequests[index]),
          onDelete: () => _deleteRequest(_filteredRequests[index].id),
          onStatusChange: (status) => _updateStatus(_filteredRequests[index], status),
        );
      },
    );
  }

  Widget _buildRequestsList() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _filteredRequests.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(bottom: defaultPadding),
          child: _BloodRequestCard(
            request: _filteredRequests[index],
            onEdit: () => _showEditDialog(_filteredRequests[index]),
            onDelete: () => _deleteRequest(_filteredRequests[index].id),
            onStatusChange: (status) => _updateStatus(_filteredRequests[index], status),
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
              'Error loading blood requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: grayColor)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadRequests,
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
            Icon(Icons.inbox, size: 64, color: grayColor),
            SizedBox(height: 16),
            Text(
              'No blood requests found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No requests match the selected filters',
              style: TextStyle(color: grayColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _BloodRequestCard extends StatefulWidget {
  final BloodRequestModel request;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(RequestStatus) onStatusChange;

  const _BloodRequestCard({
    required this.request,
    required this.onEdit,
    required this.onDelete,
    required this.onStatusChange,
  });

  @override
  State<_BloodRequestCard> createState() => _BloodRequestCardState();
}

class _BloodRequestCardState extends State<_BloodRequestCard> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => BloodRequestDetailDialog(request: widget.request),
    );
  }

  void _showNotifyDonorsDialog() {
    showDialog(
      context: context,
      builder: (context) => DonorNotificationDialog(request: widget.request),
    );
  }

  void _showFulfillmentDialog() {
    showDialog(
      context: context,
      builder: (context) => FulfillmentWorkflowDialog(request: widget.request),
    ).then((result) {
      if (result == true) {
        // Reload parent screen if appointments were created
        // The parent screen will handle the refresh
      }
    });
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

  @override
  Widget build(BuildContext context) {
    final urgencyColor = _getUrgencyColor();
    final statusColor = _getStatusColor();

    return MouseRegion(
      onEnter: (_) => _animationController.forward(),
      onExit: (_) => _animationController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: _buildCard(urgencyColor, statusColor),
      ),
    );
  }

  Widget _buildCard(Color urgencyColor, Color statusColor) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            urgencyColor.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: urgencyColor.withOpacity(0.15),
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
          side: BorderSide(color: urgencyColor.withOpacity(0.2), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with blood type and status badge at top right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          urgencyColor,
                          urgencyColor.withOpacity(0.8),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: urgencyColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.transparent,
                      child: Text(
                        widget.request.bloodTypeDisplay,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [urgencyColor, urgencyColor.withOpacity(0.7)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: urgencyColor.withOpacity(0.3),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.request.urgencyDisplay,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: statusColor, width: 1.5),
                    ),
                    child: Text(
                      widget.request.statusDisplay,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Patient Name - larger text
              Row(
                children: [
                  Icon(Icons.person_outline, size: 20, color: Colors.blue.shade700),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.request.patientName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14),
              
              // Units needed - larger text
              Row(
                children: [
                  Icon(Icons.water_drop, size: 20, color: primaryColor),
                  SizedBox(width: 8),
                  Text(
                    '${widget.request.unitsNeeded} units needed',
                    style: TextStyle(fontSize: 17, color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 14),
              
              // Contact info if available
              if (widget.request.contactPerson != null || widget.request.contactPhone != null) ...[
                if (widget.request.contactPerson != null) ...[
                  Row(
                    children: [
                      Icon(Icons.contact_phone, size: 16, color: Colors.blue.shade700),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.request.contactPerson!,
                          style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
                if (widget.request.contactPhone != null) ...[
                  Row(
                    children: [
                      Icon(Icons.phone, size: 16, color: Colors.green.shade700),
                      SizedBox(width: 8),
                      Text(
                        widget.request.contactPhone!,
                        style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                ],
              ],
              
              // Created date
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: grayColor),
                  SizedBox(width: 6),
                  Text(
                    'Created ${_formatDate(widget.request.createdAt)}',
                    style: TextStyle(fontSize: 14, color: grayColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              
              // Expiry warning
              if (widget.request.expiresAt != null && (widget.request.isExpired || widget.request.isExpiringSoon)) ...[
                SizedBox(height: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.request.isExpired ? primaryColor.withOpacity(0.1) : orangeAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.request.isExpired ? primaryColor : orangeAccent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.request.isExpired ? Icons.error : Icons.warning,
                        size: 12,
                        color: widget.request.isExpired ? primaryColor : orangeAccent,
                      ),
                      SizedBox(width: 4),
                      Text(
                        widget.request.isExpired ? 'Expired' : 'Expiring Soon',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: widget.request.isExpired ? primaryColor : orangeAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              if (widget.request.notes != null && widget.request.notes!.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  widget.request.notes!,
                  style: TextStyle(fontSize: 12, color: grayColor, fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              Spacer(),
              
              // Quick action buttons
              if (widget.request.status == RequestStatus.PENDING) ...[
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showFulfillmentDialog,
                        icon: Icon(Icons.event_available, size: 16),
                        label: Text('Fulfill', style: TextStyle(fontSize: 12)),
                        style: FilledButton.styleFrom(
                          backgroundColor: tealAccent,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showNotifyDonorsDialog,
                        icon: Icon(Icons.notifications, size: 16),
                        label: Text('Notify', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: orangeAccent,
                          side: BorderSide(color: orangeAccent, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDetailsDialog,
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('Details', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Edit', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: grayColor,
                          side: BorderSide(color: grayColor, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _showDetailsDialog,
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('Details', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: BorderSide(color: Colors.blue, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.onEdit,
                        icon: Icon(Icons.edit, size: 16),
                        label: Text('Edit', style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: urgencyColor,
                          side: BorderSide(color: urgencyColor, width: 1.5),
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
