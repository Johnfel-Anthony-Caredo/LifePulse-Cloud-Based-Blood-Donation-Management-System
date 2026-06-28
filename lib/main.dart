import 'package:admin_new/constants.dart';
import 'package:admin_new/controllers/menu_app_controller.dart';
import 'package:admin_new/screens/auth/login_screen.dart';
import 'package:admin_new/services/amplify_service.dart';
import 'package:admin_new/services/backend_config.dart';
import 'package:admin_new/services/local_backend_store.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (BackendConfig.useAwsBackend) {
    await AmplifyService.configure();
  } else {
    await LocalBackendStore.instance.ensureLoaded();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LifePulse - Blood Donation Management',
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
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    if (BackendConfig.useLocalBackend) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await Amplify.Auth.fetchAuthSession();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      safePrint('Error checking auth status: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    // Always show login screen - let user choose their role
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => MenuAppController(),
        ),
      ],
      child: const LoginScreen(),
    );
  }
}
