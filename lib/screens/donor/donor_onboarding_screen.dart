import 'package:flutter/material.dart';
import '../../constants.dart';
import 'donor_blood_type_setup.dart';

class DonorOnboardingScreen extends StatefulWidget {
  const DonorOnboardingScreen({Key? key}) : super(key: key);

  @override
  State<DonorOnboardingScreen> createState() => _DonorOnboardingScreenState();
}

class _DonorOnboardingScreenState extends State<DonorOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.water_drop,
      iconColor: primaryColor,
      title: 'Welcome to LifePulse!',
      description: 'Find hospitals that need your blood type and save lives in your community',
      image: '🩸',
    ),
    OnboardingPage(
      icon: Icons.location_on,
      iconColor: primaryColor,
      title: 'See Hospitals Near You',
      description: 'Hospitals are marked with colors showing how urgently they need blood donations',
      legendItems: [
        LegendItem('Critical', Colors.red, 'Urgent need'),
        LegendItem('Low Stock', Colors.orange, 'Need soon'),
        LegendItem('Medium', Color(0xFFFCD34D), 'Moderate stock'),
        LegendItem('Well Stocked', Color(0xFF14B8A6), 'Sufficient'),
      ],
    ),
    OnboardingPage(
      icon: Icons.local_hospital,
      iconColor: primaryColor,
      title: 'Donate & Save Lives',
      description: 'Tap any hospital to see blood types needed, available units, contact information, and directions',
      features: [
        '✓ Blood types needed',
        '✓ Available units',
        '✓ Contact information',
        '✓ Get directions',
      ],
    ),
    OnboardingPage(
      icon: Icons.person,
      iconColor: primaryColor,
      title: 'Set Your Blood Type',
      description: 'Let us show you hospitals that specifically need YOUR blood type',
      isLastPage: true,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Navigate to blood type setup
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DonorBloodTypeSetup()),
      );
    }
  }

  void _skipToEnd() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const DonorBloodTypeSetup()),
    );
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
            child: Column(
              children: [
                // Skip button
                if (_currentPage < _pages.length - 1)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextButton(
                        onPressed: _skipToEnd,
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return _buildPage(_pages[index], isWeb);
                    },
                  ),
                ),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => _buildIndicator(index == _currentPage),
                    ),
                  ),
                ),

                // Next button
                Padding(
                  padding: EdgeInsets.all(isWeb ? 32 : 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, bool isWeb) {
    final padding = isWeb ? 48.0 : 24.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // Icon or Image
          Container(
            width: isWeb ? 150 : 120,
            height: isWeb ? 150 : 120,
            decoration: BoxDecoration(
              color: page.iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: isWeb ? 80 : 60,
              color: page.iconColor,
            ),
          ),

          SizedBox(height: isWeb ? 48 : 32),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWeb ? 32 : 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: isWeb ? 24 : 16),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isWeb ? 18 : 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),

          SizedBox(height: isWeb ? 48 : 32),

          // Legend items (for page 2)
          if (page.legendItems != null)
            Column(
              children: page.legendItems!
                  .map((item) => _buildLegendItem(item, isWeb))
                  .toList(),
            ),

          // Features (for page 3)
          if (page.features != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: page.features!
                  .map((feature) => _buildFeature(feature, isWeb))
                  .toList(),
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildLegendItem(LegendItem item, bool isWeb) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: isWeb ? 40 : 32,
            height: isWeb ? 40 : 32,
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_hospital,
              color: Colors.white,
              size: isWeb ? 24 : 18,
            ),
          ),
          SizedBox(width: isWeb ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: isWeb ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String feature, bool isWeb) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: primaryColor,
            size: isWeb ? 28 : 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: TextStyle(
                fontSize: isWeb ? 18 : 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String? image;
  final List<LegendItem>? legendItems;
  final List<String>? features;
  final bool isLastPage;

  OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.image,
    this.legendItems,
    this.features,
    this.isLastPage = false,
  });
}

class LegendItem {
  final String label;
  final Color color;
  final String description;

  LegendItem(this.label, this.color, this.description);
}
