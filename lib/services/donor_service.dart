import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/donor_model.dart';
import 'backend_config.dart';
import 'local_backend_store.dart';

class DonorService {
  /// Get current logged-in donor profile
  static Future<DonorModel?> getCurrentDonor() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final matches =
          store.donors.where((donor) => donor.userId == store.currentUserId);
      return matches.isEmpty ? null : matches.first;
    }

    try {
      safePrint('👤 Fetching current donor profile...');

      // Get current user's userId
      final user = await Amplify.Auth.getCurrentUser();
      final userId = user.userId;

      safePrint('🔑 Current userId: $userId');

      const graphQLDocument = '''
        query DonorByUserId(\$userId: String!) {
          donorByUserId(userId: \$userId) {
            items {
              id
              userId
              name
              email
              phone
              bloodType
              lastDonation
              isEligible
              notificationsEnabled
              radiusKm
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'userId': userId},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null || response.hasErrors) {
        safePrint('❌ Failed to load donor: ${response.errors}');
        return null;
      }

      final Map<String, dynamic> data = json.decode(response.data!);
      final List<dynamic> items = data['donorByUserId']['items'];

      if (items.isEmpty) {
        safePrint('⚠️ No donor profile found for userId: $userId');
        return null;
      }

      final donor = DonorModel.fromJson(items.first);
      safePrint('✅ Donor profile loaded: ${donor.name}');

      return donor;
    } catch (e) {
      safePrint('🚨 Error in getCurrentDonor: $e');
      return null;
    }
  }

  /// List all donors (Admin access)
  static Future<List<DonorModel>> listDonors() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      return List<DonorModel>.from(store.donors);
    }

    try {
      safePrint('📋 Fetching donors list...');

      const graphQLDocument = '''
        query ListDonors {
          listDonors {
            items {
              id
              userId
              name
              email
              phone
              bloodType
              lastDonation
              isEligible
              notificationsEnabled
              radiusKm
              createdAt
              updatedAt
            }
          }
        }
      ''';

      // Use userPools auth - Admins group has read access
      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      safePrint(
          '📦 Response received: ${response.data != null ? "Has data" : "No data"}');
      safePrint('❌ Has errors: ${response.hasErrors}');

      if (response.hasErrors) {
        safePrint('🔴 Errors: ${response.errors}');
      }

      if (response.data == null || response.hasErrors) {
        throw Exception('Failed to load donors: ${response.errors}');
      }

      final jsonResponse = response.data!;
      safePrint('📄 Raw JSON: $jsonResponse');

      final Map<String, dynamic> data = json.decode(jsonResponse);
      final List<dynamic> items = data['listDonors']['items'];

      safePrint('✅ Found ${items.length} donors');

      final donors = items.map((item) => DonorModel.fromJson(item)).toList();

      return donors;
    } catch (e) {
      safePrint('🚨 Error in listDonors: $e');
      rethrow;
    }
  }

  /// Create a new donor (creates Cognito user + Donor record)
  static Future<DonorModel> createDonor({
    required String name,
    required String email,
    required String password,
    required String phone,
    required BloodType bloodType,
    double radiusKm = 10.0,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final donor = DonorModel(
        id: store.nextId('donor'),
        userId: 'local-user-${email.hashCode.abs()}',
        name: name,
        email: email,
        phone: phone,
        bloodType: bloodType,
        isEligible: true,
        notificationsEnabled: true,
        radiusKm: radiusKm,
        createdAt: store.now(),
        updatedAt: store.now(),
      );
      store.donors.add(donor);
      await store.persist();
      return donor;
    }

    try {
      safePrint('🆕 Creating donor account for $email...');

      // Step 1: Create Cognito user
      final signUpResult = await Amplify.Auth.signUp(
        username: email,
        password: password,
        options: SignUpOptions(
          userAttributes: {
            AuthUserAttributeKey.email: email,
            AuthUserAttributeKey.name: name,
            AuthUserAttributeKey.phoneNumber: phone,
          },
        ),
      );

      final userId = signUpResult.userId;
      safePrint('✅ Cognito user created: $userId');

      // Step 2: Create Donor record in database
      final graphQLDocument = '''
        mutation CreateDonor(\$input: CreateDonorInput!) {
          createDonor(input: \$input) {
            id
            userId
            name
            email
            phone
            bloodType
            lastDonation
            isEligible
            notificationsEnabled
            radiusKm
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'input': {
            'userId': userId,
            'name': name,
            'email': email,
            'phone': phone,
            'bloodType': bloodTypeToGraphQL(bloodType),
            'isEligible': true,
            'notificationsEnabled': true,
            'radiusKm': radiusKm,
          }
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null || response.hasErrors) {
        safePrint('🔴 Error creating donor record: ${response.errors}');
        throw Exception('Failed to create donor record: ${response.errors}');
      }

      final Map<String, dynamic> data = json.decode(response.data!);
      final donor = DonorModel.fromJson(data['createDonor']);

      safePrint('✅ Donor record created: ${donor.id}');
      return donor;
    } catch (e) {
      safePrint('🚨 Error in createDonor: $e');
      rethrow;
    }
  }

  /// Get a single donor by ID
  static Future<DonorModel?> getDonor(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final matches = store.donors.where((donor) => donor.id == id);
      return matches.isEmpty ? null : matches.first;
    }

    try {
      final graphQLDocument = '''
        query GetDonor(\$id: ID!) {
          getDonor(id: \$id) {
            id
            userId
            name
            email
            phone
            bloodType
            lastDonation
            isEligible
            notificationsEnabled
            radiusKm
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'id': id},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.hasErrors) {
        safePrint('Error getting donor: ${response.errors}');
        throw Exception('Failed to get donor: ${response.errors}');
      }

      if (response.data == null) return null;

      final Map<String, dynamic> data = json.decode(response.data!);

      if (data['getDonor'] == null) return null;

      return DonorModel.fromJson(data['getDonor']);
    } catch (e) {
      safePrint('Error in getDonor: $e');
      throw Exception('Failed to get donor: $e');
    }
  }

  /// Update donor (Admin can update eligibility, etc.)
  static Future<DonorModel> updateDonor(DonorModel donor) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index = store.donors.indexWhere((item) => item.id == donor.id);
      if (index == -1) throw Exception('Donor not found');
      store.donors[index] = donor;
      await store.persist();
      return donor;
    }

    try {
      final graphQLDocument = '''
        mutation UpdateDonor(
          \$id: ID!
          \$isEligible: Boolean!
          \$notificationsEnabled: Boolean!
          \$lastDonation: AWSDate
        ) {
          updateDonor(input: {
            id: \$id
            isEligible: \$isEligible
            notificationsEnabled: \$notificationsEnabled
            lastDonation: \$lastDonation
          }) {
            id
            userId
            name
            email
            phone
            bloodType
            lastDonation
            isEligible
            notificationsEnabled
            radiusKm
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'id': donor.id,
          'isEligible': donor.isEligible,
          'notificationsEnabled': donor.notificationsEnabled,
          if (donor.lastDonation != null)
            'lastDonation': donor.lastDonation!.format(),
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null || response.hasErrors) {
        safePrint('Error updating donor: ${response.errors}');
        throw Exception('Failed to update donor: ${response.errors}');
      }

      final Map<String, dynamic> data = json.decode(response.data!);

      return DonorModel.fromJson(data['updateDonor']);
    } catch (e) {
      safePrint('Error in updateDonor: $e');
      throw Exception('Failed to update donor: $e');
    }
  }

  /// Update donor eligibility after donation
  static Future<bool> updateDonorEligibility({
    required String id,
    required bool isEligible,
    required TemporalDate lastDonation,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index = store.donors.indexWhere((donor) => donor.id == id);
      if (index == -1) return false;
      store.donors[index] = store.donors[index].copyWith(
        isEligible: isEligible,
        lastDonation: lastDonation,
      );
      await store.persist();
      return true;
    }

    try {
      final graphQLDocument = '''
        mutation UpdateDonorEligibility(
          \$id: ID!
          \$isEligible: Boolean!
          \$lastDonation: AWSDate!
        ) {
          updateDonor(input: {
            id: \$id
            isEligible: \$isEligible
            lastDonation: \$lastDonation
          }) {
            id
            isEligible
            lastDonation
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'id': id,
          'isEligible': isEligible,
          'lastDonation': lastDonation.format(),
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null || response.hasErrors) {
        safePrint('Error updating donor eligibility: ${response.errors}');
        return false;
      }

      return true;
    } catch (e) {
      safePrint('Error in updateDonorEligibility: $e');
      return false;
    }
  }

  /// Update donor profile (for donor self-service)
  static Future<bool> updateDonorProfile({
    required String id,
    required String name,
    required String email,
    String? phone,
    required String bloodType,
    required bool notificationsEnabled,
    required double radiusKm,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index = store.donors.indexWhere((donor) => donor.id == id);
      if (index == -1) return false;
      store.donors[index] = store.donors[index].copyWith(
        name: name,
        email: email,
        phone: phone,
        bloodType: store.bloodTypeFromDisplay(bloodType),
        notificationsEnabled: notificationsEnabled,
        radiusKm: radiusKm,
      );
      await store.persist();
      return true;
    }

    try {
      final graphQLDocument = '''
        mutation UpdateDonorProfile(
          \$id: ID!
          \$name: String!
          \$email: AWSEmail!
          \$phone: String
          \$bloodType: BloodType!
          \$notificationsEnabled: Boolean!
          \$radiusKm: Float!
        ) {
          updateDonor(input: {
            id: \$id
            name: \$name
            email: \$email
            phone: \$phone
            bloodType: \$bloodType
            notificationsEnabled: \$notificationsEnabled
            radiusKm: \$radiusKm
          }) {
            id
            name
            email
            phone
            bloodType
            notificationsEnabled
            radiusKm
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'id': id,
          'name': name,
          'email': email,
          'phone': phone,
          'bloodType': bloodType,
          'notificationsEnabled': notificationsEnabled,
          'radiusKm': radiusKm,
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null || response.hasErrors) {
        safePrint('Error updating donor profile: ${response.errors}');
        return false;
      }

      return true;
    } catch (e) {
      safePrint('Error in updateDonorProfile: $e');
      return false;
    }
  }

  static Future<bool> updateCurrentDonorPreferences({
    bool? notificationsEnabled,
    double? radiusKm,
  }) async {
    final donor = await getCurrentDonor();
    if (donor == null) return false;

    return updateDonorProfile(
      id: donor.id,
      name: donor.name,
      email: donor.email,
      phone: donor.phone,
      bloodType: DonorModel.bloodTypeToGraphQL(donor.bloodType),
      notificationsEnabled: notificationsEnabled ?? donor.notificationsEnabled,
      radiusKm: radiusKm ?? donor.radiusKm ?? 10,
    );
  }

  /// Delete donor (Admin only)
  static Future<void> deleteDonor(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.donors.removeWhere((donor) => donor.id == id);
      await store.persist();
      return;
    }

    try {
      const graphQLDocument = '''
        mutation DeleteDonor(\$id: ID!) {
          deleteDonor(input: { id: \$id }) {
            id
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'id': id},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.hasErrors) {
        safePrint('Error deleting donor: ${response.errors}');
        throw Exception('Failed to delete donor: ${response.errors}');
      }
    } catch (e) {
      safePrint('Error in deleteDonor: $e');
      throw Exception('Failed to delete donor: $e');
    }
  }

  /// Search donors by blood type
  static Future<List<DonorModel>> searchByBloodType(BloodType bloodType) async {
    try {
      final donors = await listDonors();
      return donors.where((d) => d.bloodType == bloodType).toList();
    } catch (e) {
      safePrint('Error searching donors by blood type: $e');
      throw Exception('Failed to search donors: $e');
    }
  }

  /// Get eligible donors
  static Future<List<DonorModel>> getEligibleDonors() async {
    try {
      final donors = await listDonors();
      return donors.where((d) => d.isEligible).toList();
    } catch (e) {
      safePrint('Error getting eligible donors: $e');
      throw Exception('Failed to get eligible donors: $e');
    }
  }

  /// Convert BloodType enum to GraphQL string
  static String bloodTypeToGraphQL(BloodType type) {
    return type.toString().split('.').last;
  }
}
