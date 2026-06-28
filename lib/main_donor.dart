import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants.dart';
import 'controllers/menu_app_controller.dart';
import 'screens/auth/login_screen.dart';
import 'services/local_backend_store.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalBackendStore.instance.ensureLoaded();

  // No Mapbox SDK setup needed - using flutter_map with tile API
  // Mapbox tiles use public token from constants.dart

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifePulse - Blood Donation System',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: bgColor,
        primaryColor: primaryColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.black87),
        canvasColor: cardBgColor,
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentRedColor,
          surface: cardBgColor,
        ),
      ),
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (context) => MenuAppController(),
          ),
        ],
        child: const LoginScreen(),
      ),
    );
  }
}
