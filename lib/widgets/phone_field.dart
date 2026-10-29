import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kktc_taksim/core/l10n.dart';

/// Giriş ve kayıtta kullanılan telefon numarası alanı.
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final VoidCallback? onSubmitted;
  final bool autofocus;

  const PhoneField({
    super.key,
    required this.controller,
    required this.validator,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.phone,
      textInputAction: onSubmitted == null ? TextInputAction.next : TextInputAction.done,
      autofillHints: const [AutofillHints.telephoneNumber],
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
      validator: validator,
      onFieldSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
      decoration: InputDecoration(
        labelText: l10n.phoneNumber,
        hintText: '+90 5xx xxx xx xx',
        prefixIcon: const Icon(Icons.phone_outlined),
      ),
    );
  }
}
