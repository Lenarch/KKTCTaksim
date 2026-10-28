import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/data/mock_data.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/widgets/home/sheet_container.dart';

class SharedRideScreen extends StatefulWidget {
  const SharedRideScreen({super.key});

  @override
  State<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends State<SharedRideScreen> {
  final List<SharedRide> _rides = List.of(MockData.sharedRides);

  Future<void> _showCreateRideSheet() async {
    final ride = await showModalBottomSheet<SharedRide>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CreateSharedRideSheet(),
    );
    if (!mounted || ride == null) return;
    setState(() => _rides.add(ride));
  }

  void _join(int index) {
    final ride = _rides[index];
    if (ride.isFull || ride.joined) return;
    setState(() => _rides[index] = ride.copyWith(current: ride.current + 1, joined: true));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${ride.from} → ${ride.to} grubuna katıldın.')),
    );
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paylaşımlı Yolculuk'),
        content: const Text(
          'Aynı yöne giden yolcularla bir araç paylaşırsın. '
          'Grup dolduğunda veya kalkış saati geldiğinde yolculuk başlar, '
          'ücret kişi başı ödenir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tamam')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paylaşımlı Yolculuk'),
        actions: [
          IconButton(
            tooltip: 'Nasıl çalışır?',
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfo,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, 96),
        children: [
          const _PromoCard(),
          const SizedBox(height: AppSpacing.xxl),
          Text('Aktif Gruplar', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.lg),
          for (var i = 0; i < _rides.length; i++)
            _RideCard(ride: _rides[i], onJoin: () => _join(i)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null,
        onPressed: _showCreateRideSheet,
        backgroundColor: AppTheme.primaryYellow,
        foregroundColor: AppTheme.primaryBlack,
        icon: const Icon(Icons.add),
        label: const Text('Grup Oluştur'),
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard();

  @override
  Widget build(BuildContext context) {
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
                  'Birlikte yolculuk et,\ndaha avantajlı öde.',
                  style: textTheme.titleMedium?.copyWith(
                    color: AppTheme.primaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aynı yöne giden kişilerle maliyeti paylaş.',
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
  final VoidCallback onJoin;

  const _RideCard({required this.ride, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final mutedStyle = TextStyle(color: mutedColor, fontSize: 13);
    const placeStyle = TextStyle(fontWeight: FontWeight.w600);

    final String buttonLabel;
    if (ride.joined) {
      buttonLabel = 'Katıldın';
    } else if (ride.isFull) {
      buttonLabel = 'Dolu';
    } else {
      buttonLabel = 'Katıl';
    }

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
                Text(
                  '₺${ride.price}',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
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
                Text(ride.date, style: mutedStyle),
                const SizedBox(width: AppSpacing.xl),
                Icon(Icons.access_time, size: 16, color: mutedColor),
                const SizedBox(width: AppSpacing.sm),
                Text(ride.time, style: mutedStyle),
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
                            '${ride.current} / ${ride.capacity} kişi',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            ride.isFull ? 'Dolu' : '${ride.seatsLeft} koltuk kaldı',
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
                ElevatedButton(
                  onPressed: ride.isFull || ride.joined ? null : onJoin,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 45),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                  child: Text(buttonLabel),
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
  static const int _defaultPrice = 100;

  int _currentStep = 0;
  String _from = '';
  String _to = '';
  double _capacity = 4;
  TimeOfDay _time = TimeOfDay.now();

  bool get _canContinue => switch (_currentStep) {
        0 => _from.trim().isNotEmpty,
        1 => _to.trim().isNotEmpty,
        _ => true,
      };

  void _next() {
    if (_currentStep < _lastStep) {
      setState(() => _currentStep++);
      return;
    }
    Navigator.pop(
      context,
      SharedRide(
        from: _from.trim(),
        to: _to.trim(),
        date: 'Bugün',
        time: _time.format(context),
        capacity: _capacity.toInt(),
        current: 1,
        price: _defaultPrice,
        joined: true,
      ),
    );
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SheetContainer(
      heightFactor: 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Yolculuk Oluştur', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Adım ${_currentStep + 1} / ${_lastStep + 1}',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Expanded(
            child: SingleChildScrollView(
              child: switch (_currentStep) {
                0 => _Step(
                    title: 'Nereden?',
                    child: TextFormField(
                      // Adımlar ağaçta aynı yerde durduğu için ayrı key verilmezse
                      // Flutter önceki adımın alanını (ve yazısını) yeniden kullanır.
                      key: const ValueKey('from'),
                      initialValue: _from,
                      autofocus: true,
                      onChanged: (v) => setState(() => _from = v),
                      decoration: const InputDecoration(hintText: 'Başlangıç noktası'),
                    ),
                  ),
                1 => _Step(
                    title: 'Nereye?',
                    child: TextFormField(
                      key: const ValueKey('to'),
                      initialValue: _to,
                      autofocus: true,
                      onChanged: (v) => setState(() => _to = v),
                      decoration: const InputDecoration(hintText: 'Varış noktası'),
                    ),
                  ),
                _ => _Step(
                    title: 'Saat ve Kapasite',
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Yolculuk Saati'),
                          trailing: Text(
                            _time.format(context),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onTap: _pickTime,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text('Vito Kapasitesi: ${_capacity.toInt()}'),
                        Slider(
                          value: _capacity,
                          min: 1,
                          max: 8,
                          divisions: 7,
                          label: '${_capacity.toInt()}',
                          onChanged: (v) => setState(() => _capacity = v),
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
                    child: const Text('Geri'),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _canContinue ? _next : null,
                  child: Text(_currentStep < _lastStep ? 'Devam Et' : 'Yolculuğu Oluştur'),
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
