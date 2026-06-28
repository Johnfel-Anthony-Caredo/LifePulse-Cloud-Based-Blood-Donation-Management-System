class BloodInventory {
  final String? bloodGroup, units, status;
  final int? percentage;

  BloodInventory({
    this.bloodGroup,
    this.units,
    this.status,
    this.percentage,
  });
}

List demoBloodInventory = [
  BloodInventory(
    bloodGroup: "A+",
    units: "85 units",
    status: "Good Stock",
    percentage: 85,
  ),
  BloodInventory(
    bloodGroup: "O+",
    units: "120 units",
    status: "Good Stock",
    percentage: 95,
  ),
  BloodInventory(
    bloodGroup: "B+",
    units: "45 units",
    status: "Medium Stock",
    percentage: 55,
  ),
  BloodInventory(
    bloodGroup: "AB+",
    units: "28 units",
    status: "Low Stock",
    percentage: 30,
  ),
  BloodInventory(
    bloodGroup: "A-",
    units: "32 units",
    status: "Medium Stock",
    percentage: 40,
  ),
  BloodInventory(
    bloodGroup: "O-",
    units: "15 units",
    status: "Critical",
    percentage: 15,
  ),
  BloodInventory(
    bloodGroup: "B-",
    units: "22 units",
    status: "Low Stock",
    percentage: 25,
  ),
  BloodInventory(
    bloodGroup: "AB-",
    units: "12 units",
    status: "Critical",
    percentage: 12,
  ),
];
