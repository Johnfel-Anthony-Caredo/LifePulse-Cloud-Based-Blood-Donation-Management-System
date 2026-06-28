import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'constants.dart';
import 'screens/donor/donor_app_shell.dart';
import 'services/local_backend_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalBackendStore.instance.ensureLoaded();
  LocalBackendStore.instance.signIn(email: 'donor@lifepulse.local');

  runApp(const DonorPreviewApp());
}

class DonorPreviewApp extends StatelessWidget {
  const DonorPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dugo Donor Preview',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: bgColor,
        primaryColor: primaryColor,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme)
            .apply(bodyColor: Colors.black87),
        canvasColor: cardBgColor,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          secondary: accentRedColor,
          surface: cardBgColor,
        ),
      ),
      home: const DonorAppShell(),
    );
  }
}
