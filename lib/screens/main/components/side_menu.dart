import 'package:admin_new/controllers/menu_app_controller.dart';
import 'package:admin_new/constants.dart';
import 'package:admin_new/screens/auth/login_screen.dart';
import 'package:admin_new/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      // Gradient background for sidebar
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor, // Crimson red
            darkRedColor, // Dark red
          ],
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bloodtype,
                      size: 40,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "LifePulse",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "Blood Donation System",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          DrawerListTile(
            title: "Dashboard",
            svgSrc: "assets/icons/menu_dashboard.svg",
            press: () {
              context.read<MenuAppController>().changeScreen(0);
            },
            index: 0,
          ),
          DrawerListTile(
            title: "Hospitals",
            svgSrc: "assets/icons/menu_store.svg",
            press: () {
              context.read<MenuAppController>().changeScreen(1);
            },
            index: 1,
          ),
          DrawerListTile(
            title: "Maps",
            svgSrc: "assets/icons/menu_dashboard.svg",
            press: () {
              context.read<MenuAppController>().changeScreen(2);
            },
            index: 2,
          ),
          DrawerListTile(
            title: "Donors",
            svgSrc: "assets/icons/menu_profile.svg",
            press: () {
              context.read<MenuAppController>().changeScreen(3);
            },
            index: 3,
          ),
          DrawerListTile(
            title: "Appointments",
            svgSrc: "assets/icons/menu_doc.svg",
            press: () {
              context.read<MenuAppController>().changeScreen(4);
            },
            index: 4,
          ),
          DrawerListTile(
            title: "Blood Requests",
            svgSrc: "assets/icons/menu_doc.svg",
            press: () {
              context.read<MenuAppController>().changeScreen(5);
            },
            index: 5,
          ),
          DrawerListTile(
            title: "Notifications",
            svgSrc: "assets/icons/menu_notification.svg",
            press: () {
              context.read<MenuAppController>().changeScreen(6);
            },
            index: 6,
          ),
          // Logout Button
          Container(
            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListTile(
              onTap: () {
                _showLogoutDialog(context);
              },
              horizontalTitleGap: 0.0,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(
                Icons.logout,
                color: Colors.white70,
                size: 20,
              ),
              title: Text(
                "Logout",
                style: TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: primaryColor),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Sign out from Amplify first
                try {
                  await AuthService.signOut();
                  print('✅ Successfully signed out');
                } catch (e) {
                  print('❌ Error signing out: $e');
                }
                
                // Close dialog
                if (context.mounted) {
                  Navigator.of(context).pop();
                  
                  // Navigate to login screen and clear all routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}

class DrawerListTile extends StatelessWidget {
  const DrawerListTile({
    Key? key,
    // For selecting those three line once press "Command+D"
    required this.title,
    required this.svgSrc,
    required this.press,
    required this.index,
  }) : super(key: key);

  final String title, svgSrc;
  final VoidCallback press;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Consumer<MenuAppController>(
      builder: (context, controller, child) {
        bool isSelected = controller.selectedIndex == index;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.white.withOpacity(0.2) 
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected 
                ? Border.all(color: Colors.white.withOpacity(0.3), width: 1)
                : null,
          ),
          child: ListTile(
            onTap: press,
            horizontalTitleGap: 0.0,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: SvgPicture.asset(
              svgSrc,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : Colors.white70,
                BlendMode.srcIn,
              ),
              height: 20,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
    );
  }
}
