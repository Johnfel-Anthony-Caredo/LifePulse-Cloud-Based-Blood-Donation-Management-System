import 'package:admin_new/models/blood_stats.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../constants.dart';

class FileInfoCard extends StatelessWidget {
  const FileInfoCard({
    Key? key,
    required this.info,
  }) : super(key: key);

  final BloodStats info;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isVerySmall = screenSize.width < 650;
    
    return Container(
      padding: EdgeInsets.all(isVerySmall ? defaultPadding * 0.6 : defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: lightRedColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: info.color!.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(isVerySmall ? defaultPadding * 0.4 : defaultPadding * 0.75),
                height: isVerySmall ? 28 : 40,
                width: isVerySmall ? 28 : 40,
                decoration: BoxDecoration(
                  color: info.color!.withOpacity(0.15),
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                ),
                child: SvgPicture.asset(
                  info.svgSrc!,
                  colorFilter: ColorFilter.mode(
                      info.color ?? Colors.black, BlendMode.srcIn),
                ),
              ),
              Icon(Icons.more_vert, color: Colors.black54, size: isVerySmall ? 16 : 24)
            ],
          ),
          SizedBox(height: isVerySmall ? 4 : 8),
          Flexible(
            child: Text(
              info.title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                fontSize: isVerySmall ? 11 : 15,
              ),
            ),
          ),
          SizedBox(height: isVerySmall ? 2 : 4),
          ProgressLine(
            color: info.color,
            percentage: info.percentage,
          ),
          SizedBox(height: isVerySmall ? 4 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                info.count!,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall!
                    .copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: isVerySmall ? 16 : null,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: isVerySmall ? 1 : 4),
              Text(
                info.subtitle!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall!
                    .copyWith(
                      color: Colors.black54,
                      fontSize: isVerySmall ? 9 : null,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
