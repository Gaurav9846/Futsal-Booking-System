import 'package:flutter/material.dart';

class UpdateScoreScreen extends StatelessWidget {
  const UpdateScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Score'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Use the fixtures tab to update scores'),
      ),
    );
  }
}