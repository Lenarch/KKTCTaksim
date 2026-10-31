import 'package:flutter/widgets.dart';

/// [node]'u, içinde bulunduğu sayfa ya da alt pencere açılış kaymasını bitirince odaklar.
///
/// `autofocus: true` odağı kayma sürerken istiyor; bazı Android telefonlarda (ör. Xiaomi) bu
/// durumda alan seçili görünse de klavye hiç açılmıyordu ve kullanıcı yazamıyordu.
void focusAfterTransition(BuildContext context, FocusNode node) {
  void focus() {
    if (node.context != null) node.requestFocus();
  }

  final animation = ModalRoute.of(context)?.animation;
  if (animation == null || animation.status == AnimationStatus.completed) {
    WidgetsBinding.instance.addPostFrameCallback((_) => focus());
    return;
  }

  void onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    animation.removeStatusListener(onStatus);
    focus();
  }

  animation.addStatusListener(onStatus);
}
