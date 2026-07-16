import 'package:broker_flutter_pp/admin/UserFormDialog.dart';
import 'package:broker_flutter_pp/admin/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ActiveUsersTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return SingleChildScrollView(
      child: DataTable(
        columns: [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Phone')),
          DataColumn(label: Text('Address')),
          DataColumn(label: Text('Base Airport')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Actions')),
        ],
        rows: userProvider.activeUsers.map((user) {
          final canToggle = ['Modulator', 'Admin', 'SuperAdmin'].contains(userProvider.currentUserRole);
          return DataRow(cells: [
            DataCell(Text(user.name)),
            DataCell(Text(user.email)),
            DataCell(Text(user.phone)),
            DataCell(Text(user.address)),
            DataCell(Text(user.airport)),
            DataCell(Text(user.role)),
            DataCell(
              canToggle
                  ? ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: user.isActive ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  userProvider.toggleUserStatus(user.id);
                },
                child: Text(user.isActive ? 'Active' : 'Inactive'),
              )
                  : Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(color: user.isActive ? Colors.green : Colors.red),
              ),
            ),
            DataCell(Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserFormDialog(user: user),
                    );
                  },
                  child: Text('Edit'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                    userProvider.deleteUser(user.id);
                  },
                  child: Text('Delete'),
                ),
              ],
            )),
          ]);
        }).toList(),
      ),
    );
  }
}
