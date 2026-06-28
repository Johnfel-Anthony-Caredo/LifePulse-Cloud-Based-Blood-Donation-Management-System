import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/menu_app_controller.dart';
import 'donor_map_screen_web.dart';

/// Main donor map screen entry point
/// Uses flutter_map with tile layers for all platforms (web, iOS, Android)
/// Features: 10 map styles, hospital markers, urgency filtering, zoom controls
class DonorMapScreen extends StatelessWidget {
  const DonorMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Wrap with provider to avoid provider errors
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MenuAppController(),
        ),
      ],
      child: const DonorMapScreenWeb(),
    );
  }
}
