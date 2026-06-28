import 'package:flutter/material.dart';
import '../../../constants.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({Key? key}) : super(key: key);

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 768;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor,
            darkRedColor,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated blood drop particles in background
          ...List.generate(8, (index) => _buildFloatingBloodDrop(index)),
          
          // Main content
          Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? defaultPadding * 2 : defaultPadding * 4),
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo with blood drop icon
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.bloodtype_rounded,
                              size: isMobile ? 40 : 56,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'LifePulse',
                            style: TextStyle(
                              fontSize: isMobile ? 32 : 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 16 : 24),
                      
                      // Tagline
                      Text(
                        'Blood Donation\nManagement System',
                        style: TextStyle(
                          fontSize: isMobile ? 20 : 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.95),
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: isMobile ? 12 : 16),
                      
                      // Mission statement
                      Container(
                        constraints: BoxConstraints(maxWidth: isMobile ? 300 : 400),
                        child: Text(
                          'Saving Lives, One Donation at a Time',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      if (!isMobile) ...[
                        const SizedBox(height: 40),
                        // Statistics
                        Row(
                          children: [
                            _buildStat('1,248', 'Active Donors'),
                            const SizedBox(width: 40),
                            _buildStat('456', 'Blood Units'),
                            const SizedBox(width: 40),
                            _buildStat('23', 'Pending Requests'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBloodDrop(int index) {
    final random = (index * 137.5) % 1;
    final duration = 3 + (random * 4);
    final size = 40.0 + (random * 60);
    final left = (index * 123.456) % 100;
    
    return Positioned(
      left: left.toDouble(),
      top: -50,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(seconds: duration.toInt()),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, MediaQuery.of(context).size.height * value),
            child: Opacity(
              opacity: 0.1 * (1 - value),
              child: Icon(
                Icons.water_drop_rounded,
                size: size,
                color: Colors.white,
              ),
            ),
          );
        },
        onEnd: () {
          // Loop animation
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
