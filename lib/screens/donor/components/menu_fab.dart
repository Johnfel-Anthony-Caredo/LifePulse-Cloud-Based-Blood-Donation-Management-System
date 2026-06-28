import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../../constants.dart';
import '../appointments_list_screen.dart';
import '../donation_history_screen.dart';
import '../profile_screen.dart';
import '../donor_notifications_screen.dart';

class MenuFAB extends StatelessWidget {
  final VoidCallback onLogout;
  final bool isDashboard;

  const MenuFAB({
    Key? key, 
    required this.onLogout,
    this.isDashboard = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'menu_fab', // Add unique hero tag
      onPressed: () => _showMenuSheet(context),
      backgroundColor: primaryColor,
      elevation: 4,
      child: const Icon(
        Icons.menu_rounded,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  void _showMenuSheet(BuildContext context) {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MenuBottomSheet(
        onLogout: onLogout,
        isDashboard: isDashboard,
      ),
    );
  }
}

class _MenuBottomSheet extends StatelessWidget {
  final VoidCallback onLogout;
  final bool isDashboard;

  const _MenuBottomSheet({
    required this.onLogout,
    required this.isDashboard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Menu title
          Text(
            'Menu',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          
          // Menu items
          _buildMenuItem(
            context,
            icon: Icons.home_outlined,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
              if (!isDashboard) {
                Navigator.of(context).pop(); // Return to dashboard
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.calendar_today_outlined,
            title: 'My Appointments',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AppointmentsListScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.water_drop_outlined,
            title: 'My Donations',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DonationHistoryScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DonorNotificationsScreen(),
                ),
              );
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),
          _buildMenuItem(
            context,
            icon: Icons.logout_rounded,
            title: 'Logout',
            color: primaryColor,
            onTap: () {
              Navigator.pop(context); // Close menu
              onLogout();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? badge,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              color: color ?? grayColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
