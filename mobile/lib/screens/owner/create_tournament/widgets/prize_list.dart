import 'package:flutter/material.dart';

class PrizeList extends StatefulWidget {
  final List<String> prizes;
  final Function(List<String>) onPrizesChanged;

  const PrizeList({
    super.key,
    required this.prizes,
    required this.onPrizesChanged,
  });

  @override
  State<PrizeList> createState() => _PrizeListState();
}

class _PrizeListState extends State<PrizeList> {
  final TextEditingController _prizeController = TextEditingController();

  void _addPrize() {
    if (_prizeController.text.isNotEmpty) {
      final newPrizes = List<String>.from(widget.prizes)..add(_prizeController.text);
      widget.onPrizesChanged(newPrizes);
      _prizeController.clear();
    }
  }

  void _removePrize(int index) {
    final newPrizes = List<String>.from(widget.prizes)..removeAt(index);
    widget.onPrizesChanged(newPrizes);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Prizes', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        // Prize input row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _prizeController,
                decoration: InputDecoration(
                  hintText: 'e.g., Trophy + रू 5000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: _addPrize,
            ),
          ],
        ),
        // Prize list display
        if (widget.prizes.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text('Current prizes:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ...widget.prizes.asMap().entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entry.value)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.red),
                    onPressed: () => _removePrize(entry.key),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }
}