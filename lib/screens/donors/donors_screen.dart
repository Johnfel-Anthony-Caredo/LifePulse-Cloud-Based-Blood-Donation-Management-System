import 'package:admin_new/responsive.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../models/donor.dart';
import '../dashboard/components/header.dart';

class DonorsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        primary: false,
        padding: EdgeInsets.all(defaultPadding),
        child: Column(
          children: [
            Header(),
            SizedBox(height: defaultPadding),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      SizedBox(height: defaultPadding),
                      DonorsTable(),
                      if (Responsive.isMobile(context))
                        SizedBox(height: defaultPadding),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class DonorsTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    return Container(
      padding: EdgeInsets.all(defaultPadding),
      decoration: BoxDecoration(
        color: secondaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "All Donors",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: defaultPadding),
          isMobile
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: defaultPadding,
                    columns: [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Blood Type")),
                      DataColumn(label: Text("Phone")),
                      DataColumn(label: Text("Last Donation")),
                      DataColumn(label: Text("Status")),
                    ],
                    rows: List.generate(
                      demoDonors.length,
                      (index) => donorDataRow(demoDonors[index]),
                    ),
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: DataTable(
                    columnSpacing: defaultPadding,
                    columns: [
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Blood Type")),
                      DataColumn(label: Text("Phone")),
                      DataColumn(label: Text("Last Donation")),
                      DataColumn(label: Text("Status")),
                    ],
                    rows: List.generate(
                      demoDonors.length,
                      (index) => donorDataRow(demoDonors[index]),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

DataRow donorDataRow(Donor donor) {
  return DataRow(
    cells: [
      DataCell(Text(donor.id!)),
      DataCell(
        Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(Icons.person, size: 18, color: primaryColor),
            ),
            SizedBox(width: 8),
            Text(donor.name!),
          ],
        ),
      ),
      DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            donor.bloodGroup!,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      DataCell(Text(donor.phone!)),
      DataCell(Text(donor.lastDonation!)),
      DataCell(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: donor.status == "Active" 
                ? tealAccent.withOpacity(0.1) 
                : grayColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            donor.status!,
            style: TextStyle(
              color: donor.status == "Active" ? tealAccent : grayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ],
  );
}
