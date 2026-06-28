import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants.dart';
import '../../models/donor_model.dart';
import '../../models/hospital.dart';
import '../../services/appointment_service.dart';
import '../../services/donor_service.dart';

class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key, required this.hospital});

  final Hospital hospital;

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final DateFormat _dateLabelFormat = DateFormat('EEE, MMM d');
  final DateFormat _fullDateFormat = DateFormat('MMMM d, yyyy');

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTimeSlot;
  DonorModel? _donor;
  bool _isLoading = false;
  bool _isProfileLoading = true;

  final List<String> _timeSlots = const [
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
    '11:00 AM',
    '01:00 PM',
    '02:00 PM',
    '03:00 PM',
    '04:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadDonor();
  }

  Future<void> _loadDonor() async {
    final donor = await DonorService.getCurrentDonor();
    if (!mounted) return;
    setState(() {
      _donor = donor;
      _isProfileLoading = false;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _confirmBooking() async {
    if (_selectedTimeSlot == null) {
      _showMessage('Please select a time slot first.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final donor = _donor ?? await DonorService.getCurrentDonor();
      if (donor == null) {
        throw Exception('Donor profile not found');
      }

      final appointmentDateTime = _selectedAppointmentDateTime();
      final appointment = await AppointmentService.createAppointment(
        donorId: donor.id,
        hospitalId: widget.hospital.id,
        appointmentDate: appointmentDateTime,
        bloodType: DonorModel.bloodTypeToGraphQL(donor.bloodType),
        notes:
            'Appointment at $_selectedTimeSlot on ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
      );

      safePrint('Appointment created: ${appointment.id}');

      if (!mounted) return;
      _showMessage(
        'Appointment booked for ${_dateLabelFormat.format(_selectedDate)} at $_selectedTimeSlot.',
      );
      Navigator.pop(context, true);
    } catch (error) {
      safePrint('Error booking appointment: $error');
      if (mounted) {
        _showMessage('Booking failed. Please try again.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final donor = _donor;
    final donorBloodType = donor?.bloodTypeDisplay;
    final donorUnits = donorBloodType == null
        ? null
        : widget.hospital.bloodInventory[donorBloodType] ?? 0;

    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: const Color(0xFFFFF7F7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          centerTitle: false,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Book donation',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        body: _isProfileLoading
            ? const Center(
                child: CircularProgressIndicator(color: primaryColor))
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                children: [
                  _HospitalBookingHeader(
                    hospital: widget.hospital,
                    donorBloodType: donorBloodType,
                    donorUnits: donorUnits,
                  ),
                  const SizedBox(height: 16),
                  _BookingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Donor details',
                          icon: Icons.bloodtype_rounded,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _InfoChip(
                              label: donorBloodType ?? 'Blood type pending',
                              color: primaryColor,
                            ),
                            _InfoChip(
                              label: donor?.status ?? 'Profile pending',
                              color: donor?.isEligible == true
                                  ? tealAccent
                                  : orangeAccent,
                            ),
                            _InfoChip(
                              label:
                                  'Radius ${donor?.radiusKm?.toStringAsFixed(0) ?? '10'} km',
                              color: grayColor,
                              soft: true,
                            ),
                          ],
                        ),
                        if (donor?.isEligible == false) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Your profile is marked not eligible right now. You can still prepare this booking, but the hospital may confirm eligibility on arrival.',
                            style: TextStyle(color: grayColor),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BookingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Choose date',
                          icon: Icons.calendar_today_rounded,
                          trailing: TextButton(
                            onPressed: () => _selectDate(context),
                            child: const Text('Pick date'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _DateSelector(
                          selectedDate: _selectedDate,
                          formatter: _dateLabelFormat,
                          onSelected: (date) =>
                              setState(() => _selectedDate = date),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BookingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Choose time',
                          icon: Icons.schedule_rounded,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _timeSlots.map(_buildTimeSlot).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BookingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Blood inventory',
                          icon: Icons.inventory_2_rounded,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.hospital.bloodInventory.entries
                              .map(
                                (entry) => _InfoChip(
                                  label: '${entry.key}: ${entry.value}',
                                  color: _stockColor(entry.value),
                                  soft: entry.key != donorBloodType,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const _BookingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Before you arrive',
                          icon: Icons.health_and_safety_rounded,
                        ),
                        SizedBox(height: 12),
                        _PrepItem(
                          icon: Icons.restaurant_rounded,
                          title: 'Eat a proper meal',
                          message:
                              'Avoid arriving hungry. A light, iron-rich meal helps the screening go smoother.',
                        ),
                        _PrepItem(
                          icon: Icons.water_drop_rounded,
                          title: 'Hydrate well',
                          message:
                              'Drink water before your visit and bring a valid ID for check-in.',
                        ),
                        _PrepItem(
                          icon: Icons.qr_code_rounded,
                          title: 'Keep your QR ready',
                          message:
                              'After booking, your appointment appears in the Appointments tab for check-in.',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: _BookingBottomBar(
          selectedDate: _selectedDate,
          selectedTime: _selectedTimeSlot,
          dateFormat: _fullDateFormat,
          isLoading: _isLoading,
          onConfirm: _confirmBooking,
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    final isSelected = _selectedTimeSlot == time;
    return ChoiceChip(
      label: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(time),
      ),
      selected: isSelected,
      selectedColor: primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF111827),
        fontWeight: FontWeight.w800,
      ),
      side: BorderSide(
          color: isSelected ? primaryColor : const Color(0xFFFFE4E4)),
      onSelected: (_) => setState(() => _selectedTimeSlot = time),
    );
  }

  DateTime _selectedAppointmentDateTime() {
    final parts = _selectedTimeSlot!.split(' ');
    final hourMinute = parts[0].split(':');
    var hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);
    final isPm = parts[1] == 'PM';

    if (isPm && hour != 12) hour += 12;
    if (!isPm && hour == 12) hour = 0;

    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour,
      minute,
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? primaryColor : tealAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _stockColor(int units) {
    if (units <= 5) return primaryColor;
    if (units <= 15) return orangeAccent;
    if (units <= 30) return const Color(0xFFF59E0B);
    return tealAccent;
  }
}

class _HospitalBookingHeader extends StatelessWidget {
  const _HospitalBookingHeader({
    required this.hospital,
    required this.donorBloodType,
    required this.donorUnits,
  });

  final Hospital hospital;
  final String? donorBloodType;
  final int? donorUnits;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.local_hospital_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hospital.address,
                      style: const TextStyle(color: Color(0xFFFFE4E4)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                label: hospital.urgencyLabel,
                color: Colors.white,
                textColor: Colors.white,
                soft: true,
              ),
              _InfoChip(
                label: hospital.is24Hours
                    ? 'Open 24 hours'
                    : hospital.operatingHours ?? 'Check hours',
                color: Colors.white,
                textColor: Colors.white,
                soft: true,
              ),
              if (donorBloodType != null)
                _InfoChip(
                  label: '$donorBloodType stock: ${donorUnits ?? 0}',
                  color: Colors.white,
                  textColor: Colors.white,
                  soft: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.formatter,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final DateFormat formatter;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final dates = List.generate(
      7,
      (index) => DateTime.now().add(Duration(days: index + 1)),
    );

    return SizedBox(
      height: 74,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, selectedDate);
          return ChoiceChip(
            label: SizedBox(
              width: 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    index == 0 ? 'Tomorrow' : formatter.format(date),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM d').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white70 : grayColor,
                    ),
                  ),
                ],
              ),
            ),
            selected: isSelected,
            selectedColor: primaryColor,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: isSelected ? primaryColor : const Color(0xFFFFE4E4),
            ),
            onSelected: (_) => onSelected(date),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _BookingBottomBar extends StatelessWidget {
  const _BookingBottomBar({
    required this.selectedDate,
    required this.selectedTime,
    required this.dateFormat,
    required this.isLoading,
    required this.onConfirm,
  });

  final DateTime selectedDate;
  final String? selectedTime;
  final DateFormat dateFormat;
  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFFFE4E4))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected schedule',
                    style: TextStyle(color: grayColor, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    selectedTime == null
                        ? 'Choose a time'
                        : '${dateFormat.format(selectedDate)} at $selectedTime',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: isLoading ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE4E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _PrepItem extends StatelessWidget {
  const _PrepItem({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: primaryColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft ? color.withValues(alpha: 0.14) : color,
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
