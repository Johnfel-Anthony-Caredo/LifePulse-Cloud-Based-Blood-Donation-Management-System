import 'package:flutter/material.dart';

import '../../constants.dart';
import '../../responsive.dart';
import '../dashboard/components/header.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({
    Key? key,
    required this.title,
    required this.subtitle,
    this.action,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  }) : super(key: key);

  final String title;
  final String subtitle;
  final Widget? action;
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: const EdgeInsets.all(defaultPadding),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Header(),
            const SizedBox(height: defaultPadding),
            AdminPageTitle(
              title: title,
              subtitle: subtitle,
              action: action,
            ),
            const SizedBox(height: defaultPadding),
            ...children,
          ],
        ),
      ),
    );
  }
}

class AdminPageTitle extends StatelessWidget {
  const AdminPageTitle({
    Key? key,
    required this.title,
    required this.subtitle,
    this.action,
  }) : super(key: key);

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: Responsive.isMobile(context) ? 22 : 24,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: grayColor,
          ),
        ),
      ],
    );

    if (action == null) return titleBlock;

    return Responsive(
      mobile: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          titleBlock,
          const SizedBox(height: 12),
          action!,
        ],
      ),
      desktop: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: titleBlock),
          const SizedBox(width: defaultPadding),
          action!,
        ],
      ),
    );
  }
}

class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(defaultPadding),
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

