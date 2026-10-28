import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

/// Varış noktası seçtirir; seçilen yerin adıyla kapanır.
class DestinationSheet extends StatefulWidget {
  const DestinationSheet({super.key});

  @override
  State<DestinationSheet> createState() => _DestinationSheetState();
}

class _DestinationSheetState extends State<DestinationSheet> {
  String _query = '';

  void _select(String destination) {
    final trimmed = destination.trim();
    if (trimmed.isEmpty) return;
    Navigator.pop(context, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = MockData.recentDestinations
        .where((d) => d.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return SheetContainer(
      heightFactor: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            onChanged: (value) => setState(() => _query = value),
            onSubmitted: _select,
            decoration: const InputDecoration(
              hintText: 'Nereye gitmek istersin?',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ListView(
              children: [
                if (_query.trim().isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(_query.trim()),
                    subtitle: const Text('Bu adrese git'),
                    onTap: () => _select(_query),
                  ),
                for (final destination in suggestions)
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(destination),
                    onTap: () => _select(destination),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
