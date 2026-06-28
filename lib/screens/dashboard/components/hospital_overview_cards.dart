import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/hospital.dart';

class HospitalOverviewCards extends StatelessWidget {
  const HospitalOverviewCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hospitals = HospitalData.getDavaoDelNorteHospitals();
    
    // Calculate statistics
    final total = hospitals.length;
    final critical = hospitals.where((h) => h.urgency == HospitalUrgency.critical).length;
    final medium = hospitals.where((h) => h.urgency == HospitalUrgency.medium).length;
    final good = hospitals.where((h) => h.urgency == HospitalUrgency.good).length;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Total Hospitals',
            value: total.toString(),
            icon: Icons.local_hospital_rounded,
            color: primaryColor,
            subtitle: 'Across Mindanao',
          ),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Critical',
            value: critical.toString(),
            icon: Icons.warning_rounded,
            color: const Color(0xFFDC143C),
            subtitle: 'Need urgent blood',
          ),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Medium Stock',
            value: medium.toString(),
            icon: Icons.inventory_2_outlined,
            color: const Color(0xFFFCD34D),
            subtitle: 'Moderate levels',
          ),
        ),
        const SizedBox(width: defaultPadding),
        Expanded(
          child: _buildStatCard(
            context,
            title: 'Well Stocked',
            value: good.toString(),
            icon: Icons.check_circle_outline,
            color: tealAccent,
            subtitle: 'Good inventory',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: grayColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: grayColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
