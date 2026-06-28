import 'package:flutter/material.dart';

class BloodStats {
  final String? svgSrc, title, count, subtitle;
  final int? percentage;
  final Color? color;

  BloodStats({
    this.svgSrc,
    this.title,
    this.count,
    this.subtitle,
    this.percentage,
    this.color,
  });
}

List demoBloodStats = [
  BloodStats(
    title: "Total Donors",
    count: "1,248",
    subtitle: "Active donors",
    svgSrc: "assets/icons/menu_profile.svg",
    color: Color(0xFF26E5FF),
    percentage: 85,
  ),
  BloodStats(
    title: "Pending Requests",
    count: "23",
    subtitle: "Awaiting fulfillment",
    svgSrc: "assets/icons/menu_tran.svg",
    color: Color(0xFFFFA113),
    percentage: 15,
  ),
  BloodStats(
    title: "Blood Units",
    count: "456",
    subtitle: "Units in stock",
    svgSrc: "assets/icons/menu_store.svg",
    color: Color(0xFFA4CDFF),
    percentage: 65,
  ),
  BloodStats(
    title: "Total Hospitals",
    count: "20",
    subtitle: "Across Mindanao",
    svgSrc: "assets/icons/menu_notification.svg",
    color: Color(0xFFEE5858),
    percentage: 100,
  ),
];
