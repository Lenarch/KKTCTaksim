import 'dart:async';

/// [source]'tan her yeni değer gelince önceki iç akışı kapatıp [inner] ile yenisine geçer
/// (RxDart'taki `switchMap`). `asyncExpand` bunun yerine kullanılamaz: Firestore akışları hiç
/// bitmediği için bir sonraki değere (örn. başka kullanıcının girişi) asla geçmez.
Stream<R> switchMap<T, R>(Stream<T> source, Stream<R> Function(T value) inner) {
  late final StreamController<R> controller;
  StreamSubscription<T>? sourceSubscription;
  StreamSubscription<R>? innerSubscription;

  controller = StreamController<R>(
    onListen: () {
      sourceSubscription = source.listen(
        (value) {
          innerSubscription?.cancel();
          innerSubscription = inner(value).listen(controller.add, onError: controller.addError);
        },
        onError: controller.addError,
        onDone: () async {
          await innerSubscription?.cancel();
          await controller.close();
        },
      );
    },
    onCancel: () async {
      await innerSubscription?.cancel();
      await sourceSubscription?.cancel();
    },
  );
  return controller.stream;
}
