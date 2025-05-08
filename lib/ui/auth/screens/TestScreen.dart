import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Testscreen extends StatelessWidget {
  const Testscreen({super.key});

  @override
  Widget build(BuildContext context) {
    print("DrawerScreen build() called");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawer Screen'),
      ),
      drawer: const Drawer(
        child: Center(child: Text('Drawer Menu')),
      ),
      body: const Center(
        child: Text('Welcome to Drawer Screen!'),
      ),
    );
  }
}
