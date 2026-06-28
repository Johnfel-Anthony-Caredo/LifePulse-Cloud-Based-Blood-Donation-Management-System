import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import '../../constants.dart';
import '../../models/appointment.dart';
import '../../models/donor_profile.dart';
import '../../models/donor_model.dart';
import '../../models/hospital.dart';
import '../../services/auth_service.dart';
import '../../services/hospital_service.dart';
import '../../services/donor_service.dart';
import '../../services/donation_history_service.dart';
import '../auth/login_screen.dart';
import 'components/hospital_bottom_sheet.dart';
import 'components/menu_fab.dart';
import 'donor_map_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({Key? key}) : super(key: key);

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  DonorProfile? _profile;
  DonorModel? _donorModel;
  bool _isLoading = true;
  List<Hospital> _hospitals = [];
  int _totalBloodUnits = 0;
  int _donationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    await Future.wait([
      _loadProfile(),
      _loadDonorModel(),
      _loadHospitals(),
      _loadDonationCount(),
    ]);
  }
  
  Future<void> _loadDonationCount() async {
    try {
      final donor = await DonorService.getCurrentDonor();
      if (donor != null) {
        final history = await DonationHistoryService.listDonationHistoryByDonor(donor.id);
        if (mounted) {
          setState(() {
            _donationCount = history.length;
          });
        }
      }
    } catch (e) {
      safePrint('Error loading donation count: $e');
    }
  }
  
  Future<void> _loadDonorModel() async {
    try {
      final donor = await DonorService.getCurrentDonor();
      if (mounted) {
        setState(() {
          _donorModel = donor;
        });
      }
    } catch (e) {
      safePrint('Error loading donor model: $e');
    }
  }

  Future<void> _loadHospitals() async {
    try {
      final hospitals = await HospitalService.listHospitals();
      
      // Calculate total blood units
      int totalUnits = 0;
      for (var hospital in hospitals) {
        totalUnits += hospital.bloodInventory.values.fold(0, (sum, units) => sum + units);
      }
      
      if (mounted) {
        setState(() {
          _hospitals = hospitals;
          _totalBloodUnits = totalUnits;
        });
      }
    } catch (e) {
      safePrint('Error loading hospitals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load hospitals: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('donor_profile');

      if (profileJson != null) {
        setState(() {
          _profile = DonorProfile.fromJsonString(profileJson);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Hospital> get _criticalHospitals {
    return _hospitals.where((h) => h.urgency == HospitalUrgency.critical).toList();
  }

  List<Hospital> get _myBloodTypeHospitals {
    if (_profile?.bloodType == null) return [];
    return _hospitals.where((h) {
      final inventory = h.bloodInventory;
      final myType = _profile!.bloodType!;
      // Check if the blood type exists in inventory and is below 10 units
      // If blood type doesn't exist in inventory, consider it as 0 units (also needs donation)
      if (inventory.containsKey(myType)) {
        return inventory[myType]! < 10;
      }
      // If blood type is not in inventory at all, it means they have 0 units - critically needed
      return true;
    }).toList();
  }

  void _navigateToMap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DonorMapScreen()),
    );
  }

  Future<void> _handleSignOut() async {
    // Show confirmation dialog first
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: primaryColor),
            SizedBox(width: 10),
            Text('Logout'),
          ],
        ),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await AuthService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          // Still navigate to login screen even if sign out fails
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;
    final isMobile = size.width < 600;
    final maxWidth = isWeb ? 1400.0 : double.infinity;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 85,
        title: Row(
          children: [
            // Enhanced Logo with deeper shadow
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryColor, primaryColor.withOpacity(0.85)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.bloodtype_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 18),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LifePulse',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: primaryColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Blood Donation',
                  style: TextStyle(
                    fontSize: 12,
                    color: grayColor,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Enhanced Profile chip
          if (_profile?.name != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: lightGrayColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: primaryColor, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _profile!.name!,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 40 : 20,
                vertical: isWeb ? 32 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Unified Header Card with all donor info
                  _buildHeaderCard(isWeb, isMobile),

                  SizedBox(height: isWeb ? 40 : 28),

                  // Upcoming Appointments
                  if (_profile?.appointments.isNotEmpty == true) ...[
                    _buildAppointmentsSection(isWeb, isMobile),
                    SizedBox(height: isWeb ? 40 : 28),
                  ],

                  // Quick Stats - Responsive Layout
                  _buildQuickStats(isWeb, isMobile),

                  SizedBox(height: isWeb ? 48 : 36),

                  // Map Preview Section
                  _buildMapPreview(isWeb, isMobile),

                  SizedBox(height: isWeb ? 48 : 36),

                  // Combined Critical/Urgent Hospitals Section
                  if (_criticalHospitals.isNotEmpty || _myBloodTypeHospitals.isNotEmpty) ...[
                    _buildSectionHeader('Urgent Needs Near You', isWeb),
                    const SizedBox(height: 20),
                    
                    // Show critical hospitals first
                    ..._criticalHospitals
                        .take(2)
                        .map((h) => _buildHospitalCard(h, isWeb, isMobile)),
                    
                    // Then show blood type specific hospitals
                    ..._myBloodTypeHospitals
                        .where((h) => !_criticalHospitals.contains(h))
                        .take(2)
                        .map((h) => _buildHospitalCard(h, isWeb, isMobile)),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: MenuFAB(
        onLogout: _handleSignOut,
        isDashboard: true,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }

  Widget _buildHeaderCard(bool isWeb, bool isMobile) {
    // Get donor info from both profile and model
    final donor = _donorModel;
    final canDonate = _profile?.isEligibleToDonate ?? true;
    final daysUntil = _profile?.daysUntilEligible ?? 0;
    
    // Calculate eligibility from donor model if available
    bool isEligible = canDonate;
    int daysRemaining = daysUntil;
    
    if (donor?.lastDonation != null) {
      final lastDonationDate = DateTime.parse(donor!.lastDonation!.format());
      final eligibleDate = lastDonationDate.add(Duration(days: 56));
      final now = DateTime.now();
      
      if (now.isBefore(eligibleDate)) {
        daysRemaining = eligibleDate.difference(now).inDays;
        isEligible = false;
      } else {
        isEligible = true;
      }
    }

    return Container(
      padding: EdgeInsets.all(isWeb ? 36 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isEligible
              ? [primaryColor, primaryColor.withOpacity(0.9)]
              : [Colors.orange.shade600, Colors.orange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.25),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Blood Type Icon + User Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Blood Type Circle
              Container(
                width: isWeb ? 100 : 80,
                height: isWeb ? 100 : 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    donor?.bloodTypeDisplay ?? _profile?.bloodType ?? 'O+',
                    style: TextStyle(
                      fontSize: isWeb ? 36 : 28,
                      fontWeight: FontWeight.w900,
                      color: isEligible ? primaryColor : Colors.orange.shade700,
                    ),
                  ),
                ),
              ),
              SizedBox(width: isWeb ? 24 : 20),
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor?.name ?? _profile?.name ?? 'Donor',
                      style: TextStyle(
                        fontSize: isWeb ? 28 : 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: isWeb ? 16 : 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            donor?.email ?? _profile?.email ?? '',
                            style: TextStyle(
                              fontSize: isWeb ? 15 : 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (donor?.phone != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: isWeb ? 16 : 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            donor!.phone!,
                            style: TextStyle(
                              fontSize: isWeb ? 15 : 13,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: isWeb ? 32 : 24),
          
          // Eligibility Status Section
          Container(
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: isEligible 
              ? _buildEligibleStatusContent(isWeb, isMobile, donor)
              : _buildNotEligibleStatusContent(isWeb, isMobile, daysRemaining),
          ),
          
          // Find Hospitals Button
          if (isEligible) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _navigateToMap,
                icon: const Icon(Icons.location_on_rounded, size: 22),
                label: Text(
                  'Find Hospitals Near You',
                  style: TextStyle(
                    fontSize: isWeb ? 17 : 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: primaryColor,
                  padding: EdgeInsets.symmetric(
                    vertical: isWeb ? 20 : 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Eligible status content
  Widget _buildEligibleStatusContent(bool isWeb, bool isMobile, DonorModel? donor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? 16 : 14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
          ),
          child: Icon(
            Icons.check_circle_rounded,
            color: Colors.white,
            size: isWeb ? 40 : 32,
          ),
        ),
        SizedBox(width: isWeb ? 20 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You Can Donate!',
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.green.shade700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You can save lives today!',
                style: TextStyle(
                  fontSize: isWeb ? 15 : 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Not eligible status content
  Widget _buildNotEligibleStatusContent(bool isWeb, bool isMobile, int daysRemaining) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? 16 : 14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.orange.shade400, Colors.orange.shade600],
            ),
          ),
          child: Icon(
            Icons.schedule_rounded,
            color: Colors.white,
            size: isWeb ? 40 : 32,
          ),
        ),
        SizedBox(width: isWeb ? 20 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recovery Period',
                style: TextStyle(
                  fontSize: isWeb ? 24 : 20,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange.shade700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'You can donate again in $daysRemaining days',
                style: TextStyle(
                  fontSize: isWeb ? 13 : 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 18 : 14,
            vertical: isWeb ? 14 : 12,
          ),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.orange.shade200,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$daysRemaining',
                style: TextStyle(
                  fontSize: isWeb ? 32 : 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.orange.shade700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'days left',
                style: TextStyle(
                  fontSize: isWeb ? 12 : 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade600,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppointmentsSection(bool isWeb, bool isMobile) {
    final upcomingAppointments = _profile!.appointments
        .where((a) => a.status == AppointmentStatus.upcoming)
        .toList();

    if (upcomingAppointments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Upcoming Appointments', isWeb),
        const SizedBox(height: 20),
        ...upcomingAppointments.map((appointment) {
          return Container(
            margin: EdgeInsets.only(bottom: isWeb ? 20 : 16),
            padding: EdgeInsets.all(isWeb ? 24 : 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border(
                left: BorderSide(color: primaryColor, width: 5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? 14 : 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.15),
                        primaryColor.withOpacity(0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(appointment.date).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(appointment.date),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isWeb ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.hospitalName,
                        style: TextStyle(
                          fontSize: isWeb ? 17 : 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_rounded, 
                                size: 14, 
                                color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Text(
                              appointment.timeSlot,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade500],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Confirmed',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildQuickStats(bool isWeb, bool isMobile) {
    final criticalCount = _criticalHospitals.length;
    final totalDonations = _donationCount;
    final totalHospitals = _hospitals.length;

    // On mobile, stack vertically in 2-column grid
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Critical',
                  criticalCount.toString(),
                  Icons.local_hospital,
                  Colors.red,
                  isWeb,
                  isMobile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Donations',
                  totalDonations.toString(),
                  Icons.favorite,
                  primaryColor,
                  isWeb,
                  isMobile,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Hospitals',
                  totalHospitals.toString(),
                  Icons.business,
                  const Color(0xFF14B8A6),
                  isWeb,
                  isMobile,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Blood Units',
                  _totalBloodUnits.toString(),
                  Icons.water_drop_outlined,
                  const Color(0xFF9333EA),
                  isWeb,
                  isMobile,
                ),
              ),
            ],
          ),
        ],
      );
    }

    // On web/desktop, horizontal row with all 4 cards
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Critical',
            criticalCount.toString(),
            Icons.local_hospital,
            Colors.red,
            isWeb,
            isMobile,
          ),
        ),
        SizedBox(width: isWeb ? 20 : 12),
        Expanded(
          child: _buildStatCard(
            'Total Donations',
            totalDonations.toString(),
            Icons.favorite,
            primaryColor,
            isWeb,
            isMobile,
          ),
        ),
        SizedBox(width: isWeb ? 20 : 12),
        Expanded(
          child: _buildStatCard(
            'Total Hospitals',
            totalHospitals.toString(),
            Icons.business,
            const Color(0xFF14B8A6),
            isWeb,
            isMobile,
          ),
        ),
        SizedBox(width: isWeb ? 20 : 12),
        Expanded(
          child: _buildStatCard(
            'Total Blood Units',
            _totalBloodUnits.toString(),
            Icons.water_drop_outlined,
            const Color(0xFF9333EA),
            isWeb,
            isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isWeb,
    bool isMobile,
  ) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : isMobile ? 20 : 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: color.withOpacity(0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Enhanced gradient circular icon with multiple shadows
          Container(
            width: isWeb ? 80 : isMobile ? 60 : 70,
            height: isWeb ? 80 : isMobile ? 60 : 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color,
                  color.withOpacity(0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isWeb ? 40 : isMobile ? 30 : 36,
            ),
          ),
          SizedBox(height: isWeb ? 24 : 16),
          Text(
            value,
            style: TextStyle(
              fontSize: isWeb ? 42 : isMobile ? 32 : 38,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: isWeb ? 15 : 13,
              fontWeight: FontWeight.w700,
              color: Colors.grey[600],
              height: 1.3,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview(bool isWeb, bool isMobile) {
    return Container(
      height: isWeb ? 480 : 380,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Flutter Map with satellite view
            FlutterMap(
              options: MapOptions(
                initialCenter: const LatLng(7.5, 125.5), // Davao del Norte center
                initialZoom: 10.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none, // Disable interactions for preview
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.lifepulse.admin',
                  maxZoom: 19,
                ),
                // Add markers for hospitals
                MarkerLayer(
                  markers: _hospitals.take(10).map((hospital) {
                    return Marker(
                      point: LatLng(hospital.latitude, hospital.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getColorFromHex(hospital.urgencyColor),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_hospital,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            // Enhanced overlay with view full map button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(isWeb ? 28 : 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.95),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.location_on,
                                  color: primaryColor,
                                  size: isWeb ? 20 : 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Find Blood Banks Near You',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isWeb ? 20 : 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 44),
                            child: Text(
                              '${_hospitals.length} hospitals in Davao del Norte',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: isWeb ? 15 : 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _navigateToMap,
                      icon: const Icon(Icons.map_rounded, size: 20),
                      label: Text(
                        isMobile ? 'View' : 'View Full Map',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 28 : 20,
                          vertical: isWeb ? 18 : 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        shadowColor: primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 24 : 20,
        vertical: isWeb ? 20 : 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.1),
            primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isWeb ? 14 : 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.local_hospital_rounded,
              color: Colors.white,
              size: isWeb ? 28 : 24,
            ),
          ),
          const SizedBox(width: 18),
          Text(
            title,
            style: TextStyle(
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
              letterSpacing: -0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHospitalCard(Hospital hospital, bool isWeb, bool isMobile) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => HospitalBottomSheet(
            hospital: hospital,
            onClose: () => Navigator.pop(context),
          ),
        ).then((_) => _loadProfile()); // Reload profile to update appointments if booked
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: EdgeInsets.only(bottom: isWeb ? 24 : 20),
        padding: EdgeInsets.all(isWeb ? 32 : 26),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _getColorFromHex(hospital.urgencyColor).withOpacity(0.15),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Enhanced status indicator with icon - gradient background
                Container(
                  width: isWeb ? 68 : 56,
                  height: isWeb ? 68 : 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getColorFromHex(hospital.urgencyColor),
                        _getColorFromHex(hospital.urgencyColor).withOpacity(0.75),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: isWeb ? 34 : 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: TextStyle(
                          fontSize: isWeb ? 19 : 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _getColorFromHex(hospital.urgencyColor).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getColorFromHex(hospital.urgencyColor).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getColorFromHex(hospital.urgencyColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              hospital.urgencyLabel,
                              style: TextStyle(
                                fontSize: isWeb ? 13 : 12,
                                fontWeight: FontWeight.w700,
                                color: _getColorFromHex(hospital.urgencyColor),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Enhanced address with icon
            Container(
              padding: EdgeInsets.all(isWeb ? 16 : 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: isWeb ? 18 : 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hospital.address,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 13,
                        color: Colors.grey[700],
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Blood type availability with enhanced styling
            if (_profile?.bloodType != null &&
                hospital.bloodInventory.containsKey(_profile!.bloodType)) ...[
              const SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(isWeb ? 16 : 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      primaryColor.withOpacity(0.1),
                      primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: primaryColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        size: isWeb ? 22 : 20,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Blood Type Available',
                            style: TextStyle(
                              fontSize: isWeb ? 12 : 11,
                              fontWeight: FontWeight.w700,
                              color: primaryColor.withOpacity(0.8),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_profile!.bloodType}: ${hospital.bloodInventory[_profile!.bloodType]} units',
                            style: TextStyle(
                              fontSize: isWeb ? 16 : 15,
                              fontWeight: FontWeight.w800,
                              color: primaryColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to convert hex string to Color
  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}

// Custom painter for map pattern fallback
class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw grid pattern to simulate map roads
    final spacing = 60.0;
    
    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    // Horizontal lines
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
    
    // Draw some diagonal roads for more realistic look
    paint.strokeWidth = 3;
    paint.color = Colors.grey.withOpacity(0.15);
    
    canvas.drawLine(
      Offset(0, size.height * 0.3),
      Offset(size.width, size.height * 0.7),
      paint,
    );
    
    canvas.drawLine(
      Offset(size.width * 0.2, 0),
      Offset(size.width * 0.8, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
