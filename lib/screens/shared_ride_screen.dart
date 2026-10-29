import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/widgets/async_view.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({super.key});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  SharedRideRepository get _repository => Backend.instance.sharedRides;
  late Stream<List<SharedRide>> _rides = _repository.watchActive();

  /// Repository çağrısını yapar; hata olursa kullanıcıya anlaşılır bir mesaj gösterir.
  Future<bool> _run(Future<void> Function() action) async {
    final l10n = context.l10n;
    try {
      await action();
      return true;
    } on SharedRideException catch (e) {
      if (mounted) showMessage(context, e.error == SharedRideError.full ? l10n.groupFull : l10n.actionFailed);
    } catch (_) {
      if (mounted) showMessage(context, l10n.actionFailed);
    }
    return false;
  }

  Future<void> _showCreateRideSheet() async {
    final ride = await showModalBottomSheet<SharedRide>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateSharedRideSheet(),
    );
    if (!mounted || ride == null) return;
    await _run(() => _repository.create(ride));
  }

  Future<void> _join(SharedRide ride) async {
    final message = context.l10n.joinedGroup(ride.from, ride.to);
    if (await _run(() => _repository.join(ride.id)) && mounted) showMessage(context, message);
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
                  onJoin: () => _join(ride),
                  onLeave: () => _leave(ride),
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
  final VoidCallback onJoin;
  final VoidCallback onLeave;

  const _RideCard({required this.ride, required this.joined, required this.onJoin, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final mutedStyle = TextStyle(color: mutedColor, fontSize: 13);
    const placeStyle = TextStyle(fontWeight: FontWeight.w600);
    const buttonSize = Size(100, 45);

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
                      context.lira(ride.pricePerPerson),
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(l10n.perPerson, style: mutedStyle),
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
                Text(context.weekdayDate(ride.departure), style: mutedStyle),
                const SizedBox(width: AppSpacing.xl),
                Icon(Icons.access_time, size: 16, color: mutedColor),
                const SizedBox(width: AppSpacing.sm),
                Text(context.time(ride.departure), style: mutedStyle),
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
                    onPressed: ride.isFull ? null : onJoin,
                    style: ElevatedButton.styleFrom(
                      minimumSize: buttonSize,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    ),
                    child: Text(ride.isFull ? l10n.full : l10n.join),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Üç adımlı grup oluşturma formu. Oluşturulan [SharedRide] ile kapanır.
class CreateSharedRideSheet extends StatefulWidget {
  const CreateSharedRideSheet({super.key});

  @override
  State<CreateSharedRideSheet> createState() => _CreateSharedRideSheetState();
}

class _CreateSharedRideSheetState extends State<CreateSharedRideSheet> {
  static const int _lastStep = 2;
  static const int _defaultPrice = 200;
  static const Duration _maximumLeadTime = Duration(days: 30);

  int _currentStep = 0;
  String _from = '';
  String _to = '';
  double _capacity = 4;
  late DateTime _departure = _defaultDeparture();
  String _price = '$_defaultPrice';

  /// Bir sonraki tam saat.
  static DateTime _defaultDeparture() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, now.hour + 1);
  }

  int? get _pricePerPerson {
    final value = int.tryParse(_price);
    return value != null && value > 0 ? value : null;
  }

  bool get _canContinue => switch (_currentStep) {
        0 => _from.trim().isNotEmpty,
        1 => _to.trim().isNotEmpty,
        _ => _pricePerPerson != null && _departure.isAfter(DateTime.now()),
      };

  void _next() {
    if (_currentStep < _lastStep) {
      setState(() => _currentStep++);
      return;
    }
    Navigator.pop(
      context,
      // Kimliği ve ilk üyeyi (oluşturan kişi) repository verir.
      SharedRide(
        id: '',
        from: _from.trim(),
        to: _to.trim(),
        departure: _departure,
        capacity: _capacity.toInt(),
        memberIds: const [],
        pricePerPerson: _pricePerPerson!,
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _departure.isBefore(now) ? now : _departure,
      firstDate: DateUtils.dateOnly(now),
      lastDate: now.add(_maximumLeadTime),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _departure = DateTime(selected.year, selected.month, selected.day, _departure.hour, _departure.minute);
    });
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_departure));
    if (selected == null || !mounted) return;
    setState(() {
      _departure = DateTime(_departure.year, _departure.month, _departure.day, selected.hour, selected.minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    const valueStyle = TextStyle(fontWeight: FontWeight.bold);
    final departureInPast = !_departure.isAfter(DateTime.now());

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
                    child: TextFormField(
                      // Adımlar ağaçta aynı yerde durduğu için ayrı key verilmezse
                      // Flutter önceki adımın alanını (ve yazısını) yeniden kullanır.
                      key: const ValueKey('from'),
                      initialValue: _from,
                      autofocus: true,
                      onChanged: (v) => setState(() => _from = v),
                      decoration: InputDecoration(hintText: l10n.startPoint),
                    ),
                  ),
                1 => _Step(
                    title: l10n.toQuestion,
                    child: TextFormField(
                      key: const ValueKey('to'),
                      initialValue: _to,
                      autofocus: true,
                      onChanged: (v) => setState(() => _to = v),
                      decoration: InputDecoration(hintText: l10n.endPoint),
                    ),
                  ),
                _ => _Step(
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
                          trailing: Text(context.time(_departure), style: valueStyle),
                          onTap: _pickTime,
                        ),
                        if (departureInPast)
                          Text(l10n.departureInPast, style: TextStyle(color: theme.colorScheme.error)),
                        const SizedBox(height: AppSpacing.lg),
                        Text(l10n.vitoCapacity(_capacity.toInt())),
                        Slider(
                          value: _capacity,
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '${_capacity.toInt()}',
                          onChanged: (v) => setState(() => _capacity = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          key: const ValueKey('price'),
                          initialValue: _price,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          onChanged: (v) => setState(() => _price = v),
                          decoration: InputDecoration(
                            labelText: l10n.pricePerPersonLabel,
                            prefixText: '₺ ',
                            helperText: l10n.pricePerPersonHelp,
                          ),
                        ),
                      ],
                    ),
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
