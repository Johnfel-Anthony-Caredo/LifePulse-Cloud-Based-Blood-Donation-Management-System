class RecentFile {
  final String? icon, title, date, size, status;

  RecentFile({this.icon, this.title, this.date, this.size, this.status});
}

List demoRecentFiles = [
  RecentFile(
    icon: "assets/icons/xd_file.svg",
    title: "John Smith",
    date: "A+",
    size: "15 Oct 2025",
    status: "Completed",
  ),
  RecentFile(
    icon: "assets/icons/Figma_file.svg",
    title: "Sarah Johnson",
    date: "O+",
    size: "02 Nov 2025",
    status: "Completed",
  ),
  RecentFile(
    icon: "assets/icons/doc_file.svg",
    title: "Michael Brown",
    date: "B+",
    size: "28 Sep 2025",
    status: "Completed",
  ),
  RecentFile(
    icon: "assets/icons/sound_file.svg",
    title: "Emily Davis",
    date: "AB+",
    size: "20 Oct 2025",
    status: "Pending",
  ),
  RecentFile(
    icon: "assets/icons/media_file.svg",
    title: "James Wilson",
    date: "O-",
    size: "10 Oct 2025",
    status: "Completed",
  ),
  RecentFile(
    icon: "assets/icons/pdf_file.svg",
    title: "Lisa Anderson",
    date: "A-",
    size: "05 Nov 2025",
    status: "Scheduled",
  ),
];
