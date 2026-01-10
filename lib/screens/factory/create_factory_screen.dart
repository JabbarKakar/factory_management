import 'package:flutter/material.dart';

class CreateFactoryScreen extends StatelessWidget {
  const CreateFactoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Factory'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Create Factory Screen (Placeholder)'),
      ),
    );
  }
}
