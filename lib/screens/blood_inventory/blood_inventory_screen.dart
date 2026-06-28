import 'package:admin_new/responsive.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/blood_inventory.dart';
import '../shared/admin_page.dart';

class BloodInventoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Blood Inventory',
      subtitle: 'Track blood stock levels by type and stock status.',
      children: [
        Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      BloodInventoryGrid(),
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                    ],
                  ),
                ),
              ],
            ),
      ],
    );
  }
}

class BloodInventoryGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Size _size = MediaQuery.of(context).size;
    return Column(
      children: [
        Responsive(
          mobile: BloodInventoryGridView(
            crossAxisCount: _size.width < 650 ? 2 : 4,
            childAspectRatio: _size.width < 650 ? 1.1 : 0.9,
          ),
          tablet: BloodInventoryGridView(
            childAspectRatio: 0.95,
          ),
          desktop: BloodInventoryGridView(
            childAspectRatio: _size.width < 1400 ? 1.0 : 1.3,
          ),
        ),
      ],
    );
  }
}

class BloodInventoryGridView extends StatelessWidget {
  const BloodInventoryGridView({
    Key? key,
    this.crossAxisCount = 4,
    this.childAspectRatio = 1,
  }) : super(key: key);

  final int crossAxisCount;
  final double childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: demoBloodInventory.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: defaultPadding,
        mainAxisSpacing: defaultPadding,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) =>
          BloodInventoryCard(info: demoBloodInventory[index]),
    );
  }
}

class BloodInventoryCard extends StatelessWidget {
  const BloodInventoryCard({
    Key? key,
    required this.info,
  }) : super(key: key);

  final BloodInventory info;

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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(defaultPadding * 0.75),
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: _getStatusColor(info.status!).withOpacity(0.1),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: Icon(
                  Icons.water_drop,
                  color: _getStatusColor(info.status!),
                  size: 20,
                ),
              ),
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(info.status!).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    info.status!,
                    style: TextStyle(
                      color: _getStatusColor(info.status!),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Spacer(),
          Text(
            info.bloodGroup!,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          Spacer(),
          ProgressLine(
            color: _getStatusColor(info.status!),
            percentage: info.percentage,
          ),
          SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  info.units!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                "${info.percentage}%",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class ProgressLine extends StatelessWidget {
  const ProgressLine({
    Key? key,
    this.color = primaryColor,
    required this.percentage,
  }) : super(key: key);

  final Color? color;
  final int? percentage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: 5,
          decoration: BoxDecoration(
            color: color!.withOpacity(0.1),
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) => Container(
            width: constraints.maxWidth * (percentage! / 100),
            height: 5,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}

Color _getStatusColor(String status) {
  switch (status.toLowerCase()) {
    case 'good stock':
      return tealAccent;
    case 'medium stock':
      return Color(0xFFFCD34D);
    case 'low stock':
      return orangeAccent;
    case 'critical':
      return Color(0xFFDC143C);
    default:
      return grayColor;
  }
}
