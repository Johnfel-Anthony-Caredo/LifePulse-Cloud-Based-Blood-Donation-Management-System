class BloodRequest {
  final String? id, patientName, bloodGroup, units, requestDate, hospital, status, urgency;

  BloodRequest({
    this.id,
    this.patientName,
    this.bloodGroup,
    this.units,
    this.requestDate,
    this.hospital,
    this.status,
    this.urgency,
  });
}

List demoBloodRequests = [
  BloodRequest(
    id: "REQ001",
    patientName: "David Martinez",
    bloodGroup: "A+",
    units: "2 units",
    requestDate: "04 Nov 2025",
    hospital: "City General Hospital",
    status: "Pending",
    urgency: "High",
  ),
  BloodRequest(
    id: "REQ002",
    patientName: "Anna Thompson",
    bloodGroup: "O+",
    units: "3 units",
    requestDate: "04 Nov 2025",
    hospital: "St. Mary's Medical Center",
    status: "In Progress",
    urgency: "Critical",
  ),
  BloodRequest(
    id: "REQ003",
    patientName: "Robert Lee",
    bloodGroup: "B+",
    units: "1 unit",
    requestDate: "03 Nov 2025",
    hospital: "Community Health Clinic",
    status: "Completed",
    urgency: "Medium",
  ),
  BloodRequest(
    id: "REQ004",
    patientName: "Jennifer White",
    bloodGroup: "AB-",
    units: "2 units",
    requestDate: "03 Nov 2025",
    hospital: "Regional Medical Center",
    status: "Pending",
    urgency: "High",
  ),
  BloodRequest(
    id: "REQ005",
    patientName: "Christopher Green",
    bloodGroup: "O-",
    units: "4 units",
    requestDate: "02 Nov 2025",
    hospital: "Emergency Care Hospital",
    status: "Critical",
    urgency: "Critical",
  ),
];
