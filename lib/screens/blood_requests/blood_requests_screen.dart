import 'package:admin_new/responsive.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/blood_request.dart';
import '../dashboard/components/header.dart';

class BloodRequestsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildComingSoonCard(),
                      SizedBox(height: defaultPadding),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoonCard() {
    return Container(
      padding: EdgeInsets.all(defaultPadding * 2),
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
        children: [
          Icon(
            Icons.construction,
            size: 64,
            color: primaryColor.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            'Blood Requests',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This feature is under development',
            style: TextStyle(
              fontSize: 16,
              color: grayColor,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

DataRow requestDataRow(BloodRequest request) {
  return DataRow(
    cells: [
      DataCell(Text(request.id!)),
      DataCell(Text(request.patientName!)),
      DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            request.bloodGroup!,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      DataCell(Text(request.units!)),
      DataCell(Text(request.hospital!)),
      DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getUrgencyColor(request.urgency!).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            request.urgency!,
            style: TextStyle(
              color: _getUrgencyColor(request.urgency!),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(request.status!).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            request.status!,
            style: TextStyle(
              color: _getStatusColor(request.status!),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}

Color _getUrgencyColor(String urgency) {
  switch (urgency.toLowerCase()) {
    case 'critical':
      return Color(0xFFDC143C);
    case 'high':
      return orangeAccent;
    case 'medium':
      return Color(0xFFFCD34D);
    case 'low':
      return tealAccent;
    default:
      return grayColor;
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return tealAccent;
    case 'in progress':
      return orangeAccent;
    case 'pending':
      return Color(0xFFFCD34D);
    default:
      return grayColor;
  }
}
