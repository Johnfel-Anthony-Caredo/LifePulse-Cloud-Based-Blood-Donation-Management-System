import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants.dart';
import '../../models/donor_profile.dart';
import 'donor_dashboard_screen.dart';

class DonorBloodTypeSetup extends StatefulWidget {
  const DonorBloodTypeSetup({Key? key}) : super(key: key);

  @override
  State<DonorBloodTypeSetup> createState() => _DonorBloodTypeSetupState();
}

class _DonorBloodTypeSetupState extends State<DonorBloodTypeSetup> {
  String? _selectedBloodType;
  bool _notificationsEnabled = true;
  final TextEditingController _nameController = TextEditingController();

  final List<String> bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedBloodType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your blood type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final profile = DonorProfile(
        name: _nameController.text.trim(),
        bloodType: _selectedBloodType,
        notificationsEnabled: _notificationsEnabled,
        radiusKm: 50.0,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('donor_profile', profile.toJsonString());
      await prefs.setBool('onboarding_completed', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DonorDashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _skip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DonorDashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.of(context).size.width > 800;
    final maxWidth = isWeb ? 600.0 : double.infinity;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isWeb ? 48 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Skip button
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Skip for now',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: isWeb ? 40 : 24),

                  // Icon
                  Container(
                    width: isWeb ? 120 : 100,
                    height: isWeb ? 120 : 100,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: isWeb ? 60 : 50,
                      color: primaryColor,
                    ),
                  ),

                  SizedBox(height: isWeb ? 32 : 24),

                  // Title
                  Text(
                    'Complete Your Profile',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isWeb ? 28 : 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),

                  SizedBox(height: isWeb ? 16 : 12),

                  Text(
                    'Help us personalize your experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      color: Colors.grey[600],
                    ),
                  ),

                  SizedBox(height: isWeb ? 48 : 32),

                  // Name field
                  Text(
                    'Your Name',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                    ),
                  ),

                  SizedBox(height: isWeb ? 32 : 24),

                  // Blood type selection
                  Text(
                    'Blood Type',
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: isWeb ? 16 : 12,
                      mainAxisSpacing: isWeb ? 16 : 12,
                      childAspectRatio: isWeb ? 1.5 : 1.2,
                    ),
                    itemCount: bloodTypes.length,
                    itemBuilder: (context, index) {
                      final bloodType = bloodTypes[index];
                      final isSelected = _selectedBloodType == bloodType;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedBloodType = bloodType;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? primaryColor : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey[300]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              bloodType,
                              style: TextStyle(
                                fontSize: isWeb ? 20 : 18,
                                fontWeight: FontWeight.w700,
                                color:
                                    isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  SizedBox(height: isWeb ? 32 : 24),

                  // Notifications toggle
                  Container(
                    padding: EdgeInsets.all(isWeb ? 20 : 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.notifications,
                          color: primaryColor,
                          size: isWeb ? 28 : 24,
                        ),
                        SizedBox(width: isWeb ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable Notifications',
                                style: TextStyle(
                                  fontSize: isWeb ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'Get alerts for critical blood needs',
                                style: TextStyle(
                                  fontSize: isWeb ? 14 : 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() {
                              _notificationsEnabled = value;
                            });
                          },
                          activeColor: primaryColor,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isWeb ? 48 : 32),

                  // Save button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue to Dashboard',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
