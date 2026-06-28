import 'dart:convert';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/donation_history_model.dart';
import 'backend_config.dart';
import 'local_backend_store.dart';

class DonationHistoryService {
  /// Create a new donation history record
  static Future<DonationHistoryModel> createDonationHistory({
    required String donorId,
    required String hospitalId,
    required TemporalDate donationDate,
    required String bloodType,
    required int unitsGiven,
    String? notes,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final history = DonationHistoryModel(
        id: store.nextId('history'),
        donorId: donorId,
        hospitalId: hospitalId,
        donationDate: donationDate,
        bloodType: bloodType,
        unitsGiven: unitsGiven,
        notes: notes,
        createdAt: store.now(),
        updatedAt: store.now(),
      );
      store.donationHistory.add(history);
      await store.persist();
      return history;
    }

    try {
      final graphQLDocument = '''
        mutation CreateDonationHistory(
          \$donorId: ID!
          \$hospitalId: ID!
          \$donationDate: AWSDate!
          \$bloodType: BloodType!
          \$unitsGiven: Int!
          \$notes: String
        ) {
          createDonationHistory(input: {
            donorId: \$donorId
            hospitalId: \$hospitalId
            donationDate: \$donationDate
            bloodType: \$bloodType
            unitsGiven: \$unitsGiven
            notes: \$notes
          }) {
            id
            donorId
            hospitalId
            donationDate
            bloodType
            unitsGiven
            notes
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = {
        'donorId': donorId,
        'hospitalId': hospitalId,
        'donationDate': donationDate.format(),
        'bloodType': bloodType,
        'unitsGiven': unitsGiven,
        if (notes != null) 'notes': notes,
      };

      safePrint('Creating donation history with variables: $variables');

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      safePrint('Donation history response data: ${response.data}');
      safePrint('Donation history response errors: ${response.errors}');

      if (response.data == null || response.hasErrors) {
        final errorMsg = response.errors.map((e) => e.message).join(', ');
        safePrint('❌ Error creating donation history: $errorMsg');
        throw Exception('Failed to create donation history: $errorMsg');
      }

      final Map<String, dynamic> data = json.decode(response.data!);
      final donationHistory =
          DonationHistoryModel.fromJson(data['createDonationHistory']);
      safePrint(
          '✅ Donation history created successfully: ${donationHistory.id}');
      return donationHistory;
    } catch (e) {
      safePrint('❌ Exception in createDonationHistory: $e');
      rethrow;
    }
  }

  /// List donation history for a specific donor
  static Future<List<DonationHistoryModel>> listDonationHistoryByDonor(
      String donorId) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final histories = store.donationHistory
          .where((history) => history.donorId == donorId)
          .toList();
      histories.sort(
          (a, b) => b.donationDate.format().compareTo(a.donationDate.format()));
      return histories;
    }

    try {
      safePrint('📋 Fetching donation history for donor: $donorId');

      final graphQLDocument = '''
        query ListDonationHistoryByDonor(\$donorId: ID!) {
          listDonationHistories(filter: { donorId: { eq: \$donorId } }) {
            items {
              id
              donorId
              hospitalId
              donationDate
              bloodType
              unitsGiven
              notes
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'donorId': donorId},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      safePrint('📋 Response data: ${response.data}');
      safePrint('📋 Response errors: ${response.errors}');

      if (response.data == null || response.hasErrors) {
        safePrint('❌ Error listing donation history: ${response.errors}');
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.data!);
      final List<dynamic> items = data['listDonationHistories']['items'] ?? [];

      safePrint('✅ Found ${items.length} donation history records');

      final histories = items
          .map((item) =>
              DonationHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort by donation date descending (most recent first)
      histories.sort(
          (a, b) => b.donationDate.format().compareTo(a.donationDate.format()));

      return histories;
    } catch (e) {
      safePrint('Error in listDonationHistoryByDonor: $e');
      return [];
    }
  }

  /// List all donation history (for admin)
  static Future<List<DonationHistoryModel>> listAllDonationHistory() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final histories = List<DonationHistoryModel>.from(
        store.donationHistory,
      );
      histories.sort(
          (a, b) => b.donationDate.format().compareTo(a.donationDate.format()));
      return histories;
    }

    try {
      final graphQLDocument = '''
        query ListAllDonationHistory {
          listDonationHistories {
            items {
              id
              donorId
              hospitalId
              donationDate
              bloodType
              unitsGiven
              notes
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null || response.hasErrors) {
        safePrint('Error listing all donation history: ${response.errors}');
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.data!);
      final List<dynamic> items = data['listDonationHistories']['items'] ?? [];

      final histories = items
          .map((item) =>
              DonationHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      histories.sort(
          (a, b) => b.donationDate.format().compareTo(a.donationDate.format()));

      return histories;
    } catch (e) {
      safePrint('Error in listAllDonationHistory: $e');
      return [];
    }
  }

  /// Get donation history by hospital
  static Future<List<DonationHistoryModel>> listDonationHistoryByHospital(
      String hospitalId) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final histories = store.donationHistory
          .where((history) => history.hospitalId == hospitalId)
          .toList();
      histories.sort(
          (a, b) => b.donationDate.format().compareTo(a.donationDate.format()));
      return histories;
    }

    try {
      final graphQLDocument = '''
        query ListDonationHistoryByHospital(\$hospitalId: ID!) {
          listDonationHistories(filter: { hospitalId: { eq: \$hospitalId } }) {
            items {
              id
              donorId
              hospitalId
              donationDate
              bloodType
              unitsGiven
              notes
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'hospitalId': hospitalId},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null || response.hasErrors) {
        safePrint(
            'Error listing hospital donation history: ${response.errors}');
        return [];
      }

      final Map<String, dynamic> data = json.decode(response.data!);
      final List<dynamic> items = data['listDonationHistories']['items'] ?? [];

      final histories = items
          .map((item) =>
              DonationHistoryModel.fromJson(item as Map<String, dynamic>))
          .toList();

      histories.sort(
          (a, b) => b.donationDate.format().compareTo(a.donationDate.format()));

      return histories;
    } catch (e) {
      safePrint('Error in listDonationHistoryByHospital: $e');
      return [];
    }
  }
}
