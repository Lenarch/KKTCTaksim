import 'dart:async';

/// Dinlenmeye başlandığı anda [current] değerini, sonra [changes]'ten her sinyalde yenisini yayar.
/// Firestore anlık görüntü akışları gibi davranır. (`async*` ile yazılınca abone olma bir sonraki
/// mikro göreve kaldığı için arada olan değişiklikler kaçabiliyordu.)
Stream<T> watchValue<T>(Stream<void> changes, T Function() current) {
  late final StreamController<T> controller;
  StreamSubscription<void>? subscription;
  controller = StreamController<T>(
    onListen: () {
      controller.add(current());
      subscription = changes.listen((_) => controller.add(current()));
    },
    onCancel: () => subscription?.cancel(),
  );
  return controller.stream;
}
