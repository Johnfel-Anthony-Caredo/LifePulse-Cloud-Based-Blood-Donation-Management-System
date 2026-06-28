import 'dart:convert';

import 'package:amplify_flutter/amplify_flutter.dart';

import '../models/donor_model.dart';
import 'backend_config.dart';
import 'local_backend_store.dart';

class AuthService {
  static final Map<String, String> _pendingDonorData = {};

  static Future<void> signUpDonor({
    required String email,
    required String password,
    required String name,
    required String bloodType,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.signIn(email: email, name: name);
      store.createOrUpdateDonorProfile(
        email: email,
        name: name,
        bloodType: bloodType,
      );
      await store.persist();
      store.signOut();
      await store.persist();
      return;
    }

    try {
      _pendingDonorData[email] = bloodType;

      await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.name: name,
          },
        ),
      );
    } on AuthException catch (e) {
      safePrint('Error signing up donor: ${e.message}');
      rethrow;
    }
  }

  static Future<DonorModel?> createDonorProfileOnFirstLogin() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final bloodType = _pendingDonorData[store.currentEmail] ?? 'O+';
      _pendingDonorData.remove(store.currentEmail);
      final donor = store.createOrUpdateDonorProfile(
        email: store.currentEmail,
        name: store.currentName,
        bloodType: bloodType,
      );
      await store.persist();
      return donor;
    }

    try {
      final user = await Amplify.Auth.getCurrentUser();
      final userId = user.userId;

      const checkQuery = '''
        query DonorByUserId(\$userId: String!) {
          donorByUserId(userId: \$userId) {
            items {
              id
              userId
            }
          }
        }
      ''';

      final checkRequest = GraphQLRequest<String>(
        document: checkQuery,
        variables: {'userId': userId},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final checkResponse =
          await Amplify.API.query(request: checkRequest).response;
      final checkData = json.decode(checkResponse.data!);
      final existingDonors = checkData['donorByUserId']['items'] as List;

      if (existingDonors.isNotEmpty) {
        return null;
      }

      final attributes = await Amplify.Auth.fetchUserAttributes();
      final name =
          attributes.firstWhere((a) => a.userAttributeKey.key == 'name').value;
      final email =
          attributes.firstWhere((a) => a.userAttributeKey.key == 'email').value;
      final bloodTypeStr = _pendingDonorData[email] ?? 'O+';
      _pendingDonorData.remove(email);

      final bloodTypeEnum =
          LocalBackendStore.instance.bloodTypeFromDisplay(bloodTypeStr);

      const createMutation = '''
        mutation CreateDonor(\$input: CreateDonorInput!) {
          createDonor(input: \$input) {
            id
            userId
            name
            email
            phone
            bloodType
            isEligible
            notificationsEnabled
            radiusKm
            createdAt
            updatedAt
          }
        }
      ''';

      final createRequest = GraphQLRequest<String>(
        document: createMutation,
        variables: {
          'input': {
            'userId': userId,
            'name': name,
            'email': email,
            'bloodType': DonorModel.bloodTypeToGraphQL(bloodTypeEnum),
            'isEligible': true,
            'notificationsEnabled': true,
            'radiusKm': 10.0,
          }
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final createResponse =
          await Amplify.API.mutate(request: createRequest).response;
      if (createResponse.hasErrors) return null;

      final data = json.decode(createResponse.data!);
      return DonorModel.fromJson(data['createDonor']);
    } catch (e) {
      safePrint('Error in createDonorProfileOnFirstLogin: $e');
      return null;
    }
  }

  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.signIn(email: email);
      await store.persist();
      return true;
    }

    try {
      final result = await Amplify.Auth.signIn(
        username: email,
        password: password,
      );
      return result.isSignedIn;
    } on AuthException catch (e) {
      safePrint('Error signing in: ${e.message}');
      rethrow;
    }
  }

  static Future<String?> getUserRole() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      return store.currentUserId == 'local-admin' ? 'admin' : 'donor';
    }

    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final roleAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'custom:role',
        orElse: () => AuthUserAttribute(
          userAttributeKey: const CognitoUserAttributeKey.custom('role'),
          value: '',
        ),
      );
      return roleAttr.value.isNotEmpty ? roleAttr.value : null;
    } catch (e) {
      safePrint('Error fetching user role: $e');
      return null;
    }
  }

  static Future<String?> getUserBloodType() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final donors =
          store.donors.where((donor) => donor.userId == store.currentUserId);
      return donors.isEmpty ? null : donors.first.bloodTypeDisplay;
    }

    try {
      final attributes = await Amplify.Auth.fetchUserAttributes();
      final bloodTypeAttr = attributes.firstWhere(
        (attr) => attr.userAttributeKey.key == 'custom:blood_type',
        orElse: () => AuthUserAttribute(
          userAttributeKey: const CognitoUserAttributeKey.custom('blood_type'),
          value: '',
        ),
      );
      return bloodTypeAttr.value.isNotEmpty ? bloodTypeAttr.value : null;
    } catch (e) {
      safePrint('Error fetching blood type: $e');
      return null;
    }
  }

  static Future<void> signOut() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.signOut();
      await store.persist();
      return;
    }

    try {
      await Amplify.Auth.signOut();
    } on AuthException catch (e) {
      safePrint('Error signing out: ${e.message}');
      rethrow;
    }
  }

  static Future<AuthUser?> getCurrentUser() async {
    if (BackendConfig.useLocalBackend) {
      return null;
    }

    try {
      return await Amplify.Auth.getCurrentUser();
    } on AuthException catch (e) {
      safePrint('Error getting current user: ${e.message}');
      return null;
    }
  }

  static Future<bool> isSignedIn() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      return store.currentUserId != 'local-admin' ||
          store.currentEmail != 'admin@lifepulse.local';
    }

    try {
      final session = await Amplify.Auth.fetchAuthSession();
      return session.isSignedIn;
    } catch (e) {
      return false;
    }
  }
}
