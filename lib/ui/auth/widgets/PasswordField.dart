import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../common/utils/validator.dart';

import 'package:flutter/material.dart';
import 'package:broker_flutter_pp/ui/common/utils/validator.dart';

class PasswordField extends StatefulWidget {
  final TextEditingController controller;

  const PasswordField({super.key, required this.controller});

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            decoration: InputDecoration(
              labelText: 'Enter Password',
              prefixIcon: const Icon(Icons.lock),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              ),
            ),
            validator: (value) {
              return Validator.validatePassword(password: value ?? '');
            },
          ),
        ),
      ],
    );
  }
}
