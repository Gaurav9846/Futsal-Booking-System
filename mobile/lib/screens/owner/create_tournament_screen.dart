import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tournament_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../models/tournament.dart';
import 'add_teams_screen.dart';
import 'create_tournament/widgets/type_selection_card.dart';
import 'create_tournament/widgets/prize_list.dart';
import 'create_tournament/widgets/date_selection.dart';

class CreateTournamentScreen extends StatefulWidget {
  final Tournament? tournamentToEdit;

  const CreateTournamentScreen({
    super.key,
    this.tournamentToEdit,
  });

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prizePoolController = TextEditingController();
  final _entryFeeController = TextEditingController();
  final _rulesController = TextEditingController();

  // Selected values
  int? _selectedFutsalId;
  TournamentType _selectedType = TournamentType.knockout;
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime? _endDate;
  int _numberOfTeams = 8;
  bool _isPublished = false;

  // Prize list
  List<String> _prizes = [];

  bool get _isEditing => widget.tournamentToEdit != null;
  bool get _isDraftLocked => _isEditing && widget.tournamentToEdit!.status != TournamentStatus.draft;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _populateForm();
    }
  }

  void _populateForm() {
    final tournament = widget.tournamentToEdit!;
    _selectedFutsalId = tournament.futsalId;
    _nameController.text = tournament.name;
    _descriptionController.text = tournament.description ?? '';
    _selectedType = tournament.type;
    _startDate = tournament.startDate;
    _endDate = tournament.endDate;
    _numberOfTeams = tournament.maxTeams ?? 8;
    _isPublished = tournament.isPublished;

    if (tournament.entryFee != null) {
      _entryFeeController.text = tournament.entryFee!.toString();
    }
    if (tournament.prizePool != null) {
      _prizePoolController.text = tournament.prizePool!.toString();
    }
    _rulesController.text = tournament.rules ?? '';
    if (tournament.prizes != null && tournament.prizes!.isNotEmpty) {
      _prizes = List.from(tournament.prizes!);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _prizePoolController.dispose();
    _entryFeeController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? _startDate
          : (_endDate ?? _startDate.add(const Duration(days: 30))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveTournament() async {
    if (!_formKey.currentState!.validate()) return;

    if (_numberOfTeams <= 0) {
      _showError('Please select number of teams');
      return;
    }
    if (_selectedFutsalId == null) {
      _showError('Please select a futsal');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter tournament name');
      return;
    }

    final tournamentData = {
      'futsalId': _selectedFutsalId,
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      'type': _selectedType == TournamentType.knockout ? 'KNOCKOUT' : 'ROUND_ROBIN',
      'startDate': _startDate.toIso8601String(),
      'endDate': _endDate?.toIso8601String(),
      'maxTeams': _numberOfTeams,
      'entryFee': _entryFeeController.text.isNotEmpty ? double.parse(_entryFeeController.text) : null,
      'prizePool': _prizePoolController.text.isNotEmpty ? double.parse(_prizePoolController.text) : null,
      'rules': _rulesController.text.isNotEmpty ? _rulesController.text : null,
      'prizes': _prizes.isEmpty ? null : _prizes,
      'isPublished': _isPublished,
    };

    _showLoading();

    final provider = Provider.of<TournamentProvider>(context, listen: false);
    final response = _isEditing
        ? await provider.updateTournament(widget.tournamentToEdit!.id, tournamentData)
        : await provider.createTournament(tournamentData);

    if (!mounted) return;
    Navigator.pop(context);

    _showResult(response);

    if (response['status'] == 'success') {
      Navigator.pop(context, true);
      if (!_isEditing) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTeamsScreen(
              tournamentId: response['tournamentId'] ?? 0,
              maxTeams: _numberOfTeams,
              tournamentType: _selectedType,
              tournamentStatus: TournamentStatus.draft,
            ),
          ),
        );
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.green)),
    );
  }

  void _showResult(Map<String, dynamic> response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final futsalProvider = Provider.of<FutsalProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Tournament' : 'Create Tournament'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basic Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Futsal Selection
                    DropdownButtonFormField<int>(
                      value: _selectedFutsalId,
                      decoration: InputDecoration(
                        labelText: 'Select Futsal *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.sports_soccer, color: Colors.green),
                      ),
                      items: futsalProvider.myFutsals.map((futsal) {
                        return DropdownMenuItem<int>(
                          value: futsal.id,
                          child: Text(futsal.name),
                        );
                      }).toList(),
                      onChanged: _isDraftLocked
                          ? null
                          : (value) => setState(() => _selectedFutsalId = value),
                      validator: (value) => value == null ? 'Please select a futsal' : null,
                    ),
                    if (_isEditing && _isDraftLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Futsal cannot be changed after tournament starts',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                    const SizedBox(height: 16),
                    // Tournament Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Tournament Name *',
                        hintText: 'e.g., Summer Cup 2024',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.emoji_events, color: Colors.green),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter tournament name' : null,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your tournament...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.description, color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Tournament Type Card
            TypeSelectionCard(
              selectedType: _selectedType,
              onTypeSelected: (type) => setState(() => _selectedType = type),
              isEditing: _isEditing,
              isDisabled: _isDraftLocked,
            ),
            const SizedBox(height: 16),
            // Schedule Card
            DateSelection(
              startDate: _startDate,
              endDate: _endDate,
              onStartDateSelected: (date) => setState(() => _startDate = date),
              onEndDateSelected: (date) => setState(() => _endDate = date),
              isDisabled: _isDraftLocked,
            ),
            const SizedBox(height: 16),
            // Teams Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teams',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text('Number of Teams: $_numberOfTeams', style: const TextStyle(fontSize: 16)),
                        ),
                        if (!_isDraftLocked) ...[
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _numberOfTeams > 2 ? () => setState(() => _numberOfTeams--) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _numberOfTeams < 32 ? () => setState(() => _numberOfTeams++) : null,
                          ),
                        ],
                      ],
                    ),
                    if (_isEditing && _isDraftLocked)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Number of teams cannot be changed after tournament starts',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Prizes & Fees Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Prizes & Fees',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Entry Fee
                    TextFormField(
                      controller: _entryFeeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Entry Fee (Optional)',
                        hintText: 'रू 0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.currency_rupee, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Prize Pool
                    TextFormField(
                      controller: _prizePoolController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Prize Pool (Optional)',
                        hintText: 'रू 0',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        prefixIcon: const Icon(Icons.emoji_events, color: Colors.orange),
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrizeList(
                      prizes: _prizes,
                      onPrizesChanged: (newPrizes) => setState(() => _prizes = newPrizes),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Rules Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rules & Regulations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _rulesController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Enter tournament rules...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Publish Option
            Card(
              child: SwitchListTile(
                title: const Text('Publish Tournament'),
                subtitle: const Text('Make tournament visible to players'),
                value: _isPublished,
                activeColor: Colors.green,
                onChanged: _isDraftLocked ? null : (value) => setState(() => _isPublished = value),
              ),
            ),
            const SizedBox(height: 24),
            // Submit Button
            ElevatedButton(
              onPressed: _saveTournament,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _isEditing ? 'Update Tournament' : 'Create Tournament',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}