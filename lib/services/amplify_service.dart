import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_api/amplify_api.dart';
import '../amplifyconfiguration.dart';
import 'backend_config.dart';

class AmplifyService {
  static bool _isConfigured = false;

  static Future<void> configure() async {
    if (BackendConfig.useLocalBackend) {
      safePrint('Local backend mode enabled; skipping Amplify configuration');
      return;
    }

    if (_isConfigured) return;

    try {
      // Add Amplify plugins
      await Amplify.addPlugins([
        AmplifyAuthCognito(),
        AmplifyAPI(),
      ]);

      // Configure Amplify
      await Amplify.configure(amplifyconfig);
      
      _isConfigured = true;
      safePrint('✅ Amplify configured successfully');
    } on AmplifyAlreadyConfiguredException {
      safePrint('⚠️ Amplify was already configured');
      _isConfigured = true;
    } catch (e) {
      safePrint('❌ Error configuring Amplify: $e');
      rethrow;
    }
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      return false;
    }
  }

  // Get current user
  static Future<AuthUser?> getCurrentUser() async {
    try {
      return await Amplify.Auth.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  // Get user attributes (including custom:role)
  static Future<Map<String, String>> getUserAttributes() async {
    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      return {
        for (var attr in attributes)
          attr.userAttributeKey.key: attr.value
      };
    } catch (e) {
      safePrint('Error fetching user attributes: $e');
      return {};
    }
  }

  // Get user role (admin or donor)
  static Future<String?> getUserRole() async {
    try {
      final attributes = await getUserAttributes();
      return attributes['custom:role'];
    } catch (e) {
      return null;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      safePrint('Error signing out: $e');
    }
  }
}
