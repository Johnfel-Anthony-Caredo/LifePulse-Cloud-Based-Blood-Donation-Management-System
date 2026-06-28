import 'dart:convert';
import 'package:amplify_api/amplify_api.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/appointment_model.dart';
import '../models/hospital.dart';
import 'backend_config.dart';
import 'donor_service.dart';
import 'hospital_service.dart';
import 'local_backend_store.dart';
import 'blood_request_service.dart';
import 'donation_history_service.dart';

class AppointmentService {
  static Future<List<AppointmentModel>> listAppointments() async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final appointments = List<AppointmentModel>.from(
        store.appointments,
      );
      appointments
          .sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return appointments;
    }

    try {
      const graphQLDocument = '''
        query ListAppointments {
          listAppointments(limit: 1000) {
            items {
              id
              donorId
              hospitalId
              bloodRequestId
              appointmentDate
              bloodType
              status
              notes
              reminderSent
              confirmedAt
              completedAt
              cancelledAt
              cancellationReason
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
        throw Exception('Failed to fetch appointments');
      }

      final data = jsonDecode(response.data!);
      if (data == null || data['listAppointments'] == null) {
        return [];
      }

      final items = (data['listAppointments']['items'] ?? []) as List;

      return items
          .map(
              (item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      safePrint('Error listing appointments: $e');
      rethrow;
    }
  }

  static Future<AppointmentModel> getAppointment(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final matches =
          store.appointments.where((appointment) => appointment.id == id);
      if (matches.isEmpty) throw Exception('Appointment not found');
      return matches.first;
    }

    try {
      const graphQLDocument = '''
        query GetAppointment(\$id: ID!) {
          getAppointment(id: \$id) {
            id
            donorId
            hospitalId
            bloodRequestId
            appointmentDate
            bloodType
            status
            notes
            reminderSent
            confirmedAt
            completedAt
            cancelledAt
            cancellationReason
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
        throw Exception('Appointment not found');
      }

      final data = jsonDecode(response.data!);
      return AppointmentModel.fromJson(
          data['getAppointment'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error getting appointment: $e');
      rethrow;
    }
  }

  static Future<AppointmentModel> createAppointment({
    required String donorId,
    required String hospitalId,
    String? bloodRequestId,
    required DateTime appointmentDate,
    required String bloodType,
    String? notes,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final appointment = AppointmentModel(
        id: store.nextId('appointment'),
        donorId: donorId,
        hospitalId: hospitalId,
        bloodRequestId: bloodRequestId,
        appointmentDate: TemporalDateTime(appointmentDate),
        bloodType: store.bloodTypeFromDisplay(bloodType),
        status: AppointmentStatus.SCHEDULED,
        notes: notes,
        reminderSent: false,
        createdAt: store.now(),
        updatedAt: store.now(),
      );
      store.appointments.add(appointment);
      await store.persist();
      return appointment;
    }

    try {
      const graphQLDocument = '''
        mutation CreateAppointment(\$input: CreateAppointmentInput!) {
          createAppointment(input: \$input) {
            id
            donorId
            hospitalId
            bloodRequestId
            appointmentDate
            bloodType
            status
            notes
            reminderSent
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = {
        'input': {
          'donorId': donorId,
          'hospitalId': hospitalId,
          if (bloodRequestId != null) 'bloodRequestId': bloodRequestId,
          'appointmentDate': TemporalDateTime(appointmentDate).format(),
          'bloodType': bloodType,
          'status': 'SCHEDULED',
          'reminderSent': false,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      safePrint('Creating appointment with variables: $variables');

      final response = await Amplify.API.mutate(request: request).response;

      safePrint('Appointment response data: ${response.data}');
      safePrint('Appointment response errors: ${response.errors}');

      if (response.data == null || response.errors.isNotEmpty) {
        final errorMessages =
            response.errors.map((e) => '${e.message}').join(", ");
        safePrint('Create appointment errors: $errorMessages');
        throw Exception('Failed to create appointment: $errorMessages');
      }

      final data = jsonDecode(response.data!);
      if (data['createAppointment'] == null) {
        throw Exception('createAppointment returned null');
      }
      return AppointmentModel.fromJson(
          data['createAppointment'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error creating appointment: $e');
      rethrow;
    }
  }

  static Future<AppointmentModel> updateAppointment({
    required String id,
    DateTime? appointmentDate,
    String? status,
    String? notes,
    bool? reminderSent,
    DateTime? confirmedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? cancellationReason,
  }) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final index = store.appointments.indexWhere((item) => item.id == id);
      if (index == -1) throw Exception('Appointment not found');
      final existing = store.appointments[index];
      final updated = existing.copyWith(
        appointmentDate:
            appointmentDate != null ? TemporalDateTime(appointmentDate) : null,
        status:
            status != null ? AppointmentModel.statusFromString(status) : null,
        notes: notes,
        reminderSent: reminderSent,
        confirmedAt: confirmedAt != null ? TemporalDateTime(confirmedAt) : null,
        completedAt: completedAt != null ? TemporalDateTime(completedAt) : null,
        cancelledAt: cancelledAt != null ? TemporalDateTime(cancelledAt) : null,
        cancellationReason: cancellationReason,
        updatedAt: store.now(),
      );
      store.appointments[index] = updated;
      await store.persist();
      return updated;
    }

    try {
      const graphQLDocument = '''
        mutation UpdateAppointment(\$input: UpdateAppointmentInput!) {
          updateAppointment(input: \$input) {
            id
            donorId
            hospitalId
            bloodRequestId
            appointmentDate
            bloodType
            status
            notes
            reminderSent
            confirmedAt
            completedAt
            cancelledAt
            cancellationReason
            createdAt
            updatedAt
          }
        }
      ''';

      final variables = {
        'input': {
          'id': id,
          if (appointmentDate != null)
            'appointmentDate': TemporalDateTime(appointmentDate).format(),
          if (status != null) 'status': status,
          if (notes != null) 'notes': notes,
          if (reminderSent != null) 'reminderSent': reminderSent,
          if (confirmedAt != null)
            'confirmedAt': TemporalDateTime(confirmedAt).format(),
          if (completedAt != null)
            'completedAt': TemporalDateTime(completedAt).format(),
          if (cancelledAt != null)
            'cancelledAt': TemporalDateTime(cancelledAt).format(),
          if (cancellationReason != null)
            'cancellationReason': cancellationReason,
        }
      };

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: variables,
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null) {
        throw Exception('Failed to update appointment');
      }

      final data = jsonDecode(response.data!);
      return AppointmentModel.fromJson(
          data['updateAppointment'] as Map<String, dynamic>);
    } catch (e) {
      safePrint('Error updating appointment: $e');
      rethrow;
    }
  }

  static Future<void> deleteAppointment(String id) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      store.appointments.removeWhere((appointment) => appointment.id == id);
      await store.persist();
      return;
    }

    try {
      const graphQLDocument = '''
        mutation DeleteAppointment(\$input: DeleteAppointmentInput!) {
          deleteAppointment(input: \$input) {
            id
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'input': {'id': id}
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.data == null) {
        throw Exception('Failed to delete appointment');
      }
    } catch (e) {
      safePrint('Error deleting appointment: $e');
      rethrow;
    }
  }

  static Future<AppointmentModel> cancelAppointment({
    required String id,
    String cancellationReason = 'Cancelled by user',
  }) {
    return updateAppointment(
      id: id,
      status: 'CANCELLED',
      cancelledAt: DateTime.now(),
      cancellationReason: cancellationReason,
    );
  }

  static Future<AppointmentModel> confirmAppointment(String id) {
    return updateAppointment(
      id: id,
      status: 'CONFIRMED',
      confirmedAt: DateTime.now(),
    );
  }

  static Future<AppointmentModel> rescheduleAppointment({
    required String id,
    required DateTime appointmentDate,
    String? notes,
  }) {
    return updateAppointment(
      id: id,
      appointmentDate: appointmentDate,
      notes: notes,
    );
  }

  static Future<List<AppointmentModel>> listAppointmentsByDonor(
      String donorId) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final appointments = store.appointments
          .where((appointment) => appointment.donorId == donorId)
          .toList();
      appointments
          .sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return appointments;
    }

    try {
      const graphQLDocument = '''
        query ListAppointments(\$filter: ModelAppointmentFilterInput, \$limit: Int) {
          listAppointments(filter: \$filter, limit: \$limit) {
            items {
              id
              donorId
              hospitalId
              bloodRequestId
              appointmentDate
              bloodType
              status
              notes
              reminderSent
              confirmedAt
              completedAt
              cancelledAt
              cancellationReason
              createdAt
              updatedAt
            }
          }
        }
      ''';

      final request = GraphQLRequest<String>(
        document: graphQLDocument,
        variables: {
          'filter': {
            'donorId': {
              'eq': donorId,
            },
          },
          'limit': 1000,
        },
        authorizationMode: APIAuthorizationType.userPools,
      );

      safePrint('Querying appointments for donorId: $donorId');

      final response = await Amplify.API.query(request: request).response;

      safePrint('Response data: ${response.data}');
      safePrint('Response errors: ${response.errors}');

      if (response.data == null) {
        if (response.errors.isNotEmpty) {
          final errorMessages =
              response.errors.map((e) => e.message).join(', ');
          throw Exception('GraphQL errors: $errorMessages');
        }
        throw Exception('Failed to fetch appointments');
      }

      final data = jsonDecode(response.data!);
      if (data == null || data['listAppointments'] == null) {
        safePrint('No listAppointments data in response');
        return [];
      }

      final items = (data['listAppointments']['items'] ?? []) as List;
      safePrint('Found ${items.length} appointments for donor');

      final appointments = items
          .map(
              (item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();

      // Sort by appointment date DESC
      appointments
          .sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));

      return appointments;
    } catch (e) {
      safePrint('Error listing appointments by donor: $e');
      rethrow;
    }
  }

  static Future<List<AppointmentModel>> listAppointmentsByHospital(
      String hospitalId) async {
    if (BackendConfig.useLocalBackend) {
      final store = LocalBackendStore.instance;
      await store.ensureLoaded();
      final appointments = store.appointments
          .where((appointment) => appointment.hospitalId == hospitalId)
          .toList();
      appointments
          .sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
      return appointments;
    }

    try {
      const graphQLDocument = '''
        query AppointmentsByHospital(\$hospitalId: ID!) {
          appointmentsByHospital(hospitalId: \$hospitalId, limit: 1000) {
            items {
              id
              donorId
              hospitalId
              bloodRequestId
              appointmentDate
              bloodType
              status
              notes
              reminderSent
              confirmedAt
              completedAt
              cancelledAt
              cancellationReason
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
        throw Exception('Failed to fetch appointments');
      }

      final data = jsonDecode(response.data!);
      final items = data['appointmentsByHospital']['items'] as List;

      return items
          .map(
              (item) => AppointmentModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      safePrint('Error listing appointments by hospital: $e');
      rethrow;
    }
  }

  /// Complete an appointment and handle all related updates
  static Future<bool> completeAppointment({
    required String appointmentId,
    required String donorId,
    required String hospitalId,
    required String bloodType,
    required TemporalDateTime appointmentDate,
    String? bloodRequestId,
    int unitsGiven = 1,
    String? notes,
  }) async {
    try {
      // 1. Update appointment status to COMPLETED
      final now = DateTime.now();
      final appointment = await updateAppointment(
        id: appointmentId,
        status: 'COMPLETED',
        completedAt: now,
      );

      if (appointment == null) {
        safePrint('Failed to update appointment status');
        return false;
      }

      safePrint('✅ Step 1: Appointment status updated to COMPLETED');

      // 2. Update donor: set lastDonation and isEligible = false
      final donorUpdateSuccess = await DonorService.updateDonorEligibility(
        id: donorId,
        isEligible: false,
        lastDonation:
            TemporalDate.fromString(appointmentDate.format().split('T')[0]),
      );

      if (!donorUpdateSuccess) {
        safePrint('⚠️ Step 2: Failed to update donor eligibility');
        // Continue anyway, don't fail the whole operation
      } else {
        safePrint('✅ Step 2: Donor eligibility updated');
      }

      // 3. Create donation history record
      safePrint(
          '📝 Step 3: Creating donation history: donorId=$donorId, hospitalId=$hospitalId, bloodType=$bloodType, units=$unitsGiven');
      try {
        final donationHistory =
            await DonationHistoryService.createDonationHistory(
          donorId: donorId,
          hospitalId: hospitalId,
          donationDate:
              TemporalDate.fromString(appointmentDate.format().split('T')[0]),
          bloodType: bloodType,
          unitsGiven: unitsGiven,
          notes: notes,
        );
        safePrint(
            '✅ Step 3: Donation history created with ID: ${donationHistory?.id ?? "unknown"}');
      } catch (e) {
        safePrint('❌ Step 3: Failed to create donation history: $e');
        // Don't fail the whole operation, but log it
      }

      // 4. Update hospital blood inventory
      try {
        final hospital = await HospitalService.getHospital(hospitalId);
        if (hospital != null) {
          final inventory = Map<String, int>.from(hospital.bloodInventory);
          final currentUnits = inventory[bloodType] ?? 0;
          inventory[bloodType] = currentUnits + unitsGiven;

          await HospitalService.updateHospitalInventory(
            hospitalId: hospitalId,
            bloodInventory: inventory,
          );
          safePrint(
              '✅ Step 4: Hospital inventory updated: $bloodType $currentUnits → ${currentUnits + unitsGiven}');
        } else {
          safePrint('⚠️ Step 4: Hospital not found');
        }
      } catch (e) {
        safePrint('⚠️ Step 4: Failed to update hospital inventory: $e');
        // Continue anyway
      }

      // 5. If there's a blood request, mark it as fulfilled
      if (bloodRequestId != null && bloodRequestId.isNotEmpty) {
        try {
          await BloodRequestService.updateBloodRequest(
            id: bloodRequestId,
            status: 'FULFILLED',
            fulfilledAt: now,
          );
          safePrint('✅ Step 5: Blood request marked as FULFILLED');
        } catch (e) {
          safePrint('⚠️ Step 5: Failed to update blood request: $e');
          // Continue anyway
        }
      } else {
        safePrint('➖ Step 5: No blood request linked, skipped');
      }

      safePrint('🎉 Successfully completed appointment with all updates');
      return true;
    } catch (e) {
      safePrint('Error in completeAppointment: $e');
      return false;
    }
  }
}
