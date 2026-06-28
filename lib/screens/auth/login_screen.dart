import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../controllers/menu_app_controller.dart';
import '../../services/auth_service.dart';
import '../main/main_screen.dart';
import '../donor/donor_app_shell.dart';
import 'components/hero_section_enhanced.dart';
import 'components/login_form_enhanced.dart';
import 'components/role_toggle.dart';
import 'components/blood_drop_loader.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  UserRole _selectedRole = UserRole.admin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _ensureSignedOut();
  }

  // Ensure no user is signed in when landing on login screen
  Future<void> _ensureSignedOut() async {
    try {
      final isSignedIn = await AuthService.isSignedIn();
      if (isSignedIn) {
        await AuthService.signOut();
        safePrint('Signed out previous session');
      }
    } catch (e) {
      safePrint('Error checking/signing out: $e');
    }
  }

  void _handleRoleChange(UserRole role) {
    setState(() {
      _selectedRole = role;
    });
  }

  void _handleLogin(String email, String password) async {
    // Show loading
    setState(() {
      _isLoading = true;
    });

    try {
      // Make sure we're signed out first
      await AuthService.signOut();

      // Sign in with Amplify
      final isSignedIn = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (!isSignedIn) {
        throw Exception('Sign in failed');
      }

      // If donor role, create donor profile on first login
      if (_selectedRole == UserRole.donor) {
        await AuthService.createDonorProfileOnFirstLogin();
      }

      if (!mounted) return;

      // Hide loading
      setState(() {
        _isLoading = false;
      });

      // Navigate based on selected role (since we don't have custom attributes yet)
      Widget destination;
      if (_selectedRole == UserRole.donor) {
        // Navigate directly to the rebuilt donor workspace
        destination = const DonorAppShell();
      } else {
        // Navigate to Admin Dashboard with Provider
        destination = MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (context) => MenuAppController(),
            ),
          ],
          child: MainScreen(),
        );
      }

      // Navigate with fade transition
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => destination,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = 0.0;
            const end = 1.0;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return FadeTransition(
              opacity: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
    } catch (e) {
      // Hide loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Determine error message
        String errorMessage = 'Login failed';
        if (e.toString().contains('UserNotConfirmedException')) {
          errorMessage = 'Please confirm your email before signing in';
        } else if (e.toString().contains('NotAuthorizedException')) {
          errorMessage = 'Incorrect email or password';
        } else if (e.toString().contains('UserNotFoundException')) {
          errorMessage = 'User not found. Please sign up first';
        } else {
          errorMessage = 'Login failed: ${e.toString()}';
        }

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = size.width < 768;

    return Scaffold(
      body: Stack(
        children: [
          // Main content
          isMobile ? _buildMobileLayout() : _buildDesktopLayout(),

          // Loading overlay
          if (_isLoading)
            const Positioned.fill(
              child: LoadingOverlay(),
            ),
        ],
      ),
    );
  }

  // Mobile layout - stacked vertically
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Compact hero section
          SizedBox(
            height: 280,
            child: const HeroSection(),
          ),
          // Login form
          LoginFormEnhanced(
            selectedRole: _selectedRole,
            onRoleChanged: _handleRoleChange,
            onLoginPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  // Desktop layout - split screen
  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side - Hero section
        Expanded(
          flex: 5,
          child: const HeroSection(),
        ),
        // Right side - Login form
        Expanded(
          flex: 5,
          child: LoginFormEnhanced(
            selectedRole: _selectedRole,
            onRoleChanged: _handleRoleChange,
            onLoginPressed: _handleLogin,
          ),
        ),
      ],
    );
  }
}
