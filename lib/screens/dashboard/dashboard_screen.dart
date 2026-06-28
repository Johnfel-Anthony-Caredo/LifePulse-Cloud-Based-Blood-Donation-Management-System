import 'package:admin_new/responsive.dart';
import 'package:admin_new/screens/dashboard/components/my_fields.dart';
import 'package:flutter/material.dart';

import '../../constants.dart';
import 'components/critical_alerts_section.dart';
import 'components/hospital_status_table.dart';
import 'components/recent_files.dart';
import 'components/storage_details.dart';
import '../shared/admin_page.dart';

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Dashboard',
      subtitle: 'Monitor blood inventory, hospital urgency, and recent donor activity.',
      children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      MyFiles(),
                      SizedBox(height: defaultPadding),
                      
                      // Hospital Status Table
                      HospitalStatusTable(),
                      SizedBox(height: defaultPadding),
                      
                      // Recent Donors at bottom
                      RecentFiles(),
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context)) StorageDetails(),
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                      if (Responsive.isMobile(context)) CriticalAlertsSection(),
                    ],
                  ),
                ),
                if (!Responsive.isMobile(context))
                  SizedBox(width: defaultPadding),
                // Right sidebar: Blood Inventory + Critical Alerts
                if (!Responsive.isMobile(context))
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        StorageDetails(),
                        SizedBox(height: defaultPadding),
                        CriticalAlertsSection(),
                      ],
                    ),
                  ),
              ],
            ),
      ],
    );
  }
}
