import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../constants.dart';

class StorageDetails extends StatelessWidget {
  const StorageDetails({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Blood Inventory",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: defaultPadding),
          // Donut Chart
          Center(
            child: SizedBox(
              height: 200,
              width: 200,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(200, 200),
                    painter: DonutChartPainter(),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "359",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          "Total Units",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: defaultPadding),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "A+",
            amountOfFiles: "120",
            numOfFiles: 120,
            color: Color(0xFFDC143C),
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "O+",
            amountOfFiles: "95",
            numOfFiles: 95,
            color: tealAccent,
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "B+",
            amountOfFiles: "65",
            numOfFiles: 65,
            color: orangeAccent,
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "AB+",
            amountOfFiles: "40",
            numOfFiles: 40,
            color: Color(0xFFFCD34D),
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "A-",
            amountOfFiles: "35",
            numOfFiles: 35,
            color: Color(0xFFDC143C),
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "O-",
            amountOfFiles: "28",
            numOfFiles: 28,
            color: orangeAccent,
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "B-",
            amountOfFiles: "22",
            numOfFiles: 22,
            color: tealAccent,
          ),
          StorageInfoCard(
            svgSrc: "assets/icons/menu_doc.svg",
            title: "AB-",
            amountOfFiles: "15",
            numOfFiles: 15,
            color: Color(0xFFDC143C),
          ),
        ],
      ),
    );
  }
}

class StorageInfoCard extends StatelessWidget {
  const StorageInfoCard({
    Key? key,
    required this.title,
    required this.svgSrc,
    required this.amountOfFiles,
    required this.numOfFiles,
    required this.color,
  }) : super(key: key);

  final String title, svgSrc, amountOfFiles;
  final int numOfFiles;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: defaultPadding),
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: color.withOpacity(0.15)),
        borderRadius: const BorderRadius.all(
          Radius.circular(defaultPadding),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            height: 20,
            width: 20,
            child: Icon(
              Icons.water_drop,
              color: color,
              size: 18,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "$amountOfFiles units",
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
          Text(
            amountOfFiles,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          )
        ],
      ),
    );
  }
}

class DonutChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = 30.0;
    
    // Total units
    final total = 420.0;
    
    // Blood type data with colors
    final bloodData = [
      {'units': 120.0, 'color': Color(0xFFDC143C)}, // A+ - Red
      {'units': 95.0, 'color': Color(0xFFFF6B6B)},  // O+ - Light Red
      {'units': 65.0, 'color': Color(0xFFFCD34D)},  // B+ - Yellow
      {'units': 40.0, 'color': Color(0xFF4ECDC4)},  // AB+ - Cyan
      {'units': 35.0, 'color': Color(0xFF95E1D3)},  // A- - Light Cyan
      {'units': 28.0, 'color': Color(0xFFF38181)},  // O- - Pink
      {'units': 22.0, 'color': Color(0xFFAA96DA)},  // B- - Purple
      {'units': 15.0, 'color': Color(0xFFFCBF49)},  // AB- - Orange
    ];
    
    double startAngle = -math.pi / 2; // Start from top
    
    for (var data in bloodData) {
      final sweepAngle = ((data['units'] as double) / total) * 2 * math.pi;
      
      final paint = Paint()
        ..color = data['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
