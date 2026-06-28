import 'package:flutter/material.dart';
import '../../../constants.dart';

class LegendCard extends StatelessWidget {
  final bool isWebVersion;
  
  const LegendCard({Key? key, this.isWebVersion = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double scale = isWebVersion ? 1.3 : 1.0;
    // Override sizes for mobile - balanced between compact and readable
    final double titleSize = isWebVersion ? 18 * scale : 13;
    final double itemSpacing = isWebVersion ? 6 * scale : 4;
    final double topSpacing = isWebVersion ? 12 * scale : 8;
    final double padding = isWebVersion ? 16 * scale : 10;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWebVersion ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hospital Status',
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: topSpacing),
          _buildLegendItem(
            color: primaryColor,
            label: 'Critical',
            icon: Icons.warning_rounded,
            isWebVersion: isWebVersion,
          ),
          SizedBox(height: itemSpacing),
          _buildLegendItem(
            color: orangeAccent,
            label: 'Low Stock',
            icon: Icons.info_outline,
            isWebVersion: isWebVersion,
          ),
          SizedBox(height: itemSpacing),
          _buildLegendItem(
            color: const Color(0xFFFCD34D),
            label: 'Medium',
            icon: Icons.check_circle_outline,
            isWebVersion: isWebVersion,
          ),
          SizedBox(height: itemSpacing),
          _buildLegendItem(
            color: tealAccent,
            label: 'Well Stocked',
            icon: Icons.verified_outlined,
            isWebVersion: isWebVersion,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
    required bool isWebVersion,
  }) {
    final double iconSize = isWebVersion ? 28 * 1.3 : 22;
    final double iconInnerSize = isWebVersion ? 16 * 1.3 : 13;
    final double fontSize = isWebVersion ? 15 * 1.3 : 12;
    final double spacing = isWebVersion ? 10 * 1.3 : 8;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: iconInnerSize,
          ),
        ),
        SizedBox(width: spacing),
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: grayColor,
          ),
        ),
      ],
    );
  }
}
