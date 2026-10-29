import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/l10n.dart';

/// Backend'den gelen bir akışı gösterir: ilk veri gelene kadar yükleniyor,
/// hata olursa açıklama ve "Tekrar Dene", veri gelince [builder].
class AsyncView<T> extends StatelessWidget {
  final Stream<T> stream;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;

  const AsyncView({super.key, required this.stream, required this.builder, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<T>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.loadError, textAlign: TextAlign.center),
                  TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
                ],
              ),
            ),
          );
        }
        final data = snapshot.data;
        if (data == null) return const Center(child: CircularProgressIndicator());
        return builder(context, data);
      },
    );
  }
}
