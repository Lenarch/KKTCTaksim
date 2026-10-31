import 'package:url_launcher/url_launcher.dart';

/// Mağazaların istediği kalıcı adresler; sayfalar Firebase Hosting'de (`hosting/public`).
final Uri privacyPolicyUrl = Uri.parse('https://kktctaksim-1ea24.web.app/gizlilik');
final Uri termsOfUseUrl = Uri.parse('https://kktctaksim-1ea24.web.app/kosullar');

/// Sayfayı tarayıcıda açar; açılamazsa false.
Future<bool> openLegalPage(Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
