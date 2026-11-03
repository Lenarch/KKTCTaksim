import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/assistant_repository.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/services/app_settings.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Asistanın önerdiği ve adres aramasıyla doğrulanan yer.
class _Suggestion {
  final GeoPlace place;
  final String reason;
  final double meters;

  const _Suggestion(this.place, this.reason, this.meters);
}

/// Haritanın üstünde açılan YZ asistanı. "Taksi çağır"a basılırsa seçilen [GeoPlace] ile kapanır;
/// fiyat ve onay, mevcut taksi seçim ekranında gösterilir.
class AssistantSheet extends StatefulWidget {
  final GeocodingService geocoding;
  final LatLng near;

  const AssistantSheet({super.key, required this.geocoding, required this.near});

  @override
  State<AssistantSheet> createState() => _AssistantSheetState();
}

class _AssistantSheetState extends State<AssistantSheet> {
  static const int _maxSuggestions = 4;

  final TextEditingController _controller = TextEditingController();
  List<_Suggestion>? _results;
  bool _loading = false;
  String? _error;

  /// Yavaş gelen eski bir yanıt yenisinin üzerine yazılmasın diye.
  int _requestId = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<bool> _ensureConsent() async {
    if (await AppSettings.instance.assistantConsented()) return true;
    if (!mounted) return false;
    final l10n = context.l10n;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.assistantConsentTitle),
        content: Text(l10n.assistantConsentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.assistantConsentAccept)),
        ],
      ),
    );
    if (accepted != true) return false;
    await AppSettings.instance.setAssistantConsented();
    return true;
  }

  Future<void> _ask(String text) async {
    final prompt = text.trim();
    if (prompt.length < 2 || _loading) return;
    FocusScope.of(context).unfocus();
    if (!await _ensureConsent() || !mounted) return;
    final l10n = context.l10n;
    if (!await AppSettings.instance.takeAssistantQuota()) {
      if (mounted) setState(() => _error = l10n.assistantLimit);
      return;
    }
    if (!mounted) return;
    final requestId = ++_requestId;
    final language = Localizations.localeOf(context).languageCode;
    setState(() {
      _loading = true;
      _error = null;
      _results = null;
    });
    try {
      final area = await widget.geocoding.reverse(widget.near).then((p) => p?.name ?? '', onError: (_) => '');
      final suggestions = await Backend.instance.assistant.suggest(AssistantQuery(
        prompt: prompt,
        areaName: area,
        localTime: DateTime.now(),
        languageCode: language,
      ));
      final resolved = await Future.wait(suggestions.take(_maxSuggestions).map(_resolve));
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = resolved.whereType<_Suggestion>().toList();
        _loading = false;
      });
    } on AssistantException catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.error == AssistantError.limitReached ? l10n.assistantLimit : l10n.assistantFailed;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Asistan hatası: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = l10n.assistantFailed;
        _loading = false;
      });
    }
  }

  /// Önerilen yeri haritada bulur (KKTC dışı ve uydurma yerler elenir); bulunamazsa null.
  Future<_Suggestion?> _resolve(PlaceSuggestion suggestion) async {
    try {
      final found = await widget.geocoding.search(suggestion.name, near: widget.near);
      final place = bestPlaceMatch(suggestion.name, found);
      if (place == null) return null;
      // Kartta YZ'nin yazdığı ad değil, taksinin gideceği yerin gerçek adı ve adresi görünür.
      return _Suggestion(place, suggestion.reason, distanceMeters(widget.near, place.position));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    final results = _results;

    return SheetContainer(
      heightFactor: 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppTheme.primaryYellow,
                child: Icon(Icons.auto_awesome, color: AppTheme.primaryBlack),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Text(l10n.assistantTitle, style: theme.textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.assistantIntro, style: muted),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final label in [l10n.assistantChipNearby, l10n.assistantChipDinner, l10n.assistantChipNature])
                ActionChip(
                  label: Text(label),
                  side: BorderSide(color: theme.colorScheme.outline),
                  onPressed: _loading ? null : () => _ask(label),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.send,
            onSubmitted: _ask,
            decoration: InputDecoration(
              hintText: l10n.assistantHint,
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _loading ? null : () => _ask(_controller.text),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView(
              children: [
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      children: [
                        const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: AppSpacing.md),
                        Text(l10n.assistantThinking, style: muted),
                      ],
                    ),
                  )
                else if (_error != null)
                  Text(_error!, style: muted)
                else if (results != null && results.isEmpty)
                  Text(l10n.assistantNoResults, style: muted)
                else if (results != null) ...[
                  for (final s in results) _SuggestionCard(suggestion: s),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: Text(l10n.assistantDisclaimer, style: theme.textTheme.bodySmall?.copyWith(color: muted.color)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final _Suggestion suggestion;

  const _SuggestionCard({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(suggestion.place.name, style: theme.textTheme.titleMedium)),
                Text(context.distance(suggestion.meters),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
            if (suggestion.place.address != null)
              Text(suggestion.place.address!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: AppSpacing.xs),
            Text(suggestion.reason),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, suggestion.place),
                icon: const Icon(Icons.local_taxi),
                label: Text(context.l10n.assistantCallTaxi),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
