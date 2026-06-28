import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/donor_model.dart';
import '../../services/donor_service.dart';
import '../../responsive.dart';
import '../shared/admin_page.dart';
import 'components/donor_form_dialog.dart';
import 'components/donor_create_dialog.dart';

class DonorsScreen extends StatefulWidget {
  const DonorsScreen({Key? key}) : super(key: key);

  @override
  State<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends State<DonorsScreen> {
  List<DonorModel> _donors = [];
  bool _isLoading = true;
  String? _errorMessage;
  BloodType? _selectedBloodType;
  bool? _selectedEligibility;

  @override
  void initState() {
    super.initState();
    _loadDonors();
  }

  Future<void> _loadDonors() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final donors = await DonorService.listDonors();

      if (mounted) {
        setState(() {
          _donors = donors;
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

  List<DonorModel> get _filteredDonors {
    var filtered = _donors;

    if (_selectedBloodType != null) {
      filtered = filtered.where((d) => d.bloodType == _selectedBloodType).toList();
    }

    if (_selectedEligibility != null) {
      filtered = filtered.where((d) => d.isEligible == _selectedEligibility).toList();
    }

    return filtered;
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (context) => DonorCreateDialog(),
    ).then((result) {
      if (result == true) {
        _loadDonors();
      }
    });
  }

  void _showEditDialog(DonorModel donor) {
    showDialog(
      context: context,
      builder: (context) => DonorFormDialog(donor: donor),
    ).then((result) {
      if (result == true) {
        _loadDonors();
      }
    });
  }

  void _deleteDonor(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Donor'),
        content: Text('Are you sure you want to delete this donor?'),
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
        await DonorService.deleteDonor(id);
        _loadDonors();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Donor deleted successfully'),
              backgroundColor: tealAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting donor: $e'),
              backgroundColor: primaryColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Donor Management',
      subtitle: 'Review donor accounts, eligibility, and blood type coverage.',
      action: FilledButton.icon(
        onPressed: () => _showCreateDialog(),
        icon: Icon(Icons.add, size: 18),
        label: Text('Create Donor'),
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
                      // Filters and Stats
                      _buildFilterSection(),
                      SizedBox(height: defaultPadding),
                      
                      // Donors Grid/List
                      if (_isLoading)
                        Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(color: primaryColor),
                          ),
                        )
                      else if (_errorMessage != null)
                        _buildErrorWidget()
                      else if (_filteredDonors.isEmpty)
                        _buildEmptyWidget()
                      else
                        Responsive(
                          mobile: _buildDonorsGrid(crossAxisCount: 1),
                          tablet: _buildDonorsGrid(crossAxisCount: 2),
                          desktop: _buildDonorsGrid(crossAxisCount: 3),
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
    final eligibleCount = _donors.where((d) => d.isEligible).length;
    final notEligibleCount = _donors.length - eligibleCount;

    return AdminSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Donor Accounts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildStatChip('Total', _donors.length.toString(), Colors.blue),
                  _buildStatChip('Eligible', eligibleCount.toString(), tealAccent),
                  _buildStatChip('Not Eligible', notEligibleCount.toString(), orangeAccent),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          
          // Filters
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Blood Type Filter
              DropdownMenu<BloodType?>(
                width: 150,
                label: Text('Blood Type'),
                dropdownMenuEntries: [
                  DropdownMenuEntry<BloodType?>(value: null, label: 'All'),
                  ...BloodType.values.map((type) {
                    final donor = DonorModel(
                      id: '',
                      userId: '',
                      name: '',
                      email: '',
                      bloodType: type,
                      isEligible: true,
                      notificationsEnabled: true,
                    );
                    return DropdownMenuEntry(value: type, label: donor.bloodTypeDisplay);
                  }),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedBloodType = value;
                  });
                },
              ),
              
              // Eligibility Filter
              DropdownMenu<bool?>(
                width: 150,
                label: Text('Eligibility'),
                dropdownMenuEntries: [
                  DropdownMenuEntry<bool?>(value: null, label: 'All'),
                  DropdownMenuEntry(value: true, label: 'Eligible'),
                  DropdownMenuEntry(value: false, label: 'Not Eligible'),
                ],
                onSelected: (value) {
                  setState(() {
                    _selectedEligibility = value;
                  });
                },
              ),
              
              // Clear Filters
              if (_selectedBloodType != null || _selectedEligibility != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedBloodType = null;
                      _selectedEligibility = null;
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

  Widget _buildDonorsGrid({required int crossAxisCount}) {
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
      itemCount: _filteredDonors.length,
      itemBuilder: (context, index) {
        return _DonorCard(
          donor: _filteredDonors[index],
          onEdit: () => _showEditDialog(_filteredDonors[index]),
          onDelete: () => _deleteDonor(_filteredDonors[index].id),
        );
      },
    );
  }

  Widget _buildDonorsList() {
    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _filteredDonors.length,
      itemBuilder: (context, index) {
        return _DonorCard(
          donor: _filteredDonors[index],
          onEdit: () => _showEditDialog(_filteredDonors[index]),
          onDelete: () => _deleteDonor(_filteredDonors[index].id),
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
              'Error loading donors',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(_errorMessage!, style: TextStyle(color: grayColor)),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDonors,
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
            Icon(Icons.people_outline, size: 64, color: grayColor),
            SizedBox(height: 16),
            Text(
              'No donors found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'No donors match the selected filters',
              style: TextStyle(color: grayColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  final DonorModel donor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DonorCard({
    required this.donor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            donor.isEligible 
                ? tealAccent.withOpacity(0.08)
                : primaryColor.withOpacity(0.08),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: donor.isEligible 
                ? tealAccent.withOpacity(0.15)
                : primaryColor.withOpacity(0.1),
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
          side: BorderSide(
            color: donor.isEligible 
                ? tealAccent.withOpacity(0.3)
                : primaryColor.withOpacity(0.2), 
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Large centered blood type avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: donor.isEligible 
                        ? [tealAccent, tealAccent.withOpacity(0.8)]
                        : [Color(0xFFB71C1C), Color(0xFFC62828)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: donor.isEligible 
                          ? tealAccent.withOpacity(0.3)
                          : primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.transparent,
                  child: Text(
                    donor.bloodTypeDisplay,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
              
              // Name
              Text(
                donor.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              SizedBox(height: 8),
              
              // Email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.email, size: 16, color: donor.isEligible 
                      ? tealAccent.withOpacity(0.7)
                      : primaryColor.withOpacity(0.6)),
                  SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      donor.email,
                      style: TextStyle(fontSize: 14, color: grayColor),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 8),
            
            // Phone
            if (donor.phone != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone, size: 16, color: donor.isEligible ? tealAccent : primaryColor),
                  SizedBox(width: 6),
                  Text(
                    donor.phone!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: 12),
            
            // Last donation and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Donation',
                      style: TextStyle(fontSize: 10, color: grayColor),
                    ),
                    Text(
                      donor.lastDonationFormatted,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: donor.isEligible 
                          ? [tealAccent, tealAccent.withOpacity(0.7)]
                          : [Color(0xFFB71C1C), Color(0xFFC62828)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: (donor.isEligible ? tealAccent : Color(0xFFB71C1C)).withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    donor.status,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            Spacer(flex: 1),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Edit', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: donor.isEligible ? tealAccent : Color(0xFFB71C1C),
                      side: BorderSide(
                        color: donor.isEligible ? tealAccent : Color(0xFFB71C1C), 
                        width: 1.5,
                      ),
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
                      backgroundColor: donor.isEligible ? tealAccent : Color(0xFFB71C1C),
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
    ); // Container closing
  }
}
