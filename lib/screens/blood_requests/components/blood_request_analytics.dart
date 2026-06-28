import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/blood_request_model.dart';

class BloodRequestAnalytics extends StatelessWidget {
  final List<BloodRequestModel> requests;

  const BloodRequestAnalytics({Key? key, required this.requests}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate stats
    final totalRequests = requests.length;
    final pendingRequests = requests.where((r) => r.status == RequestStatus.PENDING).length;
    final fulfilledRequests = requests.where((r) => r.status == RequestStatus.FULFILLED).length;
    final cancelledRequests = requests.where((r) => r.status == RequestStatus.CANCELLED).length;
    
    final criticalRequests = requests.where((r) => r.urgency == HospitalUrgency.CRITICAL).length;
    final highRequests = requests.where((r) => r.urgency == HospitalUrgency.HIGH).length;
    final mediumRequests = requests.where((r) => r.urgency == HospitalUrgency.MEDIUM).length;
    final lowRequests = requests.where((r) => r.urgency == HospitalUrgency.LOW).length;
    
    final expiredRequests = requests.where((r) => r.isExpired).length;
    final expiringSoonRequests = requests.where((r) => r.isExpiringSoon && !r.isExpired).length;
    
    // Calculate fulfillment rate
    final completedTotal = fulfilledRequests + cancelledRequests;
    final fulfillmentRate = completedTotal > 0 
        ? (fulfilledRequests / completedTotal * 100).toStringAsFixed(1)
        : '0.0';
    
    // Calculate average units needed
    final totalUnits = requests.fold<int>(0, (sum, r) => sum + r.unitsNeeded);
    final avgUnits = totalRequests > 0 
        ? (totalUnits / totalRequests).toStringAsFixed(1)
        : '0.0';
    
    // Blood type distribution
    final bloodTypeCount = <String, int>{};
    for (var request in requests) {
      final btString = request.bloodType.toString().split('.').last;
      bloodTypeCount[btString] = (bloodTypeCount[btString] ?? 0) + 1;
    }
    
    // Calculate response time (for fulfilled requests)
    final fulfilledList = requests.where((r) => r.status == RequestStatus.FULFILLED && r.fulfilledAt != null).toList();
    double avgResponseHours = 0;
    if (fulfilledList.isNotEmpty) {
      double totalHours = 0;
      for (var req in fulfilledList) {
        final fulfilledDate = DateTime.parse(req.fulfilledAt!.format());
        final createdDate = DateTime.parse(req.createdAt!.format());
        final duration = fulfilledDate.difference(createdDate);
        totalHours += duration.inHours;
      }
      avgResponseHours = totalHours / fulfilledList.length;
    }

    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text(
                'Request Analytics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Requests',
                  totalRequests.toString(),
                  Icons.list_alt,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Fulfillment Rate',
                  '$fulfillmentRate%',
                  Icons.check_circle,
                  tealAccent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Response',
                  '${avgResponseHours.toStringAsFixed(1)}h',
                  Icons.timer,
                  Colors.purple,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Units',
                  avgUnits,
                  Icons.water_drop,
                  primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Status Distribution
          _buildSectionTitle('Status Distribution'),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  'Pending',
                  pendingRequests,
                  totalRequests,
                  orangeAccent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProgressBar(
                  'Fulfilled',
                  fulfilledRequests,
                  totalRequests,
                  tealAccent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProgressBar(
                  'Cancelled',
                  cancelledRequests,
                  totalRequests,
                  primaryColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          
          // Urgency Distribution
          _buildSectionTitle('Urgency Levels'),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildProgressBar(
                  'Critical',
                  criticalRequests,
                  totalRequests,
                  Color(0xFFDC143C),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProgressBar(
                  'High',
                  highRequests,
                  totalRequests,
                  orangeAccent,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProgressBar(
                  'Medium',
                  mediumRequests,
                  totalRequests,
                  Color(0xFFFCD34D),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildProgressBar(
                  'Low',
                  lowRequests,
                  totalRequests,
                  tealAccent,
                ),
              ),
            ],
          ),
          
          if (expiredRequests > 0 || expiringSoonRequests > 0) ...[
            SizedBox(height: 20),
            _buildSectionTitle('Expiry Status'),
            SizedBox(height: 12),
            Row(
              children: [
                if (expiredRequests > 0)
                  Expanded(
                    child: _buildAlertCard(
                      'Expired',
                      expiredRequests,
                      Icons.error,
                      primaryColor,
                    ),
                  ),
                if (expiredRequests > 0 && expiringSoonRequests > 0)
                  SizedBox(width: 12),
                if (expiringSoonRequests > 0)
                  Expanded(
                    child: _buildAlertCard(
                      'Expiring Soon',
                      expiringSoonRequests,
                      Icons.warning,
                      orangeAccent,
                    ),
                  ),
              ],
            ),
          ],
          
          if (bloodTypeCount.isNotEmpty) ...[
            SizedBox(height: 20),
            _buildSectionTitle('Blood Type Distribution'),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: bloodTypeCount.entries.map((entry) {
                return _buildBloodTypeChip(
                  entry.key,
                  entry.value,
                  totalRequests,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: grayColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '$count (${percentage.toStringAsFixed(0)}%)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: total > 0 ? count / total : 0,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertCard(String label, int count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodTypeChip(String bloodType, int count, int total) {
    final percentage = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0.0';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              bloodType,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$count ($percentage%)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
