import 'dart:math';
import 'package:flutter/material.dart';
import '../../../constants.dart';

// Class to represent a falling blood drop
class FallingDrop {
  double left;
  double top;
  double speed;
  double size;
  double opacity;

  FallingDrop({
    required this.left,
    required this.top,
    required this.speed,
    required this.size,
    required this.opacity,
  });
}

class HeroSection extends StatefulWidget {
  const HeroSection({Key? key}) : super(key: key);

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _fallingDropsController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final List<FallingDrop> _fallingDrops = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Controller for continuous falling drops
    _fallingDropsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    _initializeFallingDrops();
  }

  void _initializeFallingDrops() {
    // Create initial falling drops
    final random = Random();
    for (int i = 0; i < 20; i++) {
      _fallingDrops.add(FallingDrop(
        left: random.nextDouble(),
        top: random.nextDouble() * -0.5,
        speed: 0.3 + random.nextDouble() * 0.7,
        size: 15 + random.nextDouble() * 25,
        opacity: 0.1 + random.nextDouble() * 0.2,
      ));
    }

    // Update drops continuously
    _fallingDropsController.addListener(() {
      setState(() {
        for (var drop in _fallingDrops) {
          drop.top += drop.speed * 0.01;
          // Reset drop to top when it falls off screen
          if (drop.top > 1.2) {
            drop.top = -0.1;
            drop.left = Random().nextDouble();
            drop.speed = 0.3 + Random().nextDouble() * 0.7;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _fallingDropsController.dispose();
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
            primaryColor.withOpacity(0.85),
            darkRedColor,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Heartbeat pattern background
          Positioned.fill(
            child: CustomPaint(
              painter: HeartbeatPatternPainter(),
            ),
          ),
          
          // Continuous falling blood drops
          ..._buildFallingBloodDrops(),
          
          // Animated blood drop particles
          ...List.generate(8, (index) => _buildFloatingBloodDrop(index)),
          
          // Main content with slide animation
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
                      // Logo with elevation and shadow
                      _buildLogoWithShadow(isMobile),
                      SizedBox(height: isMobile ? 24 : 32),
                      
                      // Tagline with better typography
                      Text(
                        'Saving Lives,\nOne Donation at a Time',
                        style: TextStyle(
                          fontSize: isMobile ? 24 : 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.3,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              offset: const Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Mission statement
                      Text(
                        'Connecting donors with those in need through\nefficient blood donation management',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                      ),
                      
                      if (!isMobile) ...[
                        const SizedBox(height: 48),
                        _buildEnhancedStatistics(),
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

  Widget _buildLogoWithShadow(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container with gradient
          Container(
            padding: EdgeInsets.all(isMobile ? 14 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tealAccent.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.bloodtype_rounded,
              size: isMobile ? 40 : 56,
              color: primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LifePulse',
                style: TextStyle(
                  fontSize: isMobile ? 36 : 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              Text(
                'Blood Donation System',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatistics() {
    final stats = [
      {'icon': Icons.people, 'value': '1,248', 'label': 'Active Donors', 'color': tealAccent},
      {'icon': Icons.water_drop, 'value': '456', 'label': 'Blood Units', 'color': orangeAccent},
      {'icon': Icons.assignment, 'value': '23', 'label': 'Pending Requests', 'color': Colors.white70},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon with background
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                // Value with bold typography
                Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                // Label
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildFallingBloodDrops() {
    return _fallingDrops.map((drop) {
      return Positioned(
        left: MediaQuery.of(context).size.width * drop.left,
        top: MediaQuery.of(context).size.height * drop.top,
        child: Opacity(
          opacity: drop.opacity,
          child: Icon(
            Icons.water_drop,
            size: drop.size,
            color: Colors.white,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFloatingBloodDrop(int index) {
    final random = Random(index);
    final left = random.nextDouble() * 0.8;
    final top = random.nextDouble() * 0.8;
    final delay = random.nextInt(1000);
    final size = 20.0 + random.nextDouble() * 30;

    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: MediaQuery.of(context).size.height * top,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 2000 + delay),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          final wave = sin(value * 2 * pi);
          return Transform.translate(
            offset: Offset(0, wave * 20),
            child: Opacity(
              opacity: 0.1 + (wave.abs() * 0.2),
              child: Icon(
                Icons.water_drop,
                size: size,
                color: Colors.white,
              ),
            ),
          );
        },
        onEnd: () {
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }
}

// Custom painter for heartbeat pattern
class HeartbeatPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final spacing = size.height / 6;

    for (int i = 0; i < 6; i++) {
      final y = spacing * i;
      path.moveTo(0, y);
      
      // Create heartbeat pattern
      for (double x = 0; x < size.width; x += 100) {
        path.lineTo(x + 20, y);
        path.lineTo(x + 30, y - 20);
        path.lineTo(x + 40, y + 15);
        path.lineTo(x + 50, y);
        path.lineTo(x + 100, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
