import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/data/repositories/auth_repository.dart';
import 'package:kktc_taksim/models/driver.dart';
import 'package:kktc_taksim/models/payment_method.dart';
import 'package:kktc_taksim/models/place.dart';
import 'package:kktc_taksim/models/taxi_type.dart';
import 'package:kktc_taksim/services/location_service.dart';

/// Modellerdeki sabit değerlerin ekranda görünen adları.
extension TaxiTypeLabel on TaxiType {
  String label(AppLocalizations l10n) => switch (this) {
        TaxiType.economy => l10n.taxiEconomy,
        TaxiType.comfort => l10n.taxiComfort,
        TaxiType.xl => l10n.taxiXl,
      };
}

extension PaymentMethodLabel on PaymentMethod {
  String label(AppLocalizations l10n) => switch (this) {
        PaymentMethod.cash => l10n.paymentCash,
        PaymentMethod.card => l10n.paymentCard,
      };
}

extension PlaceCategoryLabel on PlaceCategory {
  String label(AppLocalizations l10n) => switch (this) {
        PlaceCategory.restaurant => l10n.categoryRestaurant,
        PlaceCategory.cafe => l10n.categoryCafe,
        PlaceCategory.hotel => l10n.categoryHotel,
        PlaceCategory.entertainment => l10n.categoryEntertainment,
        PlaceCategory.shopping => l10n.categoryShopping,
        PlaceCategory.historic => l10n.categoryHistoric,
      };
}

extension CarColorLabel on CarColor {
  String label(AppLocalizations l10n) => switch (this) {
        CarColor.white => l10n.carWhite,
        CarColor.silver => l10n.carSilver,
        CarColor.black => l10n.carBlack,
      };
}

extension AuthErrorLabel on AuthErrorCode {
  String label(AppLocalizations l10n) => switch (this) {
        AuthErrorCode.invalidPhone => l10n.phoneInvalid,
        AuthErrorCode.invalidCode => l10n.authInvalidCode,
        AuthErrorCode.tooManyRequests => l10n.authTooManyRequests,
        AuthErrorCode.network => l10n.networkError,
        AuthErrorCode.unknown => l10n.actionFailed,
      };
}

extension LocationStatusLabel on LocationStatus {
  String label(AppLocalizations l10n) => switch (this) {
        LocationStatus.granted => '',
        LocationStatus.denied => l10n.locationDenied,
        LocationStatus.deniedForever => l10n.locationDeniedForever,
        LocationStatus.serviceDisabled => l10n.locationServiceDisabled,
        LocationStatus.insecureContext => l10n.locationInsecure,
        LocationStatus.unavailable => l10n.locationUnavailable,
      };
}
