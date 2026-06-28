import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/blood_request_model.dart';
import 'backend_config.dart';
import 'local_backend_store.dart';

class BloodRequestService {
  static Future<List<BloodRequestModel>> listBloodRequests() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final requests = List<BloodRequestModel>.from(
        store.bloodRequests,
      );
      requests.sort((a, b) {
        if (a.createdAt == null || b.createdAt == null) return 0;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return requests;
    }

    try {
      const graphQLDocument = '''
        query ListBloodRequests {
          listBloodRequests(limit: 1000) {
            items {
              id
              hospitalId
              bloodType
              unitsNeeded
              urgency
              patientName
              contactPerson
              contactPhone
              status
              notes
              expiresAt
              fulfilledAt
              createdBy
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {},
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null) {
        throw Exception('Failed to fetch blood requests');
      }

      final data = jsonDecode(response.data!);
      if (data == null || data['listBloodRequests'] == null) {
        return [];
      }

      final items = (data['listBloodRequests']['items'] ?? []) as List;

      return items
          .map((item) =>
              BloodRequestModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      safePrint('Error listing blood requests: $e');
      rethrow;
    }
  }

  static Future<BloodRequestModel> getBloodRequest(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final matches = store.bloodRequests.where((request) => request.id == id);
      if (matches.isEmpty) throw Exception('Blood request not found');
      return matches.first;
    }

    try {
      const graphQLDocument = '''
        query GetBloodRequest(\$id: ID!) {
          getBloodRequest(id: \$id) {
            id
            hospitalId
            bloodType
            unitsNeeded
            urgency
            patientName
            contactPerson
            contactPhone
            status
            notes
            expiresAt
            fulfilledAt
            createdBy
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

      if (response.data == null) {
        throw Exception('Blood request not found');
      }

      final data = jsonDecode(response.data!);
      return BloodRequestModel.fromJson(
          data['getBloodRequest'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error getting blood request: $e');
      rethrow;
    }
  }

  static Future<BloodRequestModel> createBloodRequest({
    required String hospitalId,
    required String bloodType,
    required int unitsNeeded,
    required String urgency,
    required String patientName,
    String? contactPerson,
    String? contactPhone,
    String? notes,
    DateTime? expiresAt,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final request = BloodRequestModel(
        id: store.nextId('request'),
        hospitalId: hospitalId,
        bloodType: store.bloodTypeFromDisplay(bloodType),
        unitsNeeded: unitsNeeded,
        urgency: BloodRequestModel.urgencyFromString(urgency),
        patientName: patientName,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        status: RequestStatus.PENDING,
        notes: notes,
        expiresAt: expiresAt != null ? TemporalDateTime(expiresAt) : null,
        createdBy: store.currentUserId,
        createdAt: store.now(),
        updatedAt: store.now(),
      );
      store.bloodRequests.add(request);
      await store.persist();
      return request;
    }

    try {
      const graphQLDocument = '''
        mutation CreateBloodRequest(\$input: CreateBloodRequestInput!) {
          createBloodRequest(input: \$input) {
            id
            hospitalId
            bloodType
            unitsNeeded
            urgency
            patientName
            contactPerson
            contactPhone
            status
            notes
            expiresAt
            createdBy
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = {
        'input': {
          'hospitalId': hospitalId.toString(),
          'bloodType': bloodType,
          'unitsNeeded': unitsNeeded,
          'urgency': urgency,
          'patientName': patientName,
          if (contactPerson != null && contactPerson.isNotEmpty)
            'contactPerson': contactPerson,
          if (contactPhone != null && contactPhone.isNotEmpty)
            'contactPhone': contactPhone,
          'status': 'PENDING',
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          if (expiresAt != null)
            'expiresAt': TemporalDateTime(expiresAt).format(),
        }
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      safePrint('Creating blood request with variables: $variables');

      final response = await Amplify.API.mutate(request: request).response;

      safePrint('Response data: ${response.data}');
      safePrint('Response errors: ${response.errors}');

      if (response.data == null || response.errors.isNotEmpty) {
        final errorMessages = response.errors
            .map((e) => '${e.message} (${e.extensions})')
            .join(", ");
        safePrint('Create blood request errors: $errorMessages');
        throw Exception('Failed to create blood request: $errorMessages');
      }

      final data = jsonDecode(response.data!);
      if (data['createBloodRequest'] == null) {
        throw Exception('createBloodRequest returned null');
      }
      return BloodRequestModel.fromJson(
          data['createBloodRequest'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error creating blood request: $e');
      rethrow;
    }
  }

  static Future<BloodRequestModel> updateBloodRequest({
    required String id,
    int? unitsNeeded,
    String? urgency,
    String? patientName,
    String? contactPerson,
    String? contactPhone,
    String? status,
    String? notes,
    DateTime? expiresAt,
    DateTime? fulfilledAt,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index =
          store.bloodRequests.indexWhere((request) => request.id == id);
      if (index == -1) throw Exception('Blood request not found');
      final existing = store.bloodRequests[index];
      final updated = existing.copyWith(
        unitsNeeded: unitsNeeded,
        urgency: urgency != null
            ? BloodRequestModel.urgencyFromString(urgency)
            : null,
        patientName: patientName,
        contactPerson: contactPerson,
        contactPhone: contactPhone,
        status:
            status != null ? BloodRequestModel.statusFromString(status) : null,
        notes: notes,
        expiresAt: expiresAt != null ? TemporalDateTime(expiresAt) : null,
        fulfilledAt: fulfilledAt != null ? TemporalDateTime(fulfilledAt) : null,
        updatedAt: store.now(),
      );
      store.bloodRequests[index] = updated;
      await store.persist();
      return updated;
    }

    try {
      const graphQLDocument = '''
        mutation UpdateBloodRequest(\$input: UpdateBloodRequestInput!) {
          updateBloodRequest(input: \$input) {
            id
            hospitalId
            bloodType
            unitsNeeded
            urgency
            patientName
            contactPerson
            contactPhone
            status
            notes
            expiresAt
            fulfilledAt
            createdBy
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = {
        'input': {
          'id': id,
          if (unitsNeeded != null) 'unitsNeeded': unitsNeeded,
          if (urgency != null) 'urgency': urgency,
          if (patientName != null) 'patientName': patientName,
          if (contactPerson != null) 'contactPerson': contactPerson,
          if (contactPhone != null) 'contactPhone': contactPhone,
          if (status != null) 'status': status,
          if (notes != null) 'notes': notes,
          if (expiresAt != null)
            'expiresAt': TemporalDateTime(expiresAt).format(),
          if (fulfilledAt != null)
            'fulfilledAt': TemporalDateTime(fulfilledAt).format(),
        }
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null) {
        throw Exception('Failed to update blood request');
      }

      final data = jsonDecode(response.data!);
      return BloodRequestModel.fromJson(
          data['updateBloodRequest'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error updating blood request: $e');
      rethrow;
    }
  }

  static Future<void> deleteBloodRequest(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.bloodRequests.removeWhere((request) => request.id == id);
      await store.persist();
      return;
    }

    try {
      const graphQLDocument = '''
        mutation DeleteBloodRequest(\$input: DeleteBloodRequestInput!) {
          deleteBloodRequest(input: \$input) {
            id
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'input': {'id': id}
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null) {
        throw Exception('Failed to delete blood request');
      }
    } catch (e) {
      safePrint('Error deleting blood request: $e');
      rethrow;
    }
  }

  static Future<BloodRequestModel> fulfillBloodRequest(String id) {
    return updateBloodRequest(
      id: id,
      status: 'FULFILLED',
      fulfilledAt: DateTime.now(),
    );
  }

  static Future<BloodRequestModel> cancelBloodRequest(String id) {
    return updateBloodRequest(
      id: id,
      status: 'CANCELLED',
    );
  }

  static Future<List<BloodRequestModel>> listBloodRequestsByHospital(
      String hospitalId) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      return store.bloodRequests
          .where((request) => request.hospitalId == hospitalId)
          .toList();
    }

    try {
      const graphQLDocument = '''
        query BloodRequestsByHospital(\$hospitalId: ID!) {
          bloodRequestsByHospital(hospitalId: \$hospitalId, limit: 1000) {
            items {
              id
              hospitalId
              bloodType
              unitsNeeded
              urgency
              patientName
              contactPerson
              contactPhone
              status
              notes
              expiresAt
              fulfilledAt
              createdBy
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {'hospitalId': hospitalId},
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.data == null) {
        throw Exception('Failed to fetch blood requests');
      }

      final data = jsonDecode(response.data!);
      if (data == null || data['bloodRequestsByHospital'] == null) {
        return [];
      }

      final items = (data['bloodRequestsByHospital']['items'] ?? []) as List;

      return items
          .map((item) =>
              BloodRequestModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      safePrint('Error listing blood requests by hospital: $e');
      rethrow;
    }
  }
}
