import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import '../models/hospital.dart';
import 'backend_config.dart';
import 'local_backend_store.dart';

/// Service for Hospital CRUD operations via AWS Amplify GraphQL API
class HospitalService {
  /// Create a new hospital
  static Future<Hospital> createHospital(Hospital hospital) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final created = hospital.id.isEmpty
          ? hospital.copyWith(id: store.nextId('hospital'))
          : hospital;
      store.hospitals.add(created);
      await store.persist();
      return created;
    }

    try {
      const graphQLDocument = '''
        mutation CreateHospital(\$input: CreateHospitalInput!) {
          createHospital(input: \$input) {
            id
            name
            latitude
            longitude
            address
            phone
            email
            imageUrl
            is24Hours
            operatingHours
            urgency
            urgencyColor
            bloodInventory
            lastUpdated
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'input': hospital.toJson(),
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception('GraphQL Error: ${response.errors.first.message}');
      }

      final data = jsonDecode(response.data!)['createHospital'];
      return Hospital.fromJson(data);
    } catch (e) {
      safePrint('Error creating hospital: $e');
      rethrow;
    }
  }

  /// Update an existing hospital
  static Future<Hospital> updateHospital(Hospital hospital) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index =
          store.hospitals.indexWhere((item) => item.id == hospital.id);
      if (index == -1) throw Exception('Hospital not found');
      store.hospitals[index] = hospital;
      await store.persist();
      return hospital;
    }

    try {
      const graphQLDocument = '''
        mutation UpdateHospital(\$input: UpdateHospitalInput!) {
          updateHospital(input: \$input) {
            id
            name
            latitude
            longitude
            address
            phone
            email
            imageUrl
            is24Hours
            operatingHours
            urgency
            urgencyColor
            bloodInventory
            lastUpdated
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'input': hospital.toJson(),
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception('GraphQL Error: ${response.errors.first.message}');
      }

      final data = jsonDecode(response.data!)['updateHospital'];
      return Hospital.fromJson(data);
    } catch (e) {
      safePrint('Error updating hospital: $e');
      rethrow;
    }
  }

  /// Delete a hospital by ID
  static Future<void> deleteHospital(String hospitalId) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.hospitals.removeWhere((hospital) => hospital.id == hospitalId);
      await store.persist();
      return;
    }

    try {
      const graphQLDocument = '''
        mutation DeleteHospital(\$input: DeleteHospitalInput!) {
          deleteHospital(input: \$input) {
            id
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'input': {'id': hospitalId},
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception('GraphQL Error: ${response.errors.first.message}');
      }
    } catch (e) {
      safePrint('Error deleting hospital: $e');
      rethrow;
    }
  }

  /// List all hospitals
  static Future<List<Hospital>> listHospitals() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      return List<Hospital>.from(store.hospitals);
    }

    try {
      const graphQLDocument = '''
        query ListHospitals {
          listHospitals {
            items {
              id
              name
              latitude
              longitude
              address
              phone
              email
              imageUrl
              is24Hours
              operatingHours
              urgency
              urgencyColor
              bloodInventory
              lastUpdated
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

      if (response.errors.isNotEmpty) {
        throw Exception('GraphQL Error: ${response.errors.first.message}');
      }

      final data = jsonDecode(response.data!);
      final items = data['listHospitals']['items'] as List;

      return items.map((item) => Hospital.fromJson(item)).toList();
    } catch (e) {
      safePrint('Error listing hospitals: $e');
      rethrow;
    }
  }

  /// Get a single hospital by ID
  static Future<Hospital?> getHospital(String hospitalId) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final matches =
          store.hospitals.where((hospital) => hospital.id == hospitalId);
      return matches.isEmpty ? null : matches.first;
    }

    try {
      const graphQLDocument = '''
        query GetHospital(\$id: ID!) {
          getHospital(id: \$id) {
            id
            name
            latitude
            longitude
            address
            phone
            email
            imageUrl
            is24Hours
            operatingHours
            urgency
            urgencyColor
            bloodInventory
            lastUpdated
            createdAt
            updatedAt
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'id': hospitalId},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        throw Exception('GraphQL Error: ${response.errors.first.message}');
      }

      final data = jsonDecode(response.data!);
      final hospitalData = data['getHospital'];

      if (hospitalData == null) return null;

      return Hospital.fromJson(hospitalData);
    } catch (e) {
      safePrint('Error getting hospital: $e');
      rethrow;
    }
  }

  /// Update only the blood inventory of a hospital
  static Future<bool> updateHospitalInventory({
    required String hospitalId,
    required Map<String, int> bloodInventory,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index = store.hospitals.indexWhere((item) => item.id == hospitalId);
      if (index == -1) return false;
      store.hospitals[index] = store.hospitals[index].copyWith(
        bloodInventory: bloodInventory,
      );
      await store.persist();
      return true;
    }

    try {
      const graphQLDocument = '''
        mutation UpdateHospitalInventory(
          \$id: ID!
          \$bloodInventory: AWSJSON!
          \$lastUpdated: AWSDateTime
        ) {
          updateHospital(input: {
            id: \$id
            bloodInventory: \$bloodInventory
            lastUpdated: \$lastUpdated
          }) {
            id
            bloodInventory
            lastUpdated
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'id': hospitalId,
          'bloodInventory': jsonEncode(bloodInventory),
          'lastUpdated': TemporalDateTime.now().format(),
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        safePrint('Error updating inventory: ${response.errors}');
        return false;
      }

      return true;
    } catch (e) {
      safePrint('Error in updateHospitalInventory: $e');
      return false;
    }
  }
}
