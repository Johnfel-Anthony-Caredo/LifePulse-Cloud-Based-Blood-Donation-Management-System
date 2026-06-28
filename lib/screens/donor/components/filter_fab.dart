import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import '../../../constants.dart';
import '../../../models/hospital.dart';

class FilterFAB extends StatelessWidget {
  final HospitalUrgency? selectedUrgency;
  final String? selectedBloodType;
  final Function(HospitalUrgency?) onUrgencyChanged;
  final Function(String?) onBloodTypeChanged;

  const FilterFAB({
    Key? key,
    this.selectedUrgency,
    this.selectedBloodType,
    required this.onUrgencyChanged,
    required this.onBloodTypeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = selectedUrgency != null || selectedBloodType != null;

    return FloatingActionButton(
      heroTag: 'filter_fab', // Add unique hero tag
      onPressed: () => _showFilterSheet(context),
      backgroundColor: hasActiveFilter ? tealAccent : Colors.white,
      elevation: 4,
      child: Icon(
        Icons.tune_rounded,
        color: hasActiveFilter ? Colors.white : primaryColor,
        size: 24,
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showMaterialModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        selectedUrgency: selectedUrgency,
        selectedBloodType: selectedBloodType,
        onUrgencyChanged: onUrgencyChanged,
        onBloodTypeChanged: onBloodTypeChanged,
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final HospitalUrgency? selectedUrgency;
  final String? selectedBloodType;
  final Function(HospitalUrgency?) onUrgencyChanged;
  final Function(String?) onBloodTypeChanged;

  const _FilterBottomSheet({
    this.selectedUrgency,
    this.selectedBloodType,
    required this.onUrgencyChanged,
    required this.onBloodTypeChanged,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late HospitalUrgency? _tempUrgency;
  late String? _tempBloodType;

  @override
  void initState() {
    super.initState();
    _tempUrgency = widget.selectedUrgency;
    _tempBloodType = widget.selectedBloodType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Title and Clear button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Hospitals',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempUrgency = null;
                    _tempBloodType = null;
                  });
                  widget.onUrgencyChanged(null);
                  widget.onBloodTypeChanged(null);
                  Navigator.pop(context);
                },
                child: Text(
                  'Clear All',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Urgency Filter
          Text(
            'Urgency Level',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildUrgencyChip('All', null),
              _buildUrgencyChip('Critical', HospitalUrgency.critical),
              _buildUrgencyChip('Low Stock', HospitalUrgency.low),
              _buildUrgencyChip('Medium', HospitalUrgency.medium),
              _buildUrgencyChip('Well Stocked', HospitalUrgency.good),
            ],
          ),
          const SizedBox(height: 24),
          
          // Blood Type Filter
          Text(
            'Blood Type Needed',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildBloodTypeChip('All', null),
              _buildBloodTypeChip('A+', 'A+'),
              _buildBloodTypeChip('A-', 'A-'),
              _buildBloodTypeChip('B+', 'B+'),
              _buildBloodTypeChip('B-', 'B-'),
              _buildBloodTypeChip('O+', 'O+'),
              _buildBloodTypeChip('O-', 'O-'),
              _buildBloodTypeChip('AB+', 'AB+'),
              _buildBloodTypeChip('AB-', 'AB-'),
            ],
          ),
          const SizedBox(height: 32),
          
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onUrgencyChanged(_tempUrgency);
                widget.onBloodTypeChanged(_tempBloodType);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: tealAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildUrgencyChip(String label, HospitalUrgency? urgency) {
    final isSelected = _tempUrgency == urgency;
    
    Color chipColor;
    if (urgency == null) {
      chipColor = grayColor;
    } else {
      switch (urgency) {
        case HospitalUrgency.critical:
          chipColor = primaryColor;
          break;
        case HospitalUrgency.low:
          chipColor = orangeAccent;
          break;
        case HospitalUrgency.medium:
          chipColor = const Color(0xFFFCD34D);
          break;
        case HospitalUrgency.good:
          chipColor = tealAccent;
          break;
      }
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _tempUrgency = selected ? urgency : null;
        });
      },
      backgroundColor: isSelected ? chipColor.withOpacity(0.2) : lightGrayColor,
      selectedColor: chipColor.withOpacity(0.2),
      checkmarkColor: chipColor,
      labelStyle: TextStyle(
        color: isSelected ? chipColor : grayColor,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? chipColor : Colors.transparent,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }

  Widget _buildBloodTypeChip(String label, String? bloodType) {
    final isSelected = _tempBloodType == bloodType;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _tempBloodType = selected ? bloodType : null;
        });
      },
      backgroundColor: isSelected ? primaryColor.withOpacity(0.15) : lightGrayColor,
      selectedColor: primaryColor.withOpacity(0.15),
      checkmarkColor: primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? primaryColor : grayColor,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.transparent,
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
