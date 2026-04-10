import 'package:flutter/material.dart';

class TeamForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;
  final bool isEnabled;

  const TeamForm({
    super.key,
    required this.onSubmit,
    required this.isEnabled,
  });

  @override
  State<TeamForm> createState() => _TeamFormState();
}

class _TeamFormState extends State<TeamForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _captainNameController = TextEditingController();
  final _captainPhoneController = TextEditingController();
  final _jerseyColorController = TextEditingController();
  final List<TextEditingController> _playerControllers = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 5; i++) {
      _addPlayerField();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _captainNameController.dispose();
    _captainPhoneController.dispose();
    _jerseyColorController.dispose();
    for (var controller in _playerControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addPlayerField() {
    setState(() {
      _playerControllers.add(TextEditingController());
    });
  }

  void _removePlayerField(int index) {
    setState(() {
      _playerControllers[index].dispose();
      _playerControllers.removeAt(index);
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    List<String> players = _playerControllers
        .map((c) => c.text.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (players.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 5 players'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    widget.onSubmit({
      'name': _nameController.text.trim(),
      'captainName': _captainNameController.text.trim(),
      'captainPhone': _captainPhoneController.text.trim(),
      'jerseyColor': _jerseyColorController.text.trim(),
      'players': players,
    });

    _clearForm();
  }

  void _clearForm() {
    _nameController.clear();
    _captainNameController.clear();
    _captainPhoneController.clear();
    _jerseyColorController.clear();
    for (var controller in _playerControllers) {
      controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isEnabled) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Team',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Team Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Team Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.group, color: Colors.green),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter team name' : null,
            ),
            const SizedBox(height: 12),

            // Captain Name
            TextFormField(
              controller: _captainNameController,
              decoration: InputDecoration(
                labelText: 'Captain Name *',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.person, color: Colors.green),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Please enter captain name' : null,
            ),
            const SizedBox(height: 12),

            // Captain Phone
            TextFormField(
              controller: _captainPhoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Captain Phone',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.phone, color: Colors.green),
              ),
            ),
            const SizedBox(height: 12),

            // Jersey Color
            TextFormField(
              controller: _jerseyColorController,
              decoration: InputDecoration(
                labelText: 'Jersey Color',
                hintText: 'e.g., Red, Blue, Green',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.color_lens, color: Colors.green),
              ),
            ),
            const SizedBox(height: 12),

            // Players
            const Text('Players (minimum 5)', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            ..._playerControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          hintText: 'Player ${index + 1} name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          prefixIcon: const Icon(Icons.person_outline, size: 20),
                        ),
                      ),
                    ),
                    if (_playerControllers.length > 5)
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removePlayerField(index),
                      ),
                  ],
                ),
              );
            }),

            TextButton.icon(
              onPressed: _addPlayerField,
              icon: const Icon(Icons.add),
              label: const Text('Add Player'),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Add Team'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}