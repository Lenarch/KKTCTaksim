import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/pickup.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';
import 'package:kktc_taksim/widgets/pickup_chooser.dart';

/// Gruba katılırken (ya da [current] doluysa toplama noktasını değiştirirken) nereden
/// binileceğini seçtirir ve yeni kişi başı ücreti onaydan önce gösterir.
/// Onaylanırsa seçilen [Pickup] ile kapanır; yalnızca yeni biçimli (noktalı) gruplar için açılır.
class JoinGroupSheet extends StatefulWidget {
  final SharedRide ride;
  final GeocodingService geocoding;
  final RoutingService routing;

  /// Üyenin şimdiki toplama noktası; doluysa "nokta değiştir" kipidir.
  final Pickup? current;

  const JoinGroupSheet({
    super.key,
    required this.ride,
    required this.geocoding,
    required this.routing,
    this.current,
  });

  @override
  State<JoinGroupSheet> createState() => _JoinGroupSheetState();
}

class _JoinGroupSheetState extends State<JoinGroupSheet> {
  /// Seçici geçerli bir seçim bildirmeyince null; değiştirme kipinde şimdiki nokta ile başlar.
  late Pickup? _pickup = widget.current;

  /// Seçilen noktayla grubun kişi başı ücreti; hesaplanamıyorsa (kapalı/dolu grup) null.
  int? _newPrice(Pickup pickup) {
    final userId = Backend.instance.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final ride = widget.ride;
      final after = widget.current == null
          ? rideAfterJoin(ride, userId, pickup.detourMeters)
          : rideAfterRepick(ride, userId, pickup.detourMeters);
      return after.pricePerPerson;
    } on SharedRideException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final pickup = _pickup;
    final newPrice = pickup == null ? null : _newPrice(pickup);
    // Değiştirmede ücret aynı kalıyorsa söylenecek bir şey yok.
    final showPreview = newPrice != null && (widget.current == null || newPrice != widget.ride.pricePerPerson);

    return SheetContainer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PickupChooser(
                    meeting: widget.ride.meetingPlace!,
                    geocoding: widget.geocoding,
                    routing: widget.routing,
                    initial: widget.current,
                    onChanged: (value) => setState(() => _pickup = value),
                  ),
                  if (showPreview) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      l10n.joinPricePreview(context.lira(newPrice), context.lira(widget.ride.pricePerPerson)),
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton(
            onPressed: pickup == null ? null : () => Navigator.pop<Pickup>(context, pickup),
            child: Text(widget.current == null ? l10n.join : l10n.saveChanges),
          ),
        ],
      ),
    );
  }
}
