import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../constants.dart';
import '../../models/appointment_model.dart';
import '../../models/donation_history_model.dart';
import '../../models/donor_model.dart';
import '../../models/hospital.dart';
import '../../models/notification_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import '../../services/donation_history_service.dart';
import '../../services/donor_service.dart';
import '../../services/hospital_service.dart';
import '../../services/notification_service.dart';
import '../auth/login_screen.dart';
import 'book_appointment_screen.dart';

enum DonorMapStyle {
  satellite,
  mapbox3D,
  mapboxOutdoors,
  mapboxSatellite,
  light,
  dark,
  standard,
  terrain,
}

const _donorInk = Color(0xFF22050B);
const _donorDeepRed = Color(0xFF7A001D);
const _donorCrimson = Color(0xFFE11D48);
const _donorRose = Color(0xFFFFEEF1);
const _donorSurface = Color(0xFFFFFBFB);
const _donorBorder = Color(0xFFFFCED8);
const _donorMuted = Color(0xFF754352);
const _donorBlue = Color(0xFF2563EB);

class DonorAppShell extends StatefulWidget {
  const DonorAppShell({super.key});

  @override
  State<DonorAppShell> createState() => _DonorAppShellState();
}

class _DonorAppShellState extends State<DonorAppShell> {
  final MapController _mapController = MapController();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _timeFormat = DateFormat('h:mm a');

  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _showUnreadOnly = false;
  String? _errorMessage;

  DonorModel? _donor;
  List<Hospital> _hospitals = [];
  List<AppointmentModel> _appointments = [];
  List<NotificationModel> _notifications = [];
  List<DonationHistoryModel> _history = [];

  DonorMapStyle _mapStyle = DonorMapStyle.satellite;
  HospitalUrgency? _urgencyFilter;
  String? _bloodTypeFilter;
  Hospital? _selectedHospital;

  static const List<_DonorDestination> _destinations = [
    _DonorDestination('Home', Icons.home_rounded),
    _DonorDestination('Map', Icons.map_rounded),
    _DonorDestination(
      'Appointments',
      Icons.event_available_rounded,
      shortLabel: 'Appts',
    ),
    _DonorDestination('Inbox', Icons.notifications_rounded),
    _DonorDestination('Profile', Icons.person_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _loadDonorApp();
  }

  Future<void> _loadDonorApp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final donor = await DonorService.getCurrentDonor();
      final hospitals = await HospitalService.listHospitals();
      final appointments = donor == null
          ? <AppointmentModel>[]
          : await AppointmentService.listAppointmentsByDonor(donor.id);
      final notifications = await NotificationService.listMyNotifications();
      final history = donor == null
          ? <DonationHistoryModel>[]
          : await DonationHistoryService.listDonationHistoryByDonor(donor.id);

      if (!mounted) return;
      setState(() {
        _donor = donor;
        _hospitals = hospitals;
        _appointments = appointments;
        _notifications = notifications;
        _history = history;
        _bloodTypeFilter = null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'We could not load your donor workspace yet.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 900;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: _donorRose,
        colorScheme: const ColorScheme.light(
          primary: primaryColor,
          onPrimary: Colors.white,
          secondary: tealAccent,
          surface: Colors.white,
          onSurface: _donorInk,
          error: primaryColor,
        ),
        textTheme: Theme.of(context).textTheme.apply(
              bodyColor: _donorInk,
              displayColor: _donorInk,
            ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: _donorBorder),
          ),
        ),
        chipTheme: Theme.of(context).chipTheme.copyWith(
              selectedColor: primaryColor,
              backgroundColor: Colors.white,
              side: const BorderSide(color: _donorBorder),
              labelStyle: const TextStyle(fontWeight: FontWeight.w800),
            ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _donorBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _donorBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: primaryColor, width: 1.5),
          ),
          labelStyle: const TextStyle(color: _donorMuted),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryColor,
            side: const BorderSide(color: _donorBorder),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF6F7),
                Color(0xFFFFECEF),
                Color(0xFFFFFDFD),
              ],
            ),
          ),
          child: SafeArea(
            top: _selectedIndex != 1,
            bottom: false,
            child: isWide ? _buildWideShell() : _buildMobileShell(),
          ),
        ),
        bottomNavigationBar: isWide ? null : _buildBottomTabs(),
      ),
    );
  }

  Widget _buildWideShell() {
    return Row(
      children: [
        _buildSideNavigation(),
        Expanded(
          child: Column(
            children: [
              if (_selectedIndex != 1)
                _DonorTopBar(
                  title: _destinations[_selectedIndex].label,
                  subtitle: _topBarSubtitle,
                  donor: _donor,
                  unreadCount: _unreadNotifications.length,
                  onInbox: () => setState(() => _selectedIndex = 3),
                  onRefresh: _loadDonorApp,
                  onLogout: _logout,
                ),
              Expanded(child: _buildCurrentSection()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileShell() {
    return Column(
      children: [
        if (_selectedIndex != 1)
          _DonorTopBar(
            title: _destinations[_selectedIndex].label,
            subtitle: _topBarSubtitle,
            donor: _donor,
            unreadCount: _unreadNotifications.length,
            onInbox: () => setState(() => _selectedIndex = 3),
            onRefresh: _loadDonorApp,
            onLogout: _logout,
            compact: true,
          ),
        Expanded(child: _buildCurrentSection()),
      ],
    );
  }

  Widget _buildSideNavigation() {
    return Container(
      width: 244,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_donorDeepRed, Color(0xFF4D0012)],
        ),
        border: Border(right: BorderSide(color: Color(0x33FFFFFF))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bloodtype_rounded, color: primaryColor),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Dugo Donor',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          ...List.generate(_destinations.length, (index) {
            final destination = _destinations[index];
            final isSelected = index == _selectedIndex;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _selectedIndex = index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        destination.icon,
                        color: isSelected
                            ? primaryColor
                            : Colors.white.withValues(alpha: 0.82),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        destination.label,
                        style: TextStyle(
                          color: isSelected
                              ? primaryColor
                              : Colors.white.withValues(alpha: 0.88),
                          fontWeight:
                              isSelected ? FontWeight.w900 : FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          _DonorStatusCard(donor: _donor),
        ],
      ),
    );
  }

  Widget _buildBottomTabs() {
    return SafeArea(
      top: false,
      child: Container(
        height: 70,
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _donorBorder)),
          boxShadow: [
            BoxShadow(
              color: Color(0x1A7A001D),
              blurRadius: 20,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_destinations.length, (index) {
            final destination = _destinations[index];
            final isSelected = index == _selectedIndex;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _selectedIndex = index),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        destination.icon,
                        size: 21,
                        color: isSelected ? Colors.white : _donorMuted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      destination.shortLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isSelected ? primaryColor : const Color(0xFF1F2937),
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCurrentSection() {
    if (_isLoading) {
      return const _DonorLoadingState();
    }

    if (_errorMessage != null) {
      return _DonorErrorState(message: _errorMessage!, onRetry: _loadDonorApp);
    }

    switch (_selectedIndex) {
      case 0:
        return _buildHomeSection();
      case 1:
        return _buildMapSection();
      case 2:
        return _buildAppointmentsSection();
      case 3:
        return _buildInboxSection();
      case 4:
        return _buildProfileSection();
      default:
        return _buildHomeSection();
    }
  }

  Widget _buildHomeSection() {
    final donor = _donor;
    final urgentNeeds = _urgentNeeds.take(4).toList();
    final nextAppointment = _nextAppointment;

    return RefreshIndicator(
      onRefresh: _loadDonorApp,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _HeroNeedCard(
            donor: donor,
            urgentCount: _urgentNeeds.length,
            onFindHospital: () => setState(() => _selectedIndex = 1),
            onBook: urgentNeeds.isEmpty
                ? null
                : () => _openBooking(urgentNeeds.first),
          ),
          const SizedBox(height: 12),
          _HomeSignalStrip(
            donor: donor,
            urgentCount: _urgentNeeds.length,
            unreadCount: _unreadNotifications.length,
            nextAppointment: nextAppointment,
            hospitalName: nextAppointment == null
                ? null
                : _hospitalById(nextAppointment.hospitalId)?.name,
            dateFormat: _dateFormat,
            timeFormat: _timeFormat,
          ),
          const SizedBox(height: 16),
          _ResponsiveGrid(
            minTileWidth: 170,
            children: [
              _MetricCard(
                label: 'Blood type',
                value: donor?.bloodTypeDisplay ?? '--',
                caption: donor?.status ?? 'Profile pending',
                icon: Icons.bloodtype_rounded,
                color: primaryColor,
              ),
              _MetricCard(
                label: 'Donations',
                value: '${_history.length}',
                caption: 'Tracked donation record',
                icon: Icons.volunteer_activism_rounded,
                color: tealAccent,
              ),
              _MetricCard(
                label: 'Possible lives helped',
                value:
                    '${_history.fold<int>(0, (sum, item) => sum + (item.unitsGiven * 3))}',
                caption: 'Estimated community impact',
                icon: Icons.favorite_rounded,
                color: orangeAccent,
              ),
              _MetricCard(
                label: 'Unread alerts',
                value: '${_unreadNotifications.length}',
                caption: _unreadNotifications.isEmpty
                    ? 'You are caught up'
                    : 'Needs your attention',
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFF2563EB),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _QuickActionRow(
            actions: [
              _QuickAction(
                'Find blood needs',
                'Browse hospitals by urgency and stock',
                Icons.map_rounded,
                primaryColor,
                () => setState(() => _selectedIndex = 1),
              ),
              _QuickAction(
                'My appointments',
                'QR check-in, status, and cancellation',
                Icons.event_available_rounded,
                tealAccent,
                () => setState(() => _selectedIndex = 2),
              ),
              _QuickAction(
                'Alerts',
                'Urgent requests and reminders',
                Icons.notifications_rounded,
                orangeAccent,
                () => setState(() => _selectedIndex = 3),
              ),
              _QuickAction(
                'Donation history',
                'Your completed donor impact',
                Icons.history_rounded,
                const Color(0xFF2563EB),
                () => setState(() => _selectedIndex = 4),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Urgent nearby needs',
            actionLabel: 'Open map',
            onAction: () => setState(() => _selectedIndex = 1),
          ),
          if (urgentNeeds.isEmpty)
            const _EmptyState(
              icon: Icons.check_circle_rounded,
              title: 'No urgent needs right now',
              message:
                  'Hospitals in your area are currently stocked for your blood type.',
            )
          else
            ...urgentNeeds.map(_buildHospitalNeedCard),
          const SizedBox(height: 22),
          _SectionHeader(
            title: 'Next appointment',
            actionLabel: 'View all',
            onAction: () => setState(() => _selectedIndex = 2),
          ),
          if (nextAppointment == null)
            _EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'No appointment scheduled',
              message:
                  'Choose a hospital from urgent needs or the map to book your next donation.',
              actionLabel: urgentNeeds.isEmpty ? null : 'Book now',
              onAction: urgentNeeds.isEmpty
                  ? null
                  : () => _openBooking(urgentNeeds.first),
            )
          else
            _buildAppointmentCard(nextAppointment, compact: true),
        ],
      ),
    );
  }

  Widget _buildMapSection() {
    final topInset = MediaQuery.of(context).padding.top;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 720;

        return Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: const LatLng(7.4479, 125.8078),
                  initialZoom: isCompact ? 8.2 : 8.8,
                  minZoom: 5,
                  maxZoom: 18,
                  onTap: (_, __) => setState(() => _selectedHospital = null),
                ),
                children: [
                  TileLayer(
                    urlTemplate: _tileUrl,
                    subdomains: _tileSubdomains,
                    userAgentPackageName: 'com.example.dugo',
                    maxZoom: 19,
                  ),
                  MarkerLayer(
                    markers: _filteredHospitals.map(_hospitalMarker).toList(),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _donorDeepRed.withValues(alpha: 0.16),
                        Colors.transparent,
                        _donorDeepRed.withValues(alpha: 0.12),
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: topInset + 12,
              left: isCompact ? 12 : 18,
              right: isCompact ? 12 : null,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isCompact ? double.infinity : 690,
                ),
                child: _buildMapControls(compact: isCompact),
              ),
            ),
            Positioned(
              right: isCompact ? 12 : 18,
              bottom: isCompact && _selectedHospital != null
                  ? constraints.maxHeight * 0.48 + 28
                  : isCompact
                      ? 18
                      : 24,
              child: _MapZoomControls(
                onZoomIn: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom + 1).clamp(5.0, 18.0),
                ),
                onZoomOut: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom - 1).clamp(5.0, 18.0),
                ),
              ),
            ),
            if (!isCompact)
              Positioned(
                left: 18,
                bottom: 24,
                child: _MapLegend(),
              ),
            if (_selectedHospital != null)
              if (isCompact)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 16,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.48,
                    ),
                    child: SingleChildScrollView(
                      child: _HospitalDetailPanel(
                        hospital: _selectedHospital!,
                        donorBloodType: _donor?.bloodTypeDisplay,
                        onClose: () => setState(() => _selectedHospital = null),
                        onBook: () => _openBooking(_selectedHospital!),
                      ),
                    ),
                  ),
                )
              else
                Positioned(
                  top: topInset + 112,
                  right: 18,
                  width: 400,
                  child: _HospitalDetailPanel(
                    hospital: _selectedHospital!,
                    donorBloodType: _donor?.bloodTypeDisplay,
                    onClose: () => setState(() => _selectedHospital = null),
                    onBook: () => _openBooking(_selectedHospital!),
                  ),
                ),
          ],
        );
      },
    );
  }

  Widget _buildAppointmentsSection() {
    final upcoming = _appointments
        .where((appointment) =>
            _isActiveAppointment(appointment) && !appointment.isPast)
        .toList();
    final past = _appointments
        .where((appointment) =>
            appointment.status == AppointmentStatus.COMPLETED ||
            appointment.status == AppointmentStatus.NO_SHOW ||
            (appointment.isPast &&
                appointment.status != AppointmentStatus.CANCELLED))
        .toList();
    final cancelled = _appointments
        .where(
            (appointment) => appointment.status == AppointmentStatus.CANCELLED)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadDonorApp,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _PageIntroCard(
            icon: Icons.event_available_rounded,
            title: 'Donation schedule',
            message:
                'Track upcoming visits, keep your QR check-in ready, and manage changes before hospital arrival.',
            color: tealAccent,
          ),
          const SizedBox(height: 18),
          _SectionHeader(
            title: 'Upcoming',
            actionLabel: _urgentNeeds.isEmpty ? null : 'Book',
            onAction: _urgentNeeds.isEmpty
                ? null
                : () => _openBooking(_urgentNeeds.first),
          ),
          if (upcoming.isEmpty)
            const _EmptyState(
              icon: Icons.event_available_rounded,
              title: 'No upcoming appointments',
              message:
                  'Book with a nearby hospital when you are ready to donate.',
            )
          else
            ...upcoming.map(_buildAppointmentCard),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Past donations and visits'),
          if (past.isEmpty)
            const _EmptyState(
              icon: Icons.history_rounded,
              title: 'No past appointments yet',
              message: 'Completed visits will appear here.',
            )
          else
            ...past.take(6).map((appointment) =>
                _buildAppointmentCard(appointment, compact: true)),
          const SizedBox(height: 18),
          const _SectionHeader(title: 'Cancelled'),
          if (cancelled.isEmpty)
            const _EmptyState(
              icon: Icons.cancel_outlined,
              title: 'No cancelled appointments',
              message: 'Cancelled bookings will be kept here for reference.',
            )
          else
            ...cancelled.take(4).map((appointment) =>
                _buildAppointmentCard(appointment, compact: true)),
        ],
      ),
    );
  }

  Widget _buildInboxSection() {
    final visible = _showUnreadOnly
        ? _notifications.where((item) => !item.isRead).toList()
        : _notifications;

    return RefreshIndicator(
      onRefresh: _loadDonorApp,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _PageIntroCard(
            icon: Icons.notifications_active_rounded,
            title: 'Donor alerts',
            message:
                'Urgent blood requests, appointment reminders, and eligibility updates stay collected here.',
            color: orangeAccent,
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: !_showUnreadOnly,
                onSelected: (_) => setState(() => _showUnreadOnly = false),
              ),
              ChoiceChip(
                label: Text('Unread (${_unreadNotifications.length})'),
                selected: _showUnreadOnly,
                onSelected: (_) => setState(() => _showUnreadOnly = true),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            const _EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No notifications here',
              message:
                  'Blood requests, reminders, and system updates will appear here.',
            )
          else
            ...visible.map(_buildNotificationCard),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    final donor = _donor;

    return RefreshIndicator(
      onRefresh: _loadDonorApp,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          const _PageIntroCard(
            icon: Icons.person_rounded,
            title: 'Donor profile',
            message:
                'Keep your blood type, radius, alerts, and history ready so hospitals can match with you quickly.',
            color: primaryColor,
          ),
          const SizedBox(height: 16),
          _DonorCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: lightRedColor,
                      child: Text(
                        donor?.bloodTypeDisplay ?? '?',
                        style: const TextStyle(
                          color: primaryColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donor?.name ?? 'Donor profile',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            donor?.email ??
                                'Complete your donor profile to personalize the app.',
                            style: const TextStyle(color: grayColor),
                          ),
                        ],
                      ),
                    ),
                    _StatusChip(
                      label: donor?.status ?? 'Pending',
                      color:
                          donor?.isEligible == true ? tealAccent : orangeAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _ResponsiveGrid(
                  minTileWidth: 190,
                  children: [
                    _ProfileFact(
                        label: 'Phone', value: donor?.phone ?? 'Not set'),
                    _ProfileFact(
                        label: 'Donation radius',
                        value:
                            '${donor?.radiusKm?.toStringAsFixed(0) ?? '10'} km'),
                    _ProfileFact(
                        label: 'Last donation',
                        value: donor?.lastDonationFormatted ?? 'Never donated'),
                    _ProfileFact(
                      label: 'Notifications',
                      value: donor?.notificationsEnabled == true
                          ? 'Enabled'
                          : 'Disabled',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: donor == null ? null : _openProfileEditor,
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Edit preferences'),
                    ),
                    FilledButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign out'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Donation history'),
          if (_history.isEmpty)
            const _EmptyState(
              icon: Icons.volunteer_activism_rounded,
              title: 'No donation history yet',
              message:
                  'Your completed donations will appear here with the hospital and blood type.',
            )
          else
            ..._history.map(_buildHistoryCard),
        ],
      ),
    );
  }

  Widget _buildMapControls({required bool compact}) {
    final controls = [
      SizedBox(
        width: compact ? 168 : 186,
        child: DropdownButtonFormField<DonorMapStyle>(
          initialValue: _mapStyle,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Map style',
            isDense: true,
          ),
          items: DonorMapStyle.values
              .map(
                (style) => DropdownMenuItem(
                  value: style,
                  child: Text(_mapStyleLabel(style)),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _mapStyle = value ?? _mapStyle),
        ),
      ),
      SizedBox(
        width: compact ? 156 : 170,
        child: DropdownButtonFormField<HospitalUrgency>(
          initialValue: _urgencyFilter,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Urgency',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('All urgency')),
            DropdownMenuItem(
                value: HospitalUrgency.critical, child: Text('Critical')),
            DropdownMenuItem(
                value: HospitalUrgency.low, child: Text('Low stock')),
            DropdownMenuItem(
                value: HospitalUrgency.medium, child: Text('Medium')),
            DropdownMenuItem(
                value: HospitalUrgency.good, child: Text('Well stocked')),
          ],
          onChanged: (value) => setState(() => _urgencyFilter = value),
        ),
      ),
      SizedBox(
        width: compact ? 136 : 150,
        child: DropdownButtonFormField<String>(
          initialValue: _bloodTypeFilter,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Blood type',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('All types')),
            DropdownMenuItem(value: 'A+', child: Text('A+')),
            DropdownMenuItem(value: 'A-', child: Text('A-')),
            DropdownMenuItem(value: 'B+', child: Text('B+')),
            DropdownMenuItem(value: 'B-', child: Text('B-')),
            DropdownMenuItem(value: 'O+', child: Text('O+')),
            DropdownMenuItem(value: 'O-', child: Text('O-')),
            DropdownMenuItem(value: 'AB+', child: Text('AB+')),
            DropdownMenuItem(value: 'AB-', child: Text('AB-')),
          ],
          onChanged: (value) => setState(() => _bloodTypeFilter = value),
        ),
      ),
    ];

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_donorCrimson, _donorDeepRed],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.map_rounded,
                    color: Colors.white, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LifePulse Map',
                      style: TextStyle(
                        color: _donorInk,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${_filteredHospitals.length} hospitals matched',
                      style: const TextStyle(
                        color: _donorMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: _donor?.bloodTypeDisplay ?? 'All blood',
                color: primaryColor,
                soft: true,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (compact)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final control in controls) ...[
                    control,
                    const SizedBox(width: 10),
                  ],
                  _MiniLegendRow(),
                ],
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...controls,
                _StatusChip(
                  label: _urgencyFilter == null
                      ? 'All urgency'
                      : _urgencyFilterLabel(_urgencyFilter!),
                  color: _urgencyFilter == null
                      ? primaryColor
                      : _urgencyColor(_urgencyFilter!),
                  soft: true,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHospitalNeedCard(Hospital hospital) {
    final bloodType = _donor?.bloodTypeDisplay;
    final units = bloodType == null ? null : hospital.bloodInventory[bloodType];
    final stockUnits = units ?? 0;
    final stockLevel = (stockUnits / 40).clamp(0.0, 1.0);
    final urgencyColor = _urgencyColor(hospital.urgency);

    return _DonorCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: urgencyColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 680;
                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _UrgencyIcon(urgency: hospital.urgency),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hospital.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hospital.address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: grayColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _StatusChip(
                          label: hospital.urgencyLabel,
                          color: urgencyColor,
                        ),
                        _StatusChip(
                          label: hospital.is24Hours
                              ? 'Open 24 hours'
                              : hospital.operatingHours ?? 'Check hours',
                          color: tealAccent,
                          soft: true,
                        ),
                        if (bloodType != null)
                          _StatusChip(
                            label: '$bloodType: $stockUnits units',
                            color:
                                stockUnits <= 5 ? primaryColor : orangeAccent,
                            soft: true,
                          ),
                      ],
                    ),
                    if (bloodType != null) ...[
                      const SizedBox(height: 12),
                      _StockBar(
                        label: '$bloodType availability',
                        value: stockLevel,
                        units: stockUnits,
                        color: stockUnits <= 5 ? primaryColor : orangeAccent,
                      ),
                    ],
                  ],
                );

                final action = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${hospital.totalUnits} total units',
                      textAlign: isWide ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(
                        color: grayColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => _openBooking(hospital),
                      icon: const Icon(Icons.event_available_rounded),
                      label: const Text('Book'),
                    ),
                  ],
                );

                if (!isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      const SizedBox(height: 14),
                      action,
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 18),
                    SizedBox(width: 170, child: action),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment,
      {bool compact = false}) {
    final hospital = _hospitalById(appointment.hospitalId);
    final appointmentDate =
        DateTime.parse(appointment.appointmentDate.format()).toLocal();
    final canCancel = _isActiveAppointment(appointment) && !appointment.isPast;
    final canShowQr = _isActiveAppointment(appointment);

    return _DonorCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: lightRedColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.event_available_rounded,
                    color: primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital?.name ??
                          appointment.hospitalName ??
                          'Hospital visit',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_dateFormat.format(appointmentDate)} at ${_timeFormat.format(appointmentDate)}',
                      style: const TextStyle(color: grayColor),
                    ),
                  ],
                ),
              ),
              _StatusChip(
                label: appointment.statusDisplay,
                color: _appointmentColor(appointment.status),
              ),
            ],
          ),
          if (!compact && appointment.notes?.isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(appointment.notes!, style: const TextStyle(color: grayColor)),
          ],
          if (canShowQr || canCancel) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (canShowQr)
                  OutlinedButton.icon(
                    onPressed: () => _showAppointmentQr(appointment),
                    icon: const Icon(Icons.qr_code_rounded),
                    label: const Text('QR check-in'),
                  ),
                if (canCancel)
                  OutlinedButton.icon(
                    onPressed: () => _cancelAppointment(appointment),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    final isUrgent = notification.priority == NotificationPriority.URGENT ||
        notification.priority == NotificationPriority.HIGH;

    return _DonorCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: notification.isRead
            ? null
            : () => _markNotificationRead(notification),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isUrgent ? lightRedColor : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUrgent
                      ? Icons.priority_high_rounded
                      : Icons.notifications_rounded,
                  color: isUrgent ? primaryColor : const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(notification.timeAgo,
                            style: const TextStyle(
                                color: grayColor, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(notification.message,
                        style: const TextStyle(color: grayColor)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        _StatusChip(
                          label: notification.typeFriendly,
                          color: tealAccent,
                          soft: true,
                        ),
                        _StatusChip(
                          label: notification.priorityDisplay,
                          color: isUrgent ? primaryColor : orangeAccent,
                          soft: true,
                        ),
                        if (!notification.isRead)
                          TextButton(
                            onPressed: () =>
                                _markNotificationRead(notification),
                            child: const Text('Mark read'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DonationHistoryModel item) {
    final hospital = _hospitalById(item.hospitalId);
    return _DonorCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FFFA),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.volunteer_activism_rounded, color: tealAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hospital?.name ?? 'Donation visit',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.donationDateFormatted} - ${item.unitsGiven} unit ${item.bloodTypeDisplay}',
                  style: const TextStyle(color: grayColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Marker _hospitalMarker(Hospital hospital) {
    final color = _urgencyColor(hospital.urgency);
    final isSelected = _selectedHospital?.id == hospital.id;
    return Marker(
      point: LatLng(hospital.latitude, hospital.longitude),
      width: isSelected ? 66 : 56,
      height: isSelected ? 66 : 56,
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedHospital = hospital);
          _mapController.move(
              LatLng(hospital.latitude, hospital.longitude),
              _mapController.camera.zoom < 12
                  ? 12
                  : _mapController.camera.zoom);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (hospital.urgency == HospitalUrgency.critical)
                Container(
                  width: isSelected ? 64 : 54,
                  height: isSelected ? 64 : 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.30),
                      width: 8,
                    ),
                  ),
                ),
              Container(
                width: isSelected ? 52 : 44,
                height: isSelected ? 52 : 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.40),
                      blurRadius: isSelected ? 22 : 14,
                      spreadRadius: isSelected ? 4 : 1,
                    ),
                  ],
                ),
              ),
              Container(
                width: isSelected ? 40 : 34,
                height: isSelected ? 40 : 34,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, _donorDeepRed, 0.34)!],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(
                  Icons.bloodtype_rounded,
                  color: Colors.white,
                  size: isSelected ? 23 : 19,
                ),
              ),
              if (isSelected)
                const Positioned(
                  right: 4,
                  top: 4,
                  child: _MapSelectedBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openBooking(Hospital hospital) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookAppointmentScreen(hospital: hospital),
      ),
    );
    await _loadDonorApp();
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    await AppointmentService.updateAppointment(
      id: appointment.id,
      status: 'CANCELLED',
      cancelledAt: DateTime.now(),
      cancellationReason: 'Cancelled by donor',
    );
    await _loadDonorApp();
  }

  Future<void> _markNotificationRead(NotificationModel notification) async {
    await NotificationService.markAsRead(notification.id);
    await _loadDonorApp();
  }

  Future<void> _logout() async {
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _openProfileEditor() async {
    final donor = _donor;
    if (donor == null) return;

    final radiusController = TextEditingController(
      text: (donor.radiusKm ?? 10).toStringAsFixed(0),
    );
    bool notificationsEnabled = donor.notificationsEnabled;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Donor preferences'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: radiusController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Search radius in km',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Notifications'),
                    value: notificationsEnabled,
                    onChanged: (value) =>
                        setDialogState(() => notificationsEnabled = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    await DonorService.updateDonorProfile(
      id: donor.id,
      name: donor.name,
      email: donor.email,
      phone: donor.phone ?? '',
      bloodType: DonorModel.bloodTypeToGraphQL(donor.bloodType),
      radiusKm: double.tryParse(radiusController.text) ?? donor.radiusKm ?? 10,
      notificationsEnabled: notificationsEnabled,
    );
    await _loadDonorApp();
  }

  void _showAppointmentQr(AppointmentModel appointment) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('QR check-in'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(
                data: 'appointment:${appointment.id}',
                version: QrVersions.auto,
                size: 220,
              ),
              const SizedBox(height: 12),
              Text(
                'Show this at ${_hospitalById(appointment.hospitalId)?.name ?? 'the hospital'}',
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  String get _topBarSubtitle {
    if (_donor == null) return 'Local donor workspace';
    return '${_donor!.bloodTypeDisplay} donor - ${_donor!.status}';
  }

  List<NotificationModel> get _unreadNotifications {
    return _notifications
        .where((item) => !item.isRead && !item.isExpired)
        .toList();
  }

  List<Hospital> get _urgentNeeds {
    final bloodType = _donor?.bloodTypeDisplay;
    final hospitals = _hospitals.where((hospital) {
      if (hospital.urgency == HospitalUrgency.critical) return true;
      if (hospital.urgency == HospitalUrgency.low) return true;
      if (bloodType == null) return false;
      return (hospital.bloodInventory[bloodType] ?? 99) <= 15;
    }).toList();
    hospitals.sort(
        (a, b) => _urgencyRank(a.urgency).compareTo(_urgencyRank(b.urgency)));
    return hospitals;
  }

  List<Hospital> get _filteredHospitals {
    return _hospitals.where((hospital) {
      final matchesUrgency =
          _urgencyFilter == null || hospital.urgency == _urgencyFilter;
      final matchesBlood = _bloodTypeFilter == null ||
          (hospital.bloodInventory[_bloodTypeFilter!] ?? 0) <= 15;
      return matchesUrgency && matchesBlood;
    }).toList();
  }

  AppointmentModel? get _nextAppointment {
    final upcoming = _appointments
        .where((appointment) =>
            _isActiveAppointment(appointment) && !appointment.isPast)
        .toList();
    upcoming.sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));
    return upcoming.isEmpty ? null : upcoming.first;
  }

  Hospital? _hospitalById(String id) {
    final matches = _hospitals.where((hospital) => hospital.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  bool _isActiveAppointment(AppointmentModel appointment) {
    return appointment.status == AppointmentStatus.SCHEDULED ||
        appointment.status == AppointmentStatus.CONFIRMED;
  }

  String get _tileUrl {
    switch (_mapStyle) {
      case DonorMapStyle.satellite:
        return 'https://mt1.google.com/vt/lyrs=s&x={x}&y={y}&z={z}';
      case DonorMapStyle.mapbox3D:
        return 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
      case DonorMapStyle.mapboxOutdoors:
        return 'https://api.mapbox.com/styles/v1/mapbox/outdoors-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
      case DonorMapStyle.mapboxSatellite:
        return 'https://api.mapbox.com/styles/v1/mapbox/satellite-streets-v12/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxPublicToken';
      case DonorMapStyle.light:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
      case DonorMapStyle.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png';
      case DonorMapStyle.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case DonorMapStyle.terrain:
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
    }
  }

  List<String> get _tileSubdomains {
    switch (_mapStyle) {
      case DonorMapStyle.light:
      case DonorMapStyle.dark:
      case DonorMapStyle.terrain:
        return const ['a', 'b', 'c'];
      default:
        return const [];
    }
  }

  static String _mapStyleLabel(DonorMapStyle style) {
    switch (style) {
      case DonorMapStyle.satellite:
        return 'Satellite';
      case DonorMapStyle.mapbox3D:
        return 'Mapbox streets';
      case DonorMapStyle.mapboxOutdoors:
        return 'Outdoors';
      case DonorMapStyle.mapboxSatellite:
        return 'Satellite streets';
      case DonorMapStyle.light:
        return 'Light';
      case DonorMapStyle.dark:
        return 'Dark';
      case DonorMapStyle.standard:
        return 'Standard';
      case DonorMapStyle.terrain:
        return 'Terrain';
    }
  }

  static String _urgencyFilterLabel(HospitalUrgency urgency) {
    switch (urgency) {
      case HospitalUrgency.critical:
        return 'Critical';
      case HospitalUrgency.low:
        return 'Low stock';
      case HospitalUrgency.medium:
        return 'Medium';
      case HospitalUrgency.good:
        return 'Well stocked';
    }
  }

  static Color _urgencyColor(HospitalUrgency urgency) {
    switch (urgency) {
      case HospitalUrgency.critical:
        return primaryColor;
      case HospitalUrgency.low:
        return orangeAccent;
      case HospitalUrgency.medium:
        return const Color(0xFFF59E0B);
      case HospitalUrgency.good:
        return tealAccent;
    }
  }

  static int _urgencyRank(HospitalUrgency urgency) {
    switch (urgency) {
      case HospitalUrgency.critical:
        return 0;
      case HospitalUrgency.low:
        return 1;
      case HospitalUrgency.medium:
        return 2;
      case HospitalUrgency.good:
        return 3;
    }
  }

  static Color _appointmentColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.SCHEDULED:
        return const Color(0xFF2563EB);
      case AppointmentStatus.CONFIRMED:
        return tealAccent;
      case AppointmentStatus.COMPLETED:
        return const Color(0xFF16A34A);
      case AppointmentStatus.CANCELLED:
        return grayColor;
      case AppointmentStatus.NO_SHOW:
        return orangeAccent;
    }
  }
}

class _DonorDestination {
  const _DonorDestination(
    this.label,
    this.icon, {
    String? shortLabel,
  }) : shortLabel = shortLabel ?? label;

  final String label;
  final String shortLabel;
  final IconData icon;
}

class _DonorTopBar extends StatelessWidget {
  const _DonorTopBar({
    required this.title,
    required this.subtitle,
    required this.donor,
    required this.unreadCount,
    required this.onInbox,
    required this.onRefresh,
    required this.onLogout,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final DonorModel? donor;
  final int unreadCount;
  final VoidCallback onInbox;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 10 : 16, 16, compact ? 8 : 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Color(0xFFFFF1F3)],
        ),
        border: Border(bottom: BorderSide(color: _donorBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: compact ? 22 : 26,
                    fontWeight: FontWeight.w900,
                    color: _donorInk,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _donorMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: onInbox,
                style: IconButton.styleFrom(
                  backgroundColor: _donorRose,
                  foregroundColor: _donorDeepRed,
                ),
                icon: const Icon(Icons.notifications_rounded),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: onRefresh,
            style: IconButton.styleFrom(
              backgroundColor: _donorRose,
              foregroundColor: _donorDeepRed,
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account',
            onSelected: (value) {
              if (value == 'logout') onLogout();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'logout', child: Text('Sign out')),
            ],
            child: CircleAvatar(
              backgroundColor: primaryColor,
              child: Text(
                donor?.bloodTypeDisplay ?? 'D',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroNeedCard extends StatelessWidget {
  const _HeroNeedCard({
    required this.donor,
    required this.urgentCount,
    required this.onFindHospital,
    required this.onBook,
  });

  final DonorModel? donor;
  final int urgentCount;
  final VoidCallback onFindHospital;
  final VoidCallback? onBook;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final trimmedName = donor?.name.trim();
        final firstName = trimmedName == null || trimmedName.isEmpty
            ? 'there'
            : trimmedName.split(RegExp(r'\s+')).first;
        final bloodLabel = donor?.bloodTypeDisplay ?? 'blood';
        final headline = isWide
            ? 'Hi $firstName, your $bloodLabel can move fast where it matters.'
            : 'Hi $firstName, your $bloodLabel can help nearby hospitals.';
        final message = urgentCount == 0
            ? (isWide
                ? 'Your area is stable right now. Keep your donor profile ready for the next call.'
                : 'Your area is stable. Keep your donor profile ready.')
            : (isWide
                ? '$urgentCount hospital ${urgentCount == 1 ? 'need is' : 'needs are'} waiting in your donor network. Start with the nearest critical match.'
                : '$urgentCount urgent hospital ${urgentCount == 1 ? 'need' : 'needs'} nearby. Start with the nearest match.');
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE51246),
                Color(0xFFB20D32),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.22),
                blurRadius: 26,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -28,
                top: -18,
                child: Container(
                  width: isWide ? 210 : 130,
                  height: isWide ? 210 : 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 18,
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _StatusChip(
                              label: donor?.isEligible == true
                                  ? 'Ready to donate'
                                  : 'Check eligibility',
                              color: Colors.white,
                              soft: true,
                              textColor: Colors.white,
                            ),
                            _StatusChip(
                              label: urgentCount == 0
                                  ? 'Area stable'
                                  : '$urgentCount active needs',
                              color: Colors.white,
                              soft: true,
                              textColor: Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          headline,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isWide ? 28 : 25,
                            height: 1.08,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          message,
                          style: const TextStyle(
                            color: Color(0xFFFFE4E4),
                            fontSize: 15,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: onFindHospital,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: primaryColor,
                              ),
                              icon: const Icon(Icons.map_rounded),
                              label: const Text('Find hospital'),
                            ),
                            OutlinedButton.icon(
                              onPressed: onBook,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white),
                              ),
                              icon: const Icon(Icons.event_available_rounded),
                              label: const Text('Book donation'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isWide) ...[
                    const SizedBox(width: 18),
                    Container(
                      width: 148,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'MATCH',
                            style: TextStyle(
                              color: Color(0xFFFFE4E4),
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            donor?.bloodTypeDisplay ?? '--',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Donor profile active',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFFE4E4),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageIntroCard extends StatelessWidget {
  const _PageIntroCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withValues(alpha: 0.07),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147A001D),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: grayColor,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeSignalStrip extends StatelessWidget {
  const _HomeSignalStrip({
    required this.donor,
    required this.urgentCount,
    required this.unreadCount,
    required this.nextAppointment,
    required this.hospitalName,
    required this.dateFormat,
    required this.timeFormat,
  });

  final DonorModel? donor;
  final int urgentCount;
  final int unreadCount;
  final AppointmentModel? nextAppointment;
  final String? hospitalName;
  final DateFormat dateFormat;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    final appointmentDate = nextAppointment == null
        ? null
        : DateTime.parse(nextAppointment!.appointmentDate.format()).toLocal();

    return _DonorCard(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _SignalPill(
            icon: Icons.verified_rounded,
            label: 'Eligibility',
            value: donor?.status ?? 'Pending',
            color: donor?.isEligible == true ? tealAccent : orangeAccent,
          ),
          _SignalPill(
            icon: Icons.local_hospital_rounded,
            label: 'Priority needs',
            value: urgentCount == 0 ? 'Stable' : '$urgentCount urgent',
            color: urgentCount == 0 ? tealAccent : primaryColor,
          ),
          _SignalPill(
            icon: Icons.event_available_rounded,
            label: 'Next visit',
            value: appointmentDate == null
                ? 'Not booked'
                : '${dateFormat.format(appointmentDate)} - ${timeFormat.format(appointmentDate)}',
            helper: hospitalName,
            color:
                appointmentDate == null ? grayColor : const Color(0xFF2563EB),
          ),
          _SignalPill(
            icon: Icons.notifications_active_rounded,
            label: 'Alerts',
            value: unreadCount == 0 ? 'Clear' : '$unreadCount unread',
            color: unreadCount == 0 ? tealAccent : orangeAccent,
          ),
        ],
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 210),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: grayColor, fontSize: 12),
                ),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (helper != null)
                  Text(
                    helper!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: grayColor, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonorCard extends StatelessWidget {
  const _DonorCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: _donorSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _donorBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x147A001D),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _DonorCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: grayColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    this.minTileWidth = 180,
  });

  final List<Widget> children;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 520
            ? 1
            : (constraints.maxWidth / minTileWidth).floor().clamp(1, 4).toInt();
        final spacing = 10.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final tileHeight = columns == 1
            ? 126.0
            : columns >= 4
                ? 158.0
                : 170.0;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map(
                (child) => SizedBox(
                  width: tileWidth,
                  height: tileHeight,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return _DonorCard(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 520
              ? 1
              : constraints.maxWidth >= 760
                  ? 4
                  : 2;
          final spacing = 10.0;
          final tileWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          final tileHeight = columns == 4
              ? 112.0
              : columns == 1
                  ? 112.0
                  : 144.0;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: actions
                .map(
                  (action) => SizedBox(
                    width: tileWidth,
                    height: tileHeight,
                    child: _QuickActionTile(action: action),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction(
    this.label,
    this.subtitle,
    this.icon,
    this.color,
    this.onPressed,
  );

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: action.onPressed,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                action.color.withValues(alpha: 0.13),
                action.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: action.color.withValues(alpha: 0.24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: action.color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 19),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: action.color,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: grayColor, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.soft = false,
    this.textColor,
  });

  final String label;
  final Color color;
  final bool soft;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: soft ? color.withValues(alpha: 0.13) : color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? (soft ? color : Colors.white),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _UrgencyIcon extends StatelessWidget {
  const _UrgencyIcon({required this.urgency});

  final HospitalUrgency urgency;

  @override
  Widget build(BuildContext context) {
    final color = _DonorAppShellState._urgencyColor(urgency);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.local_hospital_rounded, color: color),
    );
  }
}

class _StockBar extends StatelessWidget {
  const _StockBar({
    required this.label,
    required this.value,
    required this.units,
    required this.color,
  });

  final String label;
  final double value;
  final int units;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: grayColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$units units',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

class _HospitalDetailPanel extends StatelessWidget {
  const _HospitalDetailPanel({
    required this.hospital,
    required this.donorBloodType,
    required this.onClose,
    required this.onBook,
  });

  final Hospital hospital;
  final String? donorBloodType;
  final VoidCallback onClose;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final units =
        donorBloodType == null ? null : hospital.bloodInventory[donorBloodType];
    final urgencyColor = _DonorAppShellState._urgencyColor(hospital.urgency);
    final criticalTypes = hospital.criticalBloodTypes.take(5).join(', ');

    return _DonorCard(
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_donorDeepRed, primaryColor],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hospital.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        hospital.address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFDDE4),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.white,
                  tooltip: 'Close',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: hospital.urgencyLabel,
                      color: urgencyColor,
                    ),
                    if (donorBloodType != null)
                      _StatusChip(
                        label: '$donorBloodType: ${units ?? 0} units',
                        color: (units ?? 0) <= 5 ? primaryColor : orangeAccent,
                        soft: true,
                      ),
                    _StatusChip(
                      label: hospital.is24Hours
                          ? 'Open 24 hours'
                          : (hospital.operatingHours ?? 'Check hours'),
                      color: tealAccent,
                      soft: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MapDetailFact(
                        label: 'Blood units',
                        value: '${hospital.totalUnits}',
                        icon: Icons.inventory_2_rounded,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _MapDetailFact(
                        label: 'Call hospital',
                        value: hospital.phone,
                        icon: Icons.phone_rounded,
                        color: _donorBlue,
                      ),
                    ),
                  ],
                ),
                if (criticalTypes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.priority_high_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Critical blood types: $criticalTypes',
                            style: const TextStyle(
                              color: _donorInk,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onBook,
                    icon: const Icon(Icons.event_available_rounded),
                    label: const Text('Book donation appointment'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapDetailFact extends StatelessWidget {
  const _MapDetailFact({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _donorMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _donorInk,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    return _DonorCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          IconButton(onPressed: onZoomIn, icon: const Icon(Icons.add_rounded)),
          const Divider(height: 1),
          IconButton(
              onPressed: onZoomOut, icon: const Icon(Icons.remove_rounded)),
        ],
      ),
    );
  }
}

class _MapSelectedBadge extends StatelessWidget {
  const _MapSelectedBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _donorDeepRed.withValues(alpha: 0.24),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Padding(
        padding: EdgeInsets.all(2),
        child: Icon(
          Icons.check_circle_rounded,
          color: tealAccent,
          size: 16,
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _DonorCard(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        children: const [
          _LegendItem(color: primaryColor, label: 'Critical'),
          _LegendItem(color: orangeAccent, label: 'Low'),
          _LegendItem(color: Color(0xFFF59E0B), label: 'Medium'),
          _LegendItem(color: tealAccent, label: 'Good'),
        ],
      ),
    );
  }
}

class _MiniLegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: _donorRose,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _donorBorder),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendItem(color: primaryColor, label: 'Critical'),
          SizedBox(width: 10),
          _LegendItem(color: orangeAccent, label: 'Low'),
          SizedBox(width: 10),
          _LegendItem(color: tealAccent, label: 'Good'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _DonorStatusCard extends StatelessWidget {
  const _DonorStatusCard({required this.donor});

  final DonorModel? donor;

  @override
  Widget build(BuildContext context) {
    return _DonorCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Donor status',
              style: TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(
            donor?.status ?? 'Profile pending',
            style: const TextStyle(color: grayColor),
          ),
          const SizedBox(height: 10),
          _StatusChip(
            label: donor?.bloodTypeDisplay ?? 'Set blood type',
            color: primaryColor,
            soft: true,
          ),
        ],
      ),
    );
  }
}

class _ProfileFact extends StatelessWidget {
  const _ProfileFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: grayColor, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _DonorCard(
      child: Column(
        children: [
          Icon(icon, size: 42, color: grayColor),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: grayColor)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _DonorLoadingState extends StatelessWidget {
  const _DonorLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primaryColor),
          SizedBox(height: 12),
          Text('Loading donor workspace...'),
        ],
      ),
    );
  }
}

class _DonorErrorState extends StatelessWidget {
  const _DonorErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: _EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Something needs a retry',
          message: message,
          actionLabel: 'Try again',
          onAction: onRetry,
        ),
      ),
    );
  }
}
