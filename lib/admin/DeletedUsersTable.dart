import 'package:broker_flutter_pp/admin/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DeletedUsersTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return SingleChildScrollView(
      child: DataTable(
        columns: [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Base Airport')),
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Restore')),
        ],
        rows: userProvider.deletedUsers.map((user) {
          return DataRow(cells: [
            DataCell(Text(user.name)),
            DataCell(Text(user.email)),
            DataCell(Text(user.airport)),
            DataCell(Text(user.role)),
            DataCell(
              ElevatedButton(
                onPressed: () {
                  userProvider.restoreUser(user.id);
                },
                child: Text('Restore'),
              ),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}
