import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../models/donor_model.dart';
import '../../models/donation_history_model.dart';
import '../../models/hospital.dart';
import '../../services/donor_service.dart';
import '../../services/donation_history_service.dart';
import '../../services/hospital_service.dart';

class DonationHistoryScreen extends StatefulWidget {
  const DonationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<DonationHistoryScreen> createState() => _DonationHistoryScreenState();
}

class _DonationHistoryScreenState extends State<DonationHistoryScreen> {
  DonorModel? _donor;
  List<DonationHistoryModel> _donationHistory = [];
  Map<String, Hospital> _hospitals = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load donor profile
      final donor = await DonorService.getCurrentDonor();
      
      if (donor != null) {
        debugPrint('🩸 Loading donation history for donor: ${donor.id}');
        
        // Load donation history
        final history = await DonationHistoryService.listDonationHistoryByDonor(donor.id);
        
        debugPrint('🩸 Retrieved ${history.length} donation records');
        
        // Load hospitals
        final hospitals = await HospitalService.listHospitals();
        final hospitalMap = {
          for (var hospital in hospitals) hospital.id: hospital
        };
        
        setState(() {
          _donor = donor;
          _donationHistory = history;
          _hospitals = hospitalMap;
          _isLoading = false;
        });
      } else {
        debugPrint('❌ No donor profile found');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('❌ Error loading donation history: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading donation history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;
    final maxWidth = isWeb ? 1000.0 : double.infinity;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Donation History'),
        ),
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final totalDonations = _donationHistory.length;
    final livesSaved = totalDonations * 3; // Each donation saves ~3 lives
    // final totalUnitsGiven = _donationHistory.fold<int>(0, (sum, donation) => sum + donation.unitsGiven);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donation History',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 32 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Impact Summary Card
                  _buildImpactCard(totalDonations, livesSaved, isWeb),
                  
                  const SizedBox(height: 24),

                  // Achievement Badges
                  if (totalDonations > 0) ...[
                    _buildAchievementsSection(totalDonations, isWeb),
                    const SizedBox(height: 24),
                  ],

                  // Statistics Grid
                  _buildStatisticsGrid(isWeb),

                  const SizedBox(height: 32),

                  // Donation Timeline
                  _buildSectionHeader('Donation Timeline', isWeb),
                  const SizedBox(height: 16),

                  if (_donationHistory.isEmpty)
                    _buildEmptyState()
                  else
                    ..._donationHistory.map((donation) =>
                        _buildTimelineItem(donation, isWeb)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImpactCard(int totalDonations, int livesSaved, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.favorite,
            size: isWeb ? 64 : 48,
            color: Colors.white,
          ),
          const SizedBox(height: 16),
          Text(
            'Your Impact',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImpactStat(
                totalDonations.toString(),
                'Donations',
                Icons.water_drop,
                isWeb,
              ),
              Container(
                width: 1,
                height: 60,
                color: Colors.white.withOpacity(0.3),
              ),
              _buildImpactStat(
                '~$livesSaved',
                'Lives Saved',
                Icons.people,
                isWeb,
              ),
            ],
          ),
          if (totalDonations > 0) ...[
            const SizedBox(height: 24),
            Text(
              '🎉 Thank you for being a life saver!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isWeb ? 16 : 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImpactStat(String value, String label, IconData icon, bool isWeb) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isWeb ? 36 : 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: isWeb ? 18 : 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: isWeb ? 16 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementsSection(int totalDonations, bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Achievements', isWeb),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (totalDonations >= 1)
              _buildBadge('🩸', 'First Donation', 'Saved 3 lives', isWeb),
            if (totalDonations >= 3)
              _buildBadge('🏆', 'Committed', '3 donations', isWeb),
            if (totalDonations >= 5)
              _buildBadge('⭐', 'Regular Donor', '5 donations', isWeb),
            if (totalDonations >= 10)
              _buildBadge('💎', 'Hero', '10+ donations', isWeb),
            // Placeholder badges
            if (totalDonations < 3)
              _buildBadge('🔒', 'Committed', 'Donate 3 times', isWeb, locked: true),
            if (totalDonations < 5)
              _buildBadge('🔒', 'Regular Donor', 'Donate 5 times', isWeb, locked: true),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String emoji, String title, String subtitle, bool isWeb,
      {bool locked = false}) {
    return Container(
      width: isWeb ? 160 : 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: locked ? Colors.grey[100] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: locked ? Colors.grey[300]! : primaryColor.withOpacity(0.3),
        ),
        boxShadow: locked
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: TextStyle(
              fontSize: isWeb ? 36 : 32,
              color: locked ? Colors.grey : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: locked ? Colors.grey : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: locked ? Colors.grey : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsGrid(bool isWeb) {
    final lastDonation = _donor?.lastDonation;
    final daysSinceLast = lastDonation != null
        ? DateTime.now().difference(DateTime.parse(lastDonation.format())).inDays
        : null;

    // Calculate days until eligible
    int daysUntilEligible = 0;
    if (lastDonation != null) {
      final lastDonationDate = DateTime.parse(lastDonation.format());
      final eligibleDate = lastDonationDate.add(Duration(days: 56));
      final now = DateTime.now();
      if (now.isBefore(eligibleDate)) {
        daysUntilEligible = eligibleDate.difference(now).inDays;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Next Eligible',
            _donor?.isEligible == true
                ? 'Now!'
                : '$daysUntilEligible days',
            Icons.schedule,
            _donor?.isEligible == true ? Colors.green : Colors.orange,
            isWeb,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Days Since Last',
            daysSinceLast != null ? '$daysSinceLast days' : 'Never',
            Icons.calendar_today,
            Colors.blue,
            isWeb,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isWeb ? 32 : 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isWeb) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isWeb ? 20 : 18,
        fontWeight: FontWeight.w800,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTimelineItem(DonationHistoryModel donation, bool isWeb) {
    final hospital = _hospitals[donation.hospitalId];
    final hospitalName = hospital?.name ?? 'Unknown Hospital';
    final donationDate = DateTime.parse(donation.donationDate.format());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: primaryColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date Circle
          Container(
            width: isWeb ? 60 : 50,
            height: isWeb ? 60 : 50,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('MMM').format(donationDate).toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                Text(
                  DateFormat('dd').format(donationDate),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Donation Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospitalName,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.bloodtype, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      '${donation.bloodTypeDisplay} • ${donation.unitsGiven} unit${donation.unitsGiven > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (donation.notes != null && donation.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    donation.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Completed • ~${donation.unitsGiven * 3} lives saved',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
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
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      child: Column(
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'No donations yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start your journey as a life saver!\nBook your first donation today.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.water_drop),
            label: const Text('Find Hospitals'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
