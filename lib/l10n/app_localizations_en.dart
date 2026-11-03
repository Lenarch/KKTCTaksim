// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KKTC Taksim';

  @override
  String get appNameUpper => 'KKTC TAKSİM';

  @override
  String get tagline => 'The smart taxi app of North Cyprus';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get continueLabel => 'Continue';

  @override
  String get retry => 'Try Again';

  @override
  String get change => 'Change';

  @override
  String get settings => 'Settings';

  @override
  String get cannotOpen => 'This can\'t be opened on your device.';

  @override
  String comingSoon(String feature) {
    return '$feature is coming soon.';
  }

  @override
  String get estimated => 'Est.';

  @override
  String minutesShort(int count) {
    return '$count min';
  }

  @override
  String get chooseRole => 'Please choose your role to continue';

  @override
  String get rolePassenger => 'I\'m a Passenger';

  @override
  String get rolePassengerHint => 'Call a taxi, share a ride';

  @override
  String get roleDriver => 'I\'m a Driver';

  @override
  String get roleDriverHint => 'Manage requests, earn money';

  @override
  String get roleStand => 'Taxi Stand';

  @override
  String get roleStandHint => 'Manage your stand and fleet';

  @override
  String get driverLogin => 'Driver sign-in';

  @override
  String get standLogin => 'Taxi stand sign-in';

  @override
  String get welcome => 'Welcome';

  @override
  String get loginSubtitle =>
      'Enter your phone number and we\'ll text you a verification code';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneRequired => 'Phone number is required';

  @override
  String get phoneInvalid => 'Enter a valid phone number';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get sendCode => 'Send Code';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign Up';

  @override
  String get createAccount => 'Create an Account';

  @override
  String get signupSubtitle =>
      'Enter your name and phone number; we\'ll verify it by SMS';

  @override
  String get fullName => 'Full Name';

  @override
  String get termsPrefix => 'By signing up you accept the ';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get termsSuffix => '.';

  @override
  String get verificationCode => 'Verification Code';

  @override
  String enterCode(String phone, int length) {
    return 'Enter the $length-digit code sent to $phone.';
  }

  @override
  String get verify => 'Verify';

  @override
  String get didntGetCode => 'Didn\'t get the code?';

  @override
  String get resend => 'Resend';

  @override
  String codeResent(String phone) {
    return 'The code was sent again to $phone.';
  }

  @override
  String get verificationSuccess => 'Verified! Welcome.';

  @override
  String get navHome => 'Home';

  @override
  String get myTrips => 'My Trips';

  @override
  String get navShared => 'Shared';

  @override
  String get explore => 'Explore';

  @override
  String get profile => 'Profile';

  @override
  String greeting(String name) {
    return 'Hi $name 👋';
  }

  @override
  String get whereToGo => 'Where would you like to go?';

  @override
  String get whereTo => 'Where to?';

  @override
  String get currentLocation => 'Your current location';

  @override
  String get tripStartPoint => 'Starting point';

  @override
  String get goToMyLocation => 'Go to my location';

  @override
  String get showingFallbackCity => 'Showing central Nicosia on the map.';

  @override
  String get locationDenied => 'Location permission was not granted.';

  @override
  String get locationDeniedForever =>
      'Location permission is off. You can turn it on in Settings.';

  @override
  String get locationServiceDisabled =>
      'Location services are turned off on your device.';

  @override
  String get locationInsecure =>
      'Browsers only share location over a secure (https) connection.';

  @override
  String get locationUnavailable =>
      'Your location couldn\'t be determined right now.';

  @override
  String get mapLoadError =>
      'The map couldn\'t be loaded. Check your internet connection.';

  @override
  String get pickOnMap => 'Choose on map';

  @override
  String get pickOnMapHint =>
      'Move the map to put the pin where you want to go';

  @override
  String get moveMapToPick =>
      'Move the map to place the pin on your destination';

  @override
  String get selectThisPoint => 'Choose This Point';

  @override
  String get pinnedLocation => 'Pinned location';

  @override
  String get recentPlaces => 'Recent places';

  @override
  String get searchFailed =>
      'Address search failed. Check your internet connection.';

  @override
  String get searchNoResults =>
      'No results. Try a different spelling or choose on the map.';

  @override
  String get calculatingRoute => 'Calculating route...';

  @override
  String get finishCurrentRideFirst => 'Finish your current ride first.';

  @override
  String approximateRoute(String summary) {
    return 'Approx. $summary';
  }

  @override
  String get taxiEconomy => 'Economy';

  @override
  String get taxiComfort => 'Comfort';

  @override
  String get taxiXl => 'XL';

  @override
  String pickupIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min away',
      one: '1 min away',
    );
    return '$_temp0';
  }

  @override
  String get fareDisclaimer =>
      'Prices are estimates and may vary with traffic and waiting time.';

  @override
  String get paymentMethod => 'Payment method';

  @override
  String get paymentCash => 'Cash';

  @override
  String get paymentCard => 'Card';

  @override
  String get when => 'When?';

  @override
  String get now => 'Now';

  @override
  String get later => 'Schedule';

  @override
  String scheduleTooSoon(int minutes) {
    return 'Rides can be scheduled at least $minutes minutes ahead.';
  }

  @override
  String get callTaxi => 'CALL TAXI';

  @override
  String get reserveTaxi => 'BOOK RIDE';

  @override
  String rideScheduled(String when) {
    return 'Your ride is booked for $when. See it under My Trips > Upcoming.';
  }

  @override
  String get searchingTaxi => 'Looking for a taxi...';

  @override
  String get searchingTaxiHint => 'Matching you with nearby drivers';

  @override
  String driverOnTheWay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Your driver is about $count min away',
      one: 'Your driver is about 1 min away',
    );
    return '$_temp0';
  }

  @override
  String get driverArrived =>
      'Your driver is here! Check the plate before getting in.';

  @override
  String plateLabel(String plate) {
    return 'Plate $plate';
  }

  @override
  String get carWhite => 'White';

  @override
  String get carSilver => 'Silver';

  @override
  String get carBlack => 'Black';

  @override
  String get message => 'Message';

  @override
  String get call => 'Call';

  @override
  String get startRideDemo => 'START RIDE (DEMO)';

  @override
  String get cancelRide => 'Cancel Ride';

  @override
  String get cancelRideTitle => 'Cancel this ride?';

  @override
  String get cancelRideMessage =>
      'Your driver is already on the way. If you cancel, the ride is added to Cancelled.';

  @override
  String get tripInProgress => 'Your ride is in progress';

  @override
  String get arrivedAtDestination => 'You\'ve arrived';

  @override
  String minutesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min left',
      one: '1 min left',
    );
    return '$_temp0';
  }

  @override
  String get completeRide => 'COMPLETE';

  @override
  String get finishDemo => 'FINISH (DEMO)';

  @override
  String get safetyTools => 'Safety';

  @override
  String get shareTrip => 'Share my trip';

  @override
  String get shareTripHint =>
      'Sends the driver, plate, arrival time and a live location link to someone you trust; the link stops when the trip ends';

  @override
  String shareTripText(String driver, String plate, String car,
      String destination, String arrival, String link) {
    return 'I\'m on a KKTC Taksim ride.\nDriver: $driver\nPlate: $plate – $car\nGoing to: $destination, arriving around $arrival\nCurrent location: $link';
  }

  @override
  String shareTripLiveText(String driver, String plate, String car,
      String destination, String arrival, String link) {
    return 'I\'m on a KKTC Taksim ride.\nDriver: $driver\nPlate: $plate – $car\nGoing to: $destination, arriving around $arrival\nFollow me live (until the trip ends): $link';
  }

  @override
  String get tripDetailsCopied =>
      'Trip details copied; you can paste them into a message.';

  @override
  String get emergencyCall => 'Emergency call';

  @override
  String get police => 'Police';

  @override
  String get ambulance => 'Ambulance';

  @override
  String get fireDepartment => 'Fire brigade';

  @override
  String get tripCompleted => 'Ride Completed';

  @override
  String totalAmount(String amount) {
    return 'Total: $amount';
  }

  @override
  String get howWasTrip => 'How was your ride?';

  @override
  String starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get submitRating => 'Submit Rating';

  @override
  String get tabUpcoming => 'Upcoming';

  @override
  String get tabPast => 'Past';

  @override
  String get tabCancelled => 'Cancelled';

  @override
  String get noUpcomingTrips => 'No upcoming rides';

  @override
  String get noUpcomingTripsHint =>
      'Choose \"Schedule\" when calling a taxi to plan a ride.';

  @override
  String get noPastTrips => 'No completed rides yet';

  @override
  String get noCancelledTrips => 'No cancelled rides';

  @override
  String get callTaxiShort => 'Call a Taxi';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String get cancelReservation => 'Cancel';

  @override
  String get cancelReservationTitle => 'Cancel this booking?';

  @override
  String cancelReservationMessage(String when) {
    return 'Your ride on $when will be cancelled.';
  }

  @override
  String get sharedRides => 'Shared Rides';

  @override
  String get howItWorks => 'How does it work?';

  @override
  String get sharedRidesInfo =>
      'You share a van (Vito) with passengers going the same way. The price on the card is per person; everyone pays their own share. The ride starts at the departure time.';

  @override
  String get sharedPromoTitle => 'Ride together,\npay less.';

  @override
  String get sharedPromoSubtitle =>
      'Split the cost with people going your way.';

  @override
  String get activeGroups => 'Active Groups';

  @override
  String get noActiveGroups =>
      'No active groups right now. Be the first to create one!';

  @override
  String get createGroup => 'Create Group';

  @override
  String get perPerson => 'per person';

  @override
  String peopleCount(int current, int capacity) {
    return '$current / $capacity people';
  }

  @override
  String seatsLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count seats left',
      one: '1 seat left',
    );
    return '$_temp0';
  }

  @override
  String get full => 'Full';

  @override
  String get join => 'Join';

  @override
  String joinedGroup(String from, String to) {
    return 'You joined the $from → $to group.';
  }

  @override
  String get leaveGroup => 'Leave';

  @override
  String get leaveGroupTitle => 'Leave this group?';

  @override
  String leaveGroupMessage(String from, String to) {
    return 'Your seat in the $from → $to group will be released.';
  }

  @override
  String get leftGroup => 'You left the group.';

  @override
  String get createRide => 'Create a Ride';

  @override
  String stepOf(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get fromQuestion => 'From where?';

  @override
  String get toQuestion => 'To where?';

  @override
  String get startPoint => 'Starting point';

  @override
  String get endPoint => 'Destination';

  @override
  String get rideDetails => 'Date, Time and Price';

  @override
  String get rideDate => 'Date';

  @override
  String get rideTime => 'Time';

  @override
  String get departureInPast => 'Departure time can\'t be in the past.';

  @override
  String vitoCapacity(int count) {
    return 'Van capacity: $count';
  }

  @override
  String get pricePerPersonLabel => 'Price per person';

  @override
  String get pricePerPersonHelp => 'The amount each passenger pays';

  @override
  String pricePerPersonInvalid(String max) {
    return 'Enter an amount between 1 and $max';
  }

  @override
  String get createRideButton => 'Create Ride';

  @override
  String get exploreSearchHint => 'What are you looking for nearby?';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryRestaurant => 'Restaurants';

  @override
  String get categoryCafe => 'Cafés';

  @override
  String get categoryHotel => 'Hotels';

  @override
  String get categoryEntertainment => 'Fun';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHistoric => 'Historic Sites';

  @override
  String get popularPlaces => 'Popular Places';

  @override
  String get noPlacesFound => 'No places match your search';

  @override
  String discountBadge(int percent) {
    return '$percent% Off';
  }

  @override
  String get callTaxiHere => 'Taxi here';

  @override
  String get personalInfo => 'Personal Details';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get paymentMethods => 'Payment Methods';

  @override
  String get notifications => 'Notifications';

  @override
  String get campaigns => 'Offers';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Phone language';

  @override
  String get logout => 'Log Out';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUseTitle => 'Terms of Use';

  @override
  String get deleteAccount => 'Delete My Account';

  @override
  String get deleteAccountMessage =>
      'Your account and all your data (profile, trip history, group memberships and messages, location shares) will be permanently deleted. This can\'t be undone. To continue, we\'ll send a verification code to your phone.';

  @override
  String get accountDeleted => 'Your account and data have been deleted.';

  @override
  String get deleteAccountFailed =>
      'Couldn\'t delete your account. Check your internet connection and try again.';

  @override
  String get logoutMessage => 'Are you sure you want to log out?';

  @override
  String get greetingNoName => 'Hi 👋';

  @override
  String get authInvalidCode => 'Wrong code. Please check the code in the SMS.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Please wait a bit and try again.';

  @override
  String get networkError =>
      'You seem to be offline. Check your internet connection.';

  @override
  String get actionFailed => 'That didn\'t work. Please try again.';

  @override
  String actionFailedWithCode(String code) {
    return 'That didn\'t work ($code). Please try again.';
  }

  @override
  String get signInRequiredForGroups =>
      'You need to sign in to create or join a group.';

  @override
  String get signIn => 'Sign in';

  @override
  String get loadError => 'Couldn\'t load the data.';

  @override
  String get noDriverFound =>
      'No taxi is available right now. Please try again shortly.';

  @override
  String get groupFull => 'This group is full.';

  @override
  String get groupChat => 'Group chat';

  @override
  String groupChatTitle(String from, String to) {
    return '$from → $to';
  }

  @override
  String get chatEmpty =>
      'No messages yet. Write the first one to agree on a meeting point and time!';

  @override
  String get chatPrivacyNote =>
      'Your phone number isn\'t shown to the group; only your name is.';

  @override
  String get locationOutsideServiceArea =>
      'You\'re outside the service area (North Cyprus).';

  @override
  String get chatRulesNote =>
      'Long-press a message to report it or block the sender.';

  @override
  String get reportMessage => 'Report';

  @override
  String get reportReasonTitle => 'Reason for report';

  @override
  String get reasonSpam => 'Spam or advertising';

  @override
  String get reasonHarassment => 'Insults or harassment';

  @override
  String get reasonInappropriate => 'Inappropriate content';

  @override
  String get reasonOther => 'Other';

  @override
  String get reportSent => 'Thanks, your report has been sent for review.';

  @override
  String get blockUser => 'Block this person';

  @override
  String blockUserTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockUserMessage =>
      'You won\'t see this person\'s messages anymore. Long-press a hidden message to unblock.';

  @override
  String userBlocked(String name) {
    return '$name has been blocked.';
  }

  @override
  String get unblockUser => 'Unblock';

  @override
  String get unblockUserMessage =>
      'This person\'s messages will be shown again.';

  @override
  String get userUnblocked => 'Unblocked.';

  @override
  String get blockedMessage => 'Message from someone you blocked';

  @override
  String get messageHint => 'Write a message…';

  @override
  String get sendMessage => 'Send';

  @override
  String get unnamedPassenger => 'Passenger';

  @override
  String get newMessages => 'New messages';

  @override
  String get notGroupMember => 'You\'re not a member of this group.';

  @override
  String get switchToPassenger => 'Switch to passenger';

  @override
  String get switchToDriver => 'Switch to driver mode';

  @override
  String get driverMode => 'Driver';

  @override
  String get driverRegisterTitle => 'Driver sign-up';

  @override
  String get driverRegisterSubtitle =>
      'Passengers will see your name, plate and car.';

  @override
  String get driverNameLabel => 'Full name';

  @override
  String get plateFieldLabel => 'Plate';

  @override
  String get carModelLabel => 'Car (make, model)';

  @override
  String get carColorLabel => 'Car colour';

  @override
  String get saveDriver => 'Finish sign-up';

  @override
  String get driverOnline => 'You\'re online';

  @override
  String get driverOffline => 'You\'re offline';

  @override
  String get driverPendingTitle => 'Your application is being reviewed';

  @override
  String get driverPendingHint =>
      'Once your plate and car details are checked you can receive requests. This screen updates by itself when you are approved.';

  @override
  String get driverOfflineHint =>
      'Go online to receive requests. Your location is shared while the app is open.';

  @override
  String get noOpenRequests =>
      'No requests right now. New requests will appear here.';

  @override
  String get openRequests => 'Open requests';

  @override
  String get acceptRide => 'Accept';

  @override
  String get rideTaken => 'Another driver already took this request.';

  @override
  String get driverNeedsLocation =>
      'Location is needed to go online and receive requests.';

  @override
  String get headToPickup => 'Go to the passenger';

  @override
  String get waitingPassenger => 'Pick up the passenger';

  @override
  String get tripInProgressDriver => 'Trip in progress';

  @override
  String get iArrived => 'I\'ve arrived';

  @override
  String get startTrip => 'Start trip';

  @override
  String get finishTrip => 'Finish trip';

  @override
  String get cancelRideDriver => 'Cancel request';

  @override
  String get cancelRideDriverMessage =>
      'The passenger\'s request will be cancelled.';

  @override
  String get navigate => 'Directions';

  @override
  String get openInGoogleMaps => 'Open in Google Maps';

  @override
  String remainingToPickup(String distance, String duration) {
    return 'To passenger $distance • $duration';
  }

  @override
  String remainingToDestination(String distance, String duration) {
    return 'To destination $distance • $duration';
  }

  @override
  String get rideFinishedDriver => 'Trip completed.';

  @override
  String pickupDistance(String distance) {
    return 'Passenger $distance away';
  }

  @override
  String get assistantTitle => 'AI assistant';

  @override
  String get assistantTooltip => 'Where should I go?';

  @override
  String get assistantIntro =>
      'Suggests places to go based on where you are and the time of day.';

  @override
  String get assistantHint => 'E.g. a quiet coffee place';

  @override
  String get assistantChipNearby => 'What to do nearby?';

  @override
  String get assistantChipDinner => 'Dinner';

  @override
  String get assistantChipNature => 'Nature and sea';

  @override
  String get assistantThinking => 'Thinking…';

  @override
  String get assistantNoResults =>
      'I couldn\'t find a suitable place for that. Try asking differently.';

  @override
  String get assistantFailed =>
      'The assistant is unavailable right now. Please try again shortly.';

  @override
  String get assistantLimit =>
      'You\'ve used today\'s questions. You can ask again tomorrow.';

  @override
  String get assistantDisclaimer =>
      'Suggestions come from AI and may be wrong. Check opening hours.';

  @override
  String get assistantConsentTitle => 'Sharing with AI';

  @override
  String get assistantConsentBody =>
      'Your questions and your approximate area (not your exact location) are sent to an AI service to generate suggestions. Continue?';

  @override
  String get assistantConsentAccept => 'Continue';

  @override
  String get assistantCallTaxi => 'Call a taxi';
}
