class Donor {
  final String? id, name, bloodGroup, phone, email, lastDonation, status;
  final bool? isAvailable;

  Donor({
    this.id,
    this.name,
    this.bloodGroup,
    this.phone,
    this.email,
    this.lastDonation,
    this.status,
    this.isAvailable,
  });
}

List demoDonors = [
  Donor(
    id: "D001",
    name: "John Smith",
    bloodGroup: "A+",
    phone: "+1234567890",
    email: "john.smith@email.com",
    lastDonation: "15 Oct 2025",
    status: "Available",
    isAvailable: true,
  ),
  Donor(
    id: "D002",
    name: "Sarah Johnson",
    bloodGroup: "O+",
    phone: "+1234567891",
    email: "sarah.j@email.com",
    lastDonation: "02 Nov 2025",
    status: "Available",
    isAvailable: true,
  ),
  Donor(
    id: "D003",
    name: "Michael Brown",
    bloodGroup: "B+",
    phone: "+1234567892",
    email: "m.brown@email.com",
    lastDonation: "28 Sep 2025",
    status: "Available",
    isAvailable: true,
  ),
  Donor(
    id: "D004",
    name: "Emily Davis",
    bloodGroup: "AB+",
    phone: "+1234567893",
    email: "emily.d@email.com",
    lastDonation: "20 Oct 2025",
    status: "Not Available",
    isAvailable: false,
  ),
  Donor(
    id: "D005",
    name: "James Wilson",
    bloodGroup: "O-",
    phone: "+1234567894",
    email: "j.wilson@email.com",
    lastDonation: "10 Oct 2025",
    status: "Available",
    isAvailable: true,
  ),
  Donor(
    id: "D006",
    name: "Lisa Anderson",
    bloodGroup: "A-",
    phone: "+1234567895",
    email: "lisa.a@email.com",
    lastDonation: "05 Nov 2025",
    status: "Available",
    isAvailable: true,
  ),
];
