import 'package:broker_flutter_pp/admin/ActiveUsersTable.dart';
import 'package:broker_flutter_pp/admin/DeletedUsersTable.dart';
import 'package:broker_flutter_pp/admin/UserFormDialog.dart';
import 'package:broker_flutter_pp/admin/UserProvider.dart';
import 'package:broker_flutter_pp/admin/UserStatusChart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  bool showDeleted = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel – User Management'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add User'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => UserFormDialog(),
                    );
                  },
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  icon: Icon(Icons.delete),
                  label: Text(showDeleted ? 'View Active Accounts' : 'View Deleted Accounts'),
                  onPressed: () {
                    setState(() {
                      showDeleted = !showDeleted;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 16),
            Expanded(
              child: showDeleted ? DeletedUsersTable() : ActiveUsersTable(),
            ),
            SizedBox(height: 16),
            Text('User Status Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            SizedBox(height: 200, child: UserStatusChart()),
          ],
        ),
      ),
    );
  }
}
