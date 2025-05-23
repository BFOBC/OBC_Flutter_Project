import 'package:broker_flutter_pp/admin/User.dart';
import 'package:broker_flutter_pp/admin/UserProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserFormDialog extends StatefulWidget {
  final User? user;

  const UserFormDialog({Key? key, this.user}) : super(key: key);

  @override
  _UserFormDialogState createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String name, email, phone, address, airport, role;

  @override
  void initState() {
    super.initState();
    name = widget.user?.name ?? '';
    email = widget.user?.email ?? '';
    phone = widget.user?.phone ?? '';
    address = widget.user?.address ?? '';
    airport = widget.user?.airport ?? '';
    role = widget.user?.role ?? 'Courier';
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return AlertDialog(
      title: Text(widget.user == null ? 'Add User' : 'Edit User'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                onSaved: (val) => name = val ?? '',
              ),
              TextFormField(
                initialValue: email,
                decoration: const InputDecoration(labelText: 'Email'),
                onSaved: (val) => email = val ?? '',
              ),
              TextFormField(
                initialValue: phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (val) => phone = val ?? '',
              ),
              TextFormField(
                initialValue: address,
                decoration: const InputDecoration(labelText: 'Address'),
                onSaved: (val) => address = val ?? '',
              ),
              TextFormField(
                initialValue: airport,
                decoration: const InputDecoration(labelText: 'Base Airport'),
                onSaved: (val) => airport = val ?? '',
              ),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: ['Courier', 'Broker', 'Modulator', 'Admin', 'SuperAdmin']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setState(() => role = val ?? 'Courier'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _formKey.currentState!.save();
            if (widget.user == null) {
              final newUser = User(
                id: DateTime.now().millisecondsSinceEpoch,
                name: name,
                email: email,
                phone: phone,
                address: address,
                airport: airport,
                role: role,
              );
              userProvider.addUser(newUser);
            } else {
              final updatedUser = widget.user!..name = name
                ..email = email
                ..phone = phone
                ..address = address
                ..airport = airport
                ..role = role;
              userProvider.updateUser(updatedUser);
            }
            Navigator.pop(context);
          },
          child: Text(widget.user == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
