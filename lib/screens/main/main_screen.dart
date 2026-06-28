import 'package:admin_new/controllers/menu_app_controller.dart';
import 'package:admin_new/responsive.dart';
import 'package:admin_new/screens/dashboard/dashboard_screen.dart';
import 'package:admin_new/screens/hospitals/hospitals_screen.dart';
import 'package:admin_new/screens/maps/admin_map_screen.dart';
import 'package:admin_new/screens/donors/donors_screen_new.dart';
import 'package:admin_new/screens/appointments/appointments_screen.dart';
import 'package:admin_new/screens/blood_requests/blood_requests_screen_new.dart';
import 'package:admin_new/screens/blood_inventory/blood_inventory_screen.dart';
import 'package:admin_new/screens/notifications/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'components/side_menu.dart';

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: context.read<MenuAppController>().scaffoldKey,
      drawer: SideMenu(),
      body: Container(
        // Beautiful gradient background
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF), // Pure white
              Color(0xFFFFF5F5), // Very light pink
              Color(0xFFFFE4E4), // Light pink
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // We want this side menu only for large screen
              if (Responsive.isDesktop(context))
                Expanded(
                  // default flex = 1
                  // and it takes 1/6 part of the screen
                  child: SideMenu(),
                ),
              Expanded(
                // It takes 5/6 part of the screen
                flex: 5,
                child: Consumer<MenuAppController>(
                  builder: (context, controller, child) {
                    return _getScreen(controller.selectedIndex);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getScreen(int index) {
    switch (index) {
      case 0:
        return DashboardScreen();
      case 1:
        return HospitalsScreen();
      case 2:
        return AdminMapScreen();
      case 3:
        return const DonorsScreen();
      case 4:
        return const AppointmentsScreen();
      case 5:
        return const BloodRequestsScreenNew();
      case 6:
        return const NotificationsScreen();
      default:
        return DashboardScreen();
    }
  }
}
