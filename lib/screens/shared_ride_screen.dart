import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/geo.dart';
import 'package:kktc_taksim/core/group_fare.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/geo_place.dart';
import 'package:kktc_taksim/screens/map_pick_screen.dart';
import 'package:kktc_taksim/services/geocoding_service.dart';
import 'package:kktc_taksim/services/pickup_detour.dart';
import 'package:kktc_taksim/services/routing_service.dart';
import 'package:kktc_taksim/widgets/join_group_sheet.dart';
import 'package:kktc_taksim/widgets/pickup_chooser.dart';
import 'package:kktc_taksim/widgets/home/destination_sheet.dart';
import 'package:kktc_taksim/core/app_routes.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/service_time.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/chat_message.dart';
import 'package:kktc_taksim/models/pickup.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/screens/group_chat_screen.dart';
import 'package:kktc_taksim/services/chat_read_state.dart';
import 'package:kktc_taksim/services/trusted_clock.dart';
import 'package:kktc_taksim/widgets/async_view.dart';
import 'package:kktc_taksim/widgets/group_failure_dialog.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

class SharedRideScreen extends StatefulWidget {
  /// Testler sahte servis verebilir.
  final GeocodingService? geocoding;
  final RoutingService? routing;

  const SharedRideScreen({super.key, this.geocoding, this.routing});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  SharedRideRepository get _repository => Backend.instance.sharedRides;
  late Stream<List<SharedRide>> _rides = _repository.watchActive();

  /// Saat ölçülürken düğmeye yeniden basılırsa form iki kez açılmasın.
  bool _openingCreateSheet = false;

  /// Katılma/değiştirme sayfası açıkken ikinci dokunuş yeni sayfa açmasın.
  bool _openingJoinSheet = false;

  /// Her toplama noktası değişince artar; kartlardaki "Toplama noktam" satırı yeniden okunur.
  int _pickupRevision = 0;

  late final GeocodingService _geocoding = widget.geocoding ?? GeocodingService();
  late final RoutingService _routing = widget.routing ?? RoutingService();

  /// Repository çağrısını yapar; hata olursa kullanıcıya anlaşılır bir mesaj gösterir.
  /// [onFailed] verilirse beklenmeyen hatada mesaj yerine o çağrılır.
  Future<bool> _run(Future<void> Function() action, {void Function(String code)? onFailed}) async {
    final l10n = context.l10n;
    try {
      await action();
      return true;
    } on SharedRideException catch (e) {
      if (!mounted) return false;
      showMessage(
        context,
        switch (e.error) {
          SharedRideError.full => l10n.groupFull,
          SharedRideError.closed => l10n.groupClosed,
          _ => l10n.actionFailed,
        },
      );
    } catch (e) {
      // Hata kodu mesajda da görünsün: testçiler cihaz kaydına bakamıyor, ekran görüntüsü atıyor.
      debugPrint('Paylaşımlı grup işlemi başarısız: $e');
      if (!mounted) return false;
      if (onFailed != null) {
        onFailed(errorCode(e));
      } else {
        showMessage(context, l10n.actionFailedWithCode(errorCode(e)));
      }
    }
    return false;
  }

  /// Liste giriş yapmadan da (boş) görünür; grup işlemleri ise giriş ister.
  bool _ensureSignedIn() {
    if (Backend.instance.auth.currentUser != null) return true;
    final l10n = context.l10n;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.signInRequiredForGroups),
        action: SnackBarAction(
          label: l10n.signIn,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
        ),
      ));
    return false;
  }

  Future<void> _showCreateRideSheet() async {
    if (_openingCreateSheet || !_ensureSignedIn()) return;
    _openingCreateSheet = true;
    // Varsayılan kalkış ve "geçmişte" kontrolü telefon saati yanlış olsa da doğru çalışsın.
    await TrustedClock.instance.sync();
    _openingCreateSheet = false;
    if (!mounted) return;
    final created = await showModalBottomSheet<({SharedRide draft, Pickup pickup})>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateSharedRideSheet(geocoding: _geocoding, routing: _routing),
    );
    if (!mounted || created == null) return;
    await _run(
      () => _repository.create(created.draft, created.pickup),
      onFailed: (code) => showDialog<void>(
        context: context,
        builder: (_) => GroupFailureDialog(errorCode: code, departure: created.draft.departure),
      ),
    );
  }

  /// Katılma ya da (şimdiki nokta [current] ise) toplama noktasını değiştirme sayfasını açar.
  Future<Pickup?> _askPickup(SharedRide ride, {Pickup? current}) async {
    if (_openingJoinSheet) return null;
    _openingJoinSheet = true;
    try {
      return await showModalBottomSheet<Pickup>(
        context: context,
        isScrollControlled: true,
        builder: (_) => JoinGroupSheet(ride: ride, geocoding: _geocoding, routing: _routing, current: current),
      );
    } finally {
      _openingJoinSheet = false;
    }
  }

  Future<void> _join(SharedRide ride) async {
    // Eski biçimli grubun düğmesi kapalıdır; yine de buluşma noktası olmadan ilerlenmez.
    if (ride.isLegacy || !_ensureSignedIn()) return;
    final message = context.l10n.joinedGroup(ride.from, ride.to);
    final pickup = await _askPickup(ride);
    if (pickup == null || !mounted) return;
    if (await _run(() => _repository.join(ride.id, pickup)) && mounted) {
      setState(() => _pickupRevision++);
      showMessage(context, message);
    }
  }

  Future<void> _changePickup(SharedRide ride) async {
    if (ride.isLegacy || !_ensureSignedIn()) return;
    final current = await _repository.myPickup(ride.id);
    if (current == null || !mounted) return;
    final pickup = await _askPickup(ride, current: current);
    if (pickup == null || !mounted) return;
    if (await _run(() => _repository.changePickup(ride.id, pickup)) && mounted) {
      setState(() => _pickupRevision++);
    }
  }

  Future<void> _leave(SharedRide ride) async {
    final l10n = context.l10n;
    final confirmed = await confirm(
      context,
      title: l10n.leaveGroupTitle,
      message: l10n.leaveGroupMessage(ride.from, ride.to),
      confirmLabel: l10n.leaveGroup,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    if (await _run(() => _repository.leave(ride.id)) && mounted) showMessage(context, l10n.leftGroup);
  }

  void _openChat(SharedRide ride) {
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => GroupChatScreen(ride: ride)));
  }

  void _showInfo() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.sharedRides),
        content: Text(l10n.sharedRidesInfo),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.ok)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sharedRides),
        actions: [
          IconButton(
            tooltip: l10n.howItWorks,
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: AsyncView<List<SharedRide>>(
        stream: _rides,
        onRetry: () => setState(() => _rides = _repository.watchActive()),
        builder: (context, rides) {
          final userId = Backend.instance.auth.currentUser?.id;
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 96),
            children: [
              const _PromoCard(),
              const SizedBox(height: AppSpacing.xxl),
              Text(l10n.activeGroups, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: AppSpacing.lg),
              if (rides.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child: Text(
                    l10n.noActiveGroups,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              for (final ride in rides)
                _RideCard(
                  ride: ride,
                  joined: ride.hasMember(userId),
                  pickupRevision: _pickupRevision,
                  onJoin: () => _join(ride),
                  onChangePickup: () => _changePickup(ride),
                  onLeave: () => _leave(ride),
                  onChat: () => _openChat(ride),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showCreateRideSheet,
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: AppTheme.primaryBlack,
        icon: const Icon(Icons.add),
        label: Text(l10n.createGroup),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlack,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.sharedPromoTitle,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  l10n.sharedPromoSubtitle,
                  style: textTheme.bodySmall?.copyWith(color: AppTheme.white.withValues(alpha: 0.7)),
                ),
              ],
            ),
          ),
          const Icon(Icons.group_add, color: AppTheme.primaryYellow, size: 50),
        ],
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final SharedRide ride;

  /// Giriş yapmış kullanıcı bu grubun üyesi mi.
  final bool joined;

  /// "Toplama noktam" satırını yeniden okutmak için; değişince satır yenilenir.
  final int pickupRevision;
  final VoidCallback onJoin;
  final VoidCallback onChangePickup;
  final VoidCallback onLeave;
  final VoidCallback onChat;

  const _RideCard({
    required this.ride,
    required this.joined,
    required this.pickupRevision,
    required this.onJoin,
    required this.onChangePickup,
    required this.onLeave,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final mutedStyle = TextStyle(color: mutedColor, fontSize: 13);
    const placeStyle = TextStyle(fontWeight: FontWeight.w600);
    const buttonSize = Size(100, 45);
    // Kişi başı ücret üye sayısına göre oynar; yalnızca yeni biçimli, açık gruplarda geçerli.
    final priceMayChange = !ride.isLegacy && ride.status == SharedRideStatus.open;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.circle, color: AppTheme.primaryYellow, size: 12),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(child: Text(ride.from, style: placeStyle, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: AppTheme.errorRed, size: 12),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(child: Text(ride.to, style: placeStyle, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${priceMayChange ? '≈ ' : ''}${context.lira(ride.pricePerPerson)}',
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(l10n.perPerson, style: mutedStyle),
                    if (priceMayChange) Text(l10n.priceMayChange, style: mutedStyle),
                  ],
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: mutedColor),
                const SizedBox(width: AppSpacing.sm),
                Text(context.serviceWeekdayDate(ride.departure), style: mutedStyle),
                const SizedBox(width: AppSpacing.xl),
                Icon(Icons.access_time, size: 16, color: mutedColor),
                const SizedBox(width: AppSpacing.sm),
                Text(context.serviceTimeLabel(ride.departure), style: mutedStyle),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.peopleCount(ride.current, ride.capacity),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            ride.isFull ? l10n.full : l10n.seatsLeft(ride.seatsLeft),
                            style: TextStyle(
                              color: ride.isFull ? AppTheme.errorRed : AppTheme.successGreen,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(
                        value: ride.fillRatio,
                        backgroundColor: theme.colorScheme.outlineVariant,
                        color: ride.isFull ? AppTheme.errorRed : AppTheme.primaryYellow,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        minHeight: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xl),
                if (joined)
                  OutlinedButton(
                    onPressed: onLeave,
                    style: OutlinedButton.styleFrom(
                      minimumSize: buttonSize,
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error),
                    ),
                    child: Text(l10n.leaveGroup),
                  )
                else
                  ElevatedButton(
                    onPressed: ride.joinable ? onJoin : null,
                    style: ElevatedButton.styleFrom(
                      minimumSize: buttonSize,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: Text(ride.isLegacy ? l10n.legacyGroup : (ride.isFull ? l10n.full : l10n.join)),
                  ),
              ],
            ),
            if (joined && priceMayChange) ...[
              const SizedBox(height: AppSpacing.lg),
              _MyPickupRow(rideId: ride.id, revision: pickupRevision, onChange: onChangePickup),
            ],
            if (joined) ...[
              const SizedBox(height: AppSpacing.lg),
              _ChatButton(rideId: ride.id, onPressed: onChat),
            ],
          ],
        ),
      ),
    );
  }
}

/// Üyenin kendi toplama noktası ve "Değiştir" eylemi; yüklenirken ya da kayıt yokken boş kalır.
class _MyPickupRow extends StatefulWidget {
  final String rideId;
  final int revision;
  final VoidCallback onChange;

  const _MyPickupRow({required this.rideId, required this.revision, required this.onChange});

  @override
  State<_MyPickupRow> createState() => _MyPickupRowState();
}

class _MyPickupRowState extends State<_MyPickupRow> {
  late Future<Pickup?> _pickup = Backend.instance.sharedRides.myPickup(widget.rideId);

  @override
  void didUpdateWidget(_MyPickupRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision || oldWidget.rideId != widget.rideId) {
      _pickup = Backend.instance.sharedRides.myPickup(widget.rideId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<Pickup?>(
      future: _pickup,
      builder: (context, snapshot) {
        final pickup = snapshot.data;
        if (pickup == null) return const SizedBox.shrink();
        return Row(
          children: [
            const Icon(Icons.place_outlined, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.myPickupPoint(pickup.place.name),
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(onPressed: widget.onChange, child: Text(l10n.changePickupAction)),
          ],
        );
      },
    );
  }
}

/// Üyelere görünen "Grup sohbeti" düğmesi; okunmamış mesaj varsa rozet gösterir.
class _ChatButton extends StatefulWidget {
  final String rideId;
  final VoidCallback onPressed;

  const _ChatButton({required this.rideId, required this.onPressed});

  @override
  State<_ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<_ChatButton> {
  late final Stream<ChatMessage?> _latest = Backend.instance.sharedRides.watchLatestMessage(widget.rideId);
  late final Stream<Set<String>> _blocked = Backend.instance.sharedRides.watchBlocked();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final userId = Backend.instance.auth.currentUser?.id;

    return StreamBuilder<Set<String>>(
      stream: _blocked,
      initialData: const {},
      builder: (context, blocked) => StreamBuilder<ChatMessage?>(
      stream: _latest,
      builder: (context, snapshot) => ValueListenableBuilder<Map<String, int>>(
        valueListenable: ChatReadState.instance.lastRead,
        builder: (context, _, __) {
          final unread = ChatReadState.instance
              .isUnread(widget.rideId, snapshot.data, userId, blocked: blocked.data ?? const {});
          return SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: widget.onPressed,
              icon: Badge(
                isLabelVisible: unread,
                smallSize: 10,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              label: Text(unread ? '${l10n.groupChat} • ${l10n.newMessages}' : l10n.groupChat),
            ),
          );
        },
      ),
      ),
    );
  }
}

/// Dört adımlı grup oluşturma formu (nereden, nereye, tarih/saat/kapasite, toplama noktası);
/// taslak grup ve oluşturanın toplama noktasıyla kapanır. Kişi başı ücret yazılmaz, rotadan hesaplanır.
/// Nereden/nereye yazılmaz, ana sayfadaki gibi seçilir (adres araması,
/// son yerler, haritadan seçme): gruba küfür, selam ya da isim gibi yer olmayan bir şey yazılamasın.
class CreateSharedRideSheet extends StatefulWidget {
  /// Testler sahte servis verebilir.
  final GeocodingService? geocoding;
  final RoutingService? routing;

  const CreateSharedRideSheet({super.key, this.geocoding, this.routing});

  @override
  State<CreateSharedRideSheet> createState() => _CreateSharedRideSheetState();
}

class _CreateSharedRideSheetState extends State<CreateSharedRideSheet> {
  static const int _lastStep = 3;
  static const Duration _maximumLeadTime = Duration(days: 30);

  int _currentStep = 0;

  late final GeocodingService _geocoding = widget.geocoding ?? GeocodingService();
  late final RoutingService _routing = widget.routing ?? RoutingService();
  GeoPlace? _from;
  GeoPlace? _to;

  /// Seçim sayfası açıkken ikinci dokunuş yeni sayfa açmasın.
  bool _choosing = false;

  static const double _samePlaceMeters = 100;

  /// Nereden ve nereye aynı yerse grup anlamsız.
  bool get _samePlace {
    final from = _from, to = _to;
    return from != null &&
        to != null &&
        (from.name == to.name || distanceMeters(from.position, to.position) < _samePlaceMeters);
  }
  double _capacity = 4;
  late ServiceDateTime _departure = _defaultDeparture();

  /// Nereden-nereye arası temel yol (metre); hesaplanırken ya da yerler eksik/aynıyken null.
  int? _baseMeters;

  /// Yavaş biten eski bir hesap yenisinin sonucunu ezmesin diye.
  int _baseRequest = 0;

  /// Oluşturanın seçtiği toplama noktası; seçici geçerli bir seçim bildirmeyince null.
  Pickup? _pickup;

  /// Kıbrıs saatiyle bir sonraki tam saat.
  static ServiceDateTime _defaultDeparture() {
    final now = serviceNow();
    return serviceDateTime(now.year, now.month, now.day, now.hour + 1);
  }

  bool get _departureInFuture => _departure.isAfter(serviceNow());

  bool get _canContinue => switch (_currentStep) {
        0 => _from != null,
        1 => _to != null && !_samePlace,
        2 => _baseMeters != null && _departureInFuture,
        _ => _pickup != null && _departureInFuture,
      };

  /// Ana sayfadaki seçim sayfasını açar; "Haritadan seç" denirse harita ekranına geçer.
  Future<void> _choosePlace({required bool from}) async {
    if (_choosing) return;
    _choosing = true;
    try {
      await _choosePlaceOnce(from: from);
    } finally {
      _choosing = false;
    }
  }

  Future<void> _choosePlaceOnce({required bool from}) async {
    final l10n = context.l10n;
    final near = (from ? _from : _to)?.position ?? _from?.position ?? MockData.fallbackLocation;
    final choice = await showModalBottomSheet<DestinationChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DestinationSheet(
        geocoding: _geocoding,
        near: near,
        hintText: from ? l10n.startPoint : l10n.endPoint,
      ),
    );
    if (!mounted || choice == null) return;
    final place = switch (choice) {
      PlaceChosen(:final place) => place,
      PickOnMapChosen() => await Navigator.push<GeoPlace>(
          context,
          MaterialPageRoute(builder: (_) => MapPickScreen(geocoding: _geocoding, initialCenter: near, requireName: true)),
        ),
    };
    if (!mounted || place == null) return;
    setState(() {
      if (from) {
        _from = place;
        // Toplama noktası eski buluşma noktasına göre seçilmişti.
        _pickup = null;
      } else {
        _to = place;
      }
    });
    _loadBaseMeters();
  }

  /// Nereden/nereye değişince temel yolu yeniden hesaplar.
  Future<void> _loadBaseMeters() async {
    final request = ++_baseRequest;
    final from = _from, to = _to;
    setState(() => _baseMeters = null);
    if (from == null || to == null || _samePlace) return;
    final meters = await groupBaseMeters(_routing, from.position, to.position);
    if (!mounted || request != _baseRequest) return;
    setState(() => _baseMeters = meters);
  }

  /// Kurallar 200 karakterden uzun yeri reddeder; adres servisinden çok uzun ad gelirse kısaltılır.
  static String _placeName(GeoPlace place) => place.name.length <= SharedRide.maxPlaceLength
      ? place.name
      : place.name.substring(0, SharedRide.maxPlaceLength);

  void _next() {
    if (_currentStep < _lastStep) {
      setState(() => _currentStep++);
      return;
    }
    Navigator.pop<({SharedRide draft, Pickup pickup})>(
      context,
      // Kimliği, ilk üyeyi (oluşturan kişi), sapmayı ve kişi başı ücreti repository hesaplar.
      (
        draft: SharedRide(
          id: '',
          from: _placeName(_from!),
          to: _placeName(_to!),
          departure: DateTime.fromMillisecondsSinceEpoch(_departure.millisecondsSinceEpoch),
          capacity: _capacity.toInt(),
          memberIds: const [],
          fromPoint: _from!.position,
          toPoint: _to!.position,
          baseMeters: _baseMeters!,
        ),
        pickup: _pickup!,
      ),
    );
  }

  Future<void> _pickDate() async {
    // Takvim Kıbrıs'taki günleri gösterir; telefon başka bir günde olabilir.
    final now = serviceNow();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _departure.isBefore(now) ? today : DateTime(_departure.year, _departure.month, _departure.day),
      firstDate: today,
      lastDate: DateTime(now.year, now.month, now.day + _maximumLeadTime.inDays),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _departure = serviceDateTime(selected.year, selected.month, selected.day, _departure.hour, _departure.minute);
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: TimeOfDay(hour: _departure.hour, minute: _departure.minute));
    if (selected == null || !mounted) return;
    setState(() {
      _departure = serviceDateTime(_departure.year, _departure.month, _departure.day, selected.hour, selected.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const valueStyle = TextStyle(fontWeight: FontWeight.bold);
    final departureInPast = !_departureInFuture;

    return SheetContainer(
      heightFactor: 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.createRide, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.stepOf(_currentStep + 1, _lastStep + 1),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: SingleChildScrollView(
              child: switch (_currentStep) {
                0 => _Step(
                    title: l10n.fromQuestion,
                    child: _PlaceChoice(place: _from, onTap: () => _choosePlace(from: true)),
                  ),
                1 => _Step(
                    title: l10n.toQuestion,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PlaceChoice(place: _to, onTap: () => _choosePlace(from: false)),
                        if (_samePlace) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(l10n.samePlaceError, style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ],
                    ),
                  ),
                2 => _Step(
                    title: l10n.rideDetails,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today),
                          title: Text(l10n.rideDate),
                          trailing: Text(context.weekdayDate(_departure), style: valueStyle),
                          onTap: _pickDate,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.access_time),
                          title: Text(l10n.rideTime),
                          trailing: Text(context.serviceTimeLabel(_departure), style: valueStyle),
                          onTap: _pickTime,
                        ),
                        if (departureInPast)
                          Text(l10n.departureInPast, style: TextStyle(color: theme.colorScheme.error)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(l10n.vitoCapacity(_capacity.toInt())),
                        Slider(
                          value: _capacity,
                          min: 1,
                          max: SharedRide.maxCapacity.toDouble(),
                          divisions: SharedRide.maxCapacity - 1,
                          label: '${_capacity.toInt()}',
                          onChanged: (v) => setState(() => _capacity = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _FareEstimate(baseMeters: _baseMeters, capacity: _capacity.toInt()),
                      ],
                    ),
                  ),
                _ => PickupChooser(
                    meeting: _from!,
                    geocoding: _geocoding,
                    routing: _routing,
                    initial: _pickup,
                    onChanged: (pickup) => setState(() => _pickup = pickup),
                  ),
              },
            ),
          ),
          Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _currentStep--),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 56)),
                    child: Text(l10n.back),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _canContinue ? _next : null,
                  child: Text(_currentStep < _lastStep ? l10n.continueLabel : l10n.createRideButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 3. adımdaki ücret tahmini: tek kişiyle ve grup dolunca kişi başı; yol hesaplanırken ilerleme gösterir.
class _FareEstimate extends StatelessWidget {
  final int? baseMeters;
  final int capacity;

  const _FareEstimate({required this.baseMeters, required this.capacity});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final baseMeters = this.baseMeters;
    if (baseMeters == null) {
      return const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    int perPerson(int members) =>
        groupPricePerPerson(baseMeters: baseMeters, extraMeters: 0, capacity: capacity, members: members);
    final muted = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.groupFareEstimate(context.lira(perPerson(1)), context.lira(perPerson(capacity))), style: muted),
        if (capacity >= largeGroupCapacity) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.largeGroupNote, style: muted),
        ],
      ],
    );
  }
}

/// Seçilen yer ya da "Konum seç"; dokununca seçim sayfası açılır.
class _PlaceChoice extends StatelessWidget {
  final GeoPlace? place;
  final VoidCallback onTap;

  const _PlaceChoice({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final place = this.place;
    final address = place?.address;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(place == null ? Icons.search : Icons.place, color: theme.colorScheme.primary),
        title: Text(
          place?.name ?? context.l10n.chooseLocation,
          style: TextStyle(fontWeight: place == null ? FontWeight.normal : FontWeight.w600),
        ),
        subtitle: address == null ? null : Text(address, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Icon(place == null ? Icons.chevron_right : Icons.edit_outlined),
        onTap: onTap,
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String title;
  final Widget child;

  const _Step({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: AppSpacing.xl),
        child,
      ],
    );
  }
}
