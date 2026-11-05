import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/models/group_diagnostics.dart';

/// Grup açılamayınca nedeni cihazda ölçer; en olası nedeni ve ekran görüntüsü için teknik özeti gösterir.
class GroupFailureDialog extends StatefulWidget {
  final String errorCode;
  final DateTime departure;

  const GroupFailureDialog({super.key, required this.errorCode, required this.departure});

  @override
  State<GroupFailureDialog> createState() => _GroupFailureDialogState();
}

class _GroupFailureDialogState extends State<GroupFailureDialog> {
  late final Future<GroupDiagnostics> _diagnostics = Backend.instance.sharedRides.diagnose();

  String _suspectText(GroupDiagnostics diagnostics) {
    final l10n = context.l10n;
    final suspect = groupFailureSuspect(
      errorCode: widget.errorCode,
      diagnostics: diagnostics,
      departure: widget.departure,
    );
    return switch (suspect) {
      GroupFailureSuspect.signedOut => l10n.groupSuspectSignedOut,
      GroupFailureSuspect.session => l10n.groupSuspectSession,
      GroupFailureSuspect.readDenied => l10n.groupSuspectReadDenied,
      GroupFailureSuspect.clock => l10n.groupSuspectClock,
      GroupFailureSuspect.network => l10n.groupSuspectNetwork,
      GroupFailureSuspect.rules => l10n.groupSuspectRules,
      GroupFailureSuspect.unknown => l10n.groupSuspectUnknown,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return FutureBuilder<GroupDiagnostics>(
      future: _diagnostics,
      builder: (context, snapshot) {
        final diagnostics = snapshot.data;
        final report = diagnostics == null
            ? null
            : groupDiagnosticsReport(
                errorCode: widget.errorCode,
                diagnostics: diagnostics,
                departure: widget.departure,
              );
        return AlertDialog(
          title: Text(l10n.groupFailureTitle),
          content: SingleChildScrollView(
            child: diagnostics == null || report == null
                ? Row(
                    children: [
                      const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(l10n.groupFailureChecking)),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_suspectText(diagnostics)),
                      const SizedBox(height: AppSpacing.md),
                      SelectableText(
                        report,
                        style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(l10n.groupFailureHint, style: theme.textTheme.bodySmall),
                    ],
                  ),
          ),
          actions: [
            if (report != null)
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: report));
                  if (context.mounted) showMessage(context, l10n.groupFailureCopied);
                },
                child: Text(l10n.groupFailureCopy),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: Text(MaterialLocalizations.of(context).closeButtonLabel)),
          ],
        );
      },
    );
  }
}
