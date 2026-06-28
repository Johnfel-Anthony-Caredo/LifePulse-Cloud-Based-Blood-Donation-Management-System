import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/hospital.dart';

class CriticalAlertsSection extends StatefulWidget {
  const CriticalAlertsSection({Key? key}) : super(key: key);

  @override
  State<CriticalAlertsSection> createState() => _CriticalAlertsSectionState();
}

class _CriticalAlertsSectionState extends State<CriticalAlertsSection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final hospitals = HospitalData.getDavaoDelNorteHospitals();
    
    // Get critical and low stock hospitals
    final criticalHospitals = hospitals
        .where((h) => h.urgency == HospitalUrgency.critical || h.urgency == HospitalUrgency.low)
        .toList();

    if (criticalHospitals.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only 3 by default, or all if expanded
    final hospitalsToShow = _showAll ? criticalHospitals : criticalHospitals.take(3).toList();
    final hasMore = criticalHospitals.length > 3;

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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Critical Alerts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${criticalHospitals.length}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${criticalHospitals.length} ${criticalHospitals.length == 1 ? 'hospital needs' : 'hospitals need'} attention',
            style: TextStyle(
              fontSize: 13,
              color: grayColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Alert list - Compact vertical layout for sidebar (showing 3 or all)
          ...hospitalsToShow.map((hospital) {
            final criticalBloodTypes = hospital.criticalBloodTypes;
            final urgencyColor = _getUrgencyColor(hospital.urgency);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital name and status
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: urgencyColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hospital.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 12,
                                  color: grayColor,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    hospital.address.split(',').first,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: grayColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // Critical blood types - VERTICAL layout for sidebar
                  if (criticalBloodTypes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blood Types Needed:',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: grayColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...criticalBloodTypes.map((bloodType) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: urgencyColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: urgencyColor.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      bloodType,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: urgencyColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${hospital.bloodInventory[bloodType]} units',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: grayColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                  
                  // Divider
                  if (hospital != hospitalsToShow.last)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Divider(color: Colors.grey[200]),
                    ),
                ],
              ),
            );
          }).toList(),
          
          // View More/Less button
          if (hasMore) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showAll = !_showAll;
                  });
                },
                icon: Icon(
                  _showAll ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                ),
                label: Text(
                  _showAll 
                    ? 'Show Less' 
                    : 'View ${criticalHospitals.length - 3} More',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                ),
              ),
            ),
          ],
          
          // Send Alert Button
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Send alerts to donors
              },
              icon: const Icon(Icons.notifications_active, size: 18),
              label: const Text('Send Alert'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getUrgencyColor(HospitalUrgency urgency) {
    switch (urgency) {
      case HospitalUrgency.critical:
        return const Color(0xFFDC143C);
      case HospitalUrgency.low:
        return orangeAccent;
      case HospitalUrgency.medium:
        return const Color(0xFFFCD34D);
      case HospitalUrgency.good:
        return tealAccent;
    }
  }
}
