import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../models/hospital.dart';
import '../../../responsive.dart';

class HospitalStatusTable extends StatefulWidget {
  const HospitalStatusTable({Key? key}) : super(key: key);

  @override
  State<HospitalStatusTable> createState() => _HospitalStatusTableState();
}

class _HospitalStatusTableState extends State<HospitalStatusTable> {
  HospitalUrgency? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final hospitals = HospitalData.getDavaoDelNorteHospitals();
    final isMobile = Responsive.isMobile(context);
    
    // Apply filter
    final filteredHospitals = _selectedFilter == null
        ? hospitals
        : hospitals.where((h) => h.urgency == _selectedFilter).toList();

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hospital Status Overview',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Showing ${filteredHospitals.length} of ${hospitals.length} hospitals',
                      style: TextStyle(
                        fontSize: 13,
                        color: grayColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  // Filter dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: lightGrayColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<HospitalUrgency?>(
                      value: _selectedFilter,
                      hint: Text('All Status', style: TextStyle(fontSize: isMobile ? 12 : 14)),
                      underline: const SizedBox(),
                      icon: const Icon(Icons.filter_list, size: 18),
                      items: [
                        DropdownMenuItem(
                          value: null,
                          child: Text('All Status'),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.critical,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC143C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Critical'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.low,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: orangeAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Low Stock'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.medium,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFCD34D),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Medium'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HospitalUrgency.good,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: tealAccent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('Well Stocked'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedFilter = value;
                        });
                      },
                    ),
                  ),
                  // Hide View Map button on mobile
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to donor map
                      },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('View Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: lightGrayColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Hospital Name',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: grayColor,
                          ),
                        ),
                      ),
                      // Hide City column on mobile
                      if (!isMobile)
                        Expanded(
                          flex: 2,
                          child: Text(
                            'City',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: grayColor,
                            ),
                          ),
                        ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: grayColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 50),
                    ],
                  ),
                ),
                
                // Table rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredHospitals.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey[200],
                  ),
                  itemBuilder: (context, index) {
                    final hospital = filteredHospitals[index];
                    final urgencyColor = _getUrgencyColor(hospital.urgency);
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hospital.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.phone,
                                      size: 12,
                                      color: grayColor.withOpacity(0.7),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hospital.phone,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: grayColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Hide City column on mobile
                          if (!isMobile)
                            Expanded(
                              flex: 2,
                              child: Text(
                                hospital.address.split(',').first,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: grayColor,
                                ),
                              ),
                            ),
                          Expanded(
                            flex: 1,
                            child: Container(
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
                                hospital.urgencyLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: urgencyColor,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // TODO: Show hospital details dialog
                            },
                            icon: Icon(
                              Icons.visibility_outlined,
                              size: 20,
                              color: primaryColor,
                            ),
                            tooltip: 'View Details',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
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
