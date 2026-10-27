// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Heritage';

  @override
  String get navScan => 'Scan a QR code or beacon';

  @override
  String get navHome => 'Home';

  @override
  String get navExplore => 'Explore';

  @override
  String get navMap => 'Map';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navProfile => 'Profile';

  @override
  String get navPlaylist => 'Playlist';

  @override
  String get navNotifications => 'Notifications';

  @override
  String get inboxTitle => 'Notifications';

  @override
  String get inboxMarkAllRead => 'Mark all as read';

  @override
  String get inboxEmpty =>
      'No notifications yet. News and events from the site will appear here.';

  @override
  String get inboxLoginTitle => 'Sign in to get notifications';

  @override
  String get inboxLoginMessage =>
      'News and events from the site will be sent to you once you sign in.';

  @override
  String get inboxNew => 'New';

  @override
  String get playlistTitle => 'Playlist';

  @override
  String playlistSummary(int count) {
    return '$count narrations';
  }

  @override
  String get playlistPlayAll => 'Play all';

  @override
  String get playlistEmpty => 'No artifacts have narration yet.';

  @override
  String get playerNext => 'Next';

  @override
  String get playerPrevious => 'Previous';

  @override
  String get playerNarrationMuted => 'Audio guide · muted';

  @override
  String get playerNarration => 'Audio guide';

  @override
  String get playerUnmute => 'Unmute';

  @override
  String get playerMute => 'Mute';

  @override
  String get scanSheetTitle => 'Identify an artifact';

  @override
  String get scanQrTitle => 'Scan QR code';

  @override
  String get scanQrSubtitle => 'Scan the code on the sign next to the artifact';

  @override
  String get scanBeaconTitle => 'Scan beacons';

  @override
  String get scanBeaconActive =>
      'Scanning — the app introduces artifacts as you get close';

  @override
  String get scanBeaconIdle =>
      'Recognize artifacts automatically when you stand near a beacon';

  @override
  String get artifactImageComingSoon => 'Photo coming soon';

  @override
  String get saveFailedRetry => 'Couldn\'t save your change. Please try again.';

  @override
  String get favoriteRemoved => 'Removed from favorites';

  @override
  String get favoriteAdded => 'Saved to favorites';

  @override
  String get seeAll => 'See all';

  @override
  String get splashTagline => 'Your digital guide to heritage sites';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get homeScanning => 'Scanning';

  @override
  String get homeHistory => 'History';

  @override
  String get homeFeedback => 'Feedback';

  @override
  String get homeHelp => 'Help';

  @override
  String get homeAccount => 'Account';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get accountInfoTitle => 'Account information';

  @override
  String get accountNotSet => 'Not set';

  @override
  String get accountLoginTitle => 'Sign in to see your account details';

  @override
  String get homeFeatured => 'Featured';

  @override
  String get homeNews => 'News';

  @override
  String get homeRecentVisits => 'Recently visited';

  @override
  String get homeOffline => 'Can\'t reach the server — showing saved data.';

  @override
  String get retry => 'Try again';

  @override
  String get homeOfficialApp => 'Official app';

  @override
  String get homeAbout => 'About';

  @override
  String get aboutTagline => 'Your companion for heritage visits';

  @override
  String get aboutIntroHeading => 'About Smart Heritage';

  @override
  String get aboutIntroBody =>
      'Smart Heritage is a visitor guide for museums and heritage sites. It tells the story of each artifact through photos, articles and audio narration, so you can explore at your own pace without waiting for a tour guide.\n\nWhen you approach an artifact fitted with an iBeacon, the app recognises it, opens its introduction and plays the narration right there. All content is written and kept up to date by the site\'s management team.';

  @override
  String get aboutFeaturesHeading => 'What you can do';

  @override
  String get aboutFeatureDiscover =>
      'Read about each artifact, browse its photos and reviews.';

  @override
  String get aboutFeatureListen =>
      'Listen to audio narration in several languages, or play the whole list in order.';

  @override
  String get aboutFeatureScan =>
      'Scan the QR code on an information panel, or turn on iBeacon scanning to recognise artifacts near you.';

  @override
  String get aboutFeatureMap =>
      'See a map of the sites, floor plans and exhibition areas.';

  @override
  String get aboutFeatureNews =>
      'Get news and events from the site and keep a history of your visits.';

  @override
  String get aboutHowHeading => 'Getting started';

  @override
  String get aboutHowBody =>
      'Sign in to unlock narration, scanning and notifications. Then tap the scan button in the middle of the navigation bar when you stand in front of an artifact, or open the Playlist to listen ahead at home. Turn on Bluetooth and allow location access for iBeacon to work.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get homeHeroSubtitle =>
      'Walk up to an artifact and its audio guide plays';

  @override
  String get langNameVi => 'Vietnamese';

  @override
  String get langNameEn => 'English';

  @override
  String get langNameFr => 'French';

  @override
  String get langNameJa => 'Japanese';

  @override
  String get langNameKo => 'Korean';

  @override
  String get langNameZh => 'Chinese';

  @override
  String get langScreenTitle => 'Choose language';

  @override
  String get langScreenIntro =>
      'The interface, artifact descriptions, audio guides and video subtitles will use the language you choose.';

  @override
  String get confirm => 'Confirm';

  @override
  String get langUpdated => 'Display language updated';

  @override
  String get langSavedLocalOnly =>
      'Language changed on this device, but it couldn\'t be saved to your account.';

  @override
  String langUiFallbackNotice(String language) {
    return 'The app interface isn\'t available in $language yet, so it\'s shown in English. Artifact content still uses $language where available.';
  }

  @override
  String get mapPlacesTitle => 'Places to visit';

  @override
  String mapAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count areas',
      one: '1 area',
      zero: 'No areas yet',
    );
    return '$_temp0';
  }

  @override
  String mapArtifactCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artifacts',
      one: '1 artifact',
    );
    return '$_temp0';
  }

  @override
  String get mapNotPinned => 'not on the map yet';

  @override
  String get mapScreenTitle => 'Visitor map';

  @override
  String mapYouAreAt(String place) {
    return 'You\'re at $place';
  }

  @override
  String get mapPlacesList => 'List of places';

  @override
  String get mapNoPinnedPlaces =>
      'No places have been placed on the map yet. Pick a place to see its areas.';

  @override
  String mapYouAreHereWith(String details) {
    return 'You\'re here · $details';
  }

  @override
  String get close => 'Close';

  @override
  String get mapViewAreas => 'View areas';

  @override
  String get mapAllArtifacts => 'All artifacts';

  @override
  String get mapPickArea => 'Pick an area to see its map';

  @override
  String get mapPickFloor => 'Pick a floor to see its area plan';

  @override
  String get mapOtherAreas => 'Other areas';

  @override
  String get mapFloorPlan => 'Floor plan';

  @override
  String get mapOnThisFloor => 'You\'re on this floor';

  @override
  String get mapNoArtifacts => 'No artifacts yet';

  @override
  String get mapYouAreHere => 'You\'re here';

  @override
  String get mapFloorNoPlan => 'This floor has no plan yet';

  @override
  String get mapPickAreaBelow => 'Pick an area below to see its map.';

  @override
  String get mapFloorPlanLoadFailed => 'Couldn\'t load the floor plan';

  @override
  String get mapFloorNoAreas => 'This floor has no areas yet.';

  @override
  String get mapPlanLoadFailed => 'Couldn\'t load the plan.';

  @override
  String get mapAttractionNoPlan => 'This area has no floor plan yet.';

  @override
  String get crowdQuiet => 'Quiet right now';

  @override
  String crowdAroundHere(int count) {
    return '~$count visitors around here';
  }

  @override
  String crowdAroundZone(int count, String zone) {
    return '~$count visitors around $zone';
  }

  @override
  String crowdHere(int count) {
    return '~$count visitors here';
  }

  @override
  String crowdInArea(int count) {
    return '~$count visitors in this area';
  }

  @override
  String get locationServiceOff =>
      'Please turn on GPS/Location on your device and try again.';

  @override
  String get locationDeniedForever =>
      'Location access is blocked. Turn it back on in your device Settings.';

  @override
  String get locationNeeded =>
      'The app needs location access to show you on the map.';

  @override
  String get mapNoLocationTitle => 'Not on the map yet';

  @override
  String get mapNoLocationText =>
      'No artifacts or beacons in this area have been placed on the map yet.';

  @override
  String mapYouAreInZone(String zone) {
    return 'You\'re in the $zone area';
  }

  @override
  String mapDistanceFromYou(String zone, String distance) {
    return '$zone · ~$distance away';
  }

  @override
  String get mapDirections => 'Directions';

  @override
  String get details => 'Details';

  @override
  String get mapNotReadyTitle => 'Map not available';

  @override
  String get mapNotReadyText =>
      'This build has no Mapbox token. Run again with --dart-define-from-file=mapbox.local.json.';

  @override
  String get artifactTabIntro => 'About';

  @override
  String get artifactTabPhotos => 'Photos';

  @override
  String get artifactTabVideo => 'Video';

  @override
  String get artifactTabReviews => 'Reviews';

  @override
  String get artifactSavedOffline =>
      'Content is saved — you can keep reading even after leaving the beacon\'s range.';

  @override
  String get artifactOverview => 'Overview';

  @override
  String get artifactListen => 'Listen to the audio guide';

  @override
  String artifactNoLanguage(String language) {
    return 'This artifact isn\'t available in $language yet';
  }

  @override
  String get artifactNoLanguageText =>
      'The description and audio guide haven\'t been written in your chosen language yet. Choose another language to view them.';

  @override
  String get changeLanguage => 'Change language';

  @override
  String artifactPhotoPlaceholder(int index, int total) {
    return 'Photo $index/$total';
  }

  @override
  String videoNarration(String name) {
    return 'Audio guide: $name';
  }

  @override
  String get videoDocumentary => 'Documentary: discovery and conservation';

  @override
  String get videoSubtitles => 'Videos have Vietnamese and English subtitles';

  @override
  String get audioViewArtifact => 'View artifact details';

  @override
  String get audioNoRecording => 'This artifact has no audio guide yet.';

  @override
  String get audioLoading => 'Loading the audio guide…';

  @override
  String get audioLanguage => 'Audio guide language';

  @override
  String get share => 'Share';

  @override
  String get audioTranscript => 'Transcript';

  @override
  String get audioLinkCopied => 'Artifact link copied';

  @override
  String get back => 'Back';

  @override
  String get newsUnavailable =>
      'This article is no longer available or hasn\'t been published in your language.';

  @override
  String get newsLoadFailed => 'Couldn\'t load the article.';

  @override
  String get newsEmpty => 'This article has no content yet.';

  @override
  String get reviewTagContentGood => 'Engaging content';

  @override
  String get reviewTagNarrationClear => 'Clear narration';

  @override
  String get reviewTagWayfindingEasy => 'Easy to find';

  @override
  String get reviewTagImagesGood => 'Great photos';

  @override
  String get reviewTagLanguagesMissing => 'Needs more languages';

  @override
  String get reviewTagAudioPoor => 'Audio could be better';

  @override
  String get feedbackTitle => 'Reviews & feedback';

  @override
  String get rating1 => 'Very poor';

  @override
  String get rating2 => 'Not satisfied';

  @override
  String get rating3 => 'Okay';

  @override
  String get rating4 => 'Satisfied';

  @override
  String get rating5 => 'Excellent';

  @override
  String get feedbackPickRating => 'Please choose a star rating';

  @override
  String get feedbackThanks => 'Thank you! Your feedback has been sent.';

  @override
  String get feedbackHowWasVisit => 'How was your visit today?';

  @override
  String get feedbackWhatImpressed => 'What stood out to you?';

  @override
  String get feedbackTellUsMore => 'Tell us more';

  @override
  String get feedbackHint =>
      'Your thoughts and suggestions help us do better...';

  @override
  String get feedbackAttachPhoto => 'Attach a photo';

  @override
  String get feedbackSend => 'Send feedback';

  @override
  String get reviewsLoadFailed => 'Couldn\'t load reviews.';

  @override
  String get reviewsEmpty => 'No reviews yet. Be the first!';

  @override
  String reviewsHeader(int count) {
    return 'Visitor reviews ($count)';
  }

  @override
  String get qrNotOurs => 'This QR code isn\'t a SmartHeritage artifact code.';

  @override
  String get qrTorch => 'Flashlight';

  @override
  String get qrAimHint =>
      'Fit the QR code from the artifact\'s sign inside the frame';

  @override
  String get qrCameraDenied =>
      'The app doesn\'t have camera access. Turn on Camera for SmartHeritage in your device Settings.';

  @override
  String get qrCameraFailed =>
      'Couldn\'t open the camera. Close this screen and try again.';

  @override
  String get beaconSearching => 'Looking for beacons around you…';

  @override
  String get beaconTapToStart => 'Tap to start scanning';

  @override
  String get beaconScanningHint =>
      'Stand near an artifact. When a beacon is detected, the app introduces that artifact — you can leave this page and scanning continues.';

  @override
  String get beaconIdleHint =>
      'The app uses Bluetooth to pick up beacons placed next to artifacts.';

  @override
  String get beaconStop => 'Stop scanning';

  @override
  String get beaconTurnOff => 'Turn off beacon scanning';

  @override
  String get beaconTurnOn => 'Turn on beacon scanning';

  @override
  String beaconStartFailed(String detail) {
    return 'Couldn\'t start the beacon scanner ($detail).';
  }

  @override
  String get beaconLocationServiceOff =>
      'Turn on Location Services in Settings to scan for beacons.';

  @override
  String get beaconLocationNeeded =>
      'The app needs location access to detect beacons. Turn it on in Settings.';

  @override
  String get beaconGpsOffAndroid =>
      'Turn on Location (GPS) — Android needs it to scan for beacons.';

  @override
  String get beaconNotReady => 'The beacon scanner couldn\'t start.';

  @override
  String get bluetoothOff => 'Turn on Bluetooth to scan for beacons.';

  @override
  String get bluetoothUnauthorized =>
      'The app isn\'t allowed to use Bluetooth. Turn it on in Settings.';

  @override
  String get bluetoothUnsupported =>
      'This device doesn\'t support Bluetooth Low Energy.';

  @override
  String get bluetoothNotReady =>
      'Bluetooth isn\'t ready. Try turning scanning on again.';

  @override
  String get beaconDetectedVia => 'Detected via iBeacon · ~2 m away';

  @override
  String get beaconLater => 'Later';

  @override
  String get beaconExploreNow => 'Explore now';

  @override
  String get beaconAudioMuted => 'Audio guide is muted';

  @override
  String get beaconAudioPlaying => 'Playing the audio guide';

  @override
  String get beaconAudioLogin => 'Sign in to listen to the narration';

  @override
  String beaconChoiceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artifacts nearby',
      one: '1 artifact nearby',
    );
    return '$_temp0';
  }

  @override
  String get beaconChoiceMessage =>
      'Choose an artifact to view and listen to its audio guide.';

  @override
  String get beaconChoiceHasAudio => 'Audio guide';

  @override
  String get favTitle => 'Favorite artifacts';

  @override
  String get favLoginTitle => 'Log in to save favorites';

  @override
  String get favLoginMessage =>
      'Log in to save and sync your favorite\nartifacts across all your devices';

  @override
  String get favEmptyTitle => 'No favorites yet';

  @override
  String get favEmptyMessage =>
      'Tap ♥ on an artifact to save it\nand come back to it anytime';

  @override
  String get loginOrRegister => 'Log in / Sign up';

  @override
  String get historyTitle => 'Visit history';

  @override
  String historyDetectedAt(String time) {
    return 'Detected by iBeacon at $time';
  }

  @override
  String get historyClearTitle => 'Clear history';

  @override
  String get historyClearAccount =>
      'Clear the entire visit history for this account?';

  @override
  String get historyClearDevice =>
      'Clear the entire visit history on this device?';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get historyStatArtifacts => 'Artifacts seen';

  @override
  String get historyStatDays => 'Visit days';

  @override
  String get historyStatAreas => 'Areas visited';

  @override
  String get historyEmptyTitle => 'No visits yet';

  @override
  String get historyEmptyMessage =>
      'When you get close to an artifact, iBeacon\nrecords it here automatically';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get audioPlayFailed => 'Couldn\'t play the audio guide.';

  @override
  String get profileTitle => 'My account';

  @override
  String get profileSectionPersonal => 'Personal';

  @override
  String get profileEdit => 'Edit personal details';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileSectionDevice => 'Device';

  @override
  String get profileSectionSupport => 'Support';

  @override
  String get profileRateSite => 'Rate this heritage site';

  @override
  String get profileNotifications => 'Notifications';

  @override
  String get profileHelpFaq => 'Help & FAQ';

  @override
  String get profileAbout => 'About the app';

  @override
  String get logout => 'Log out';

  @override
  String get profileBadge => 'Heritage explorer';

  @override
  String get profileGuestTitle => 'Visit with your own account';

  @override
  String get login => 'Log in';

  @override
  String get register => 'Sign up';

  @override
  String get profileBeaconScan => 'iBeacon scanning';

  @override
  String get profileScanOff => 'Off';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get loggedOut => 'Logged out';

  @override
  String get editProfileSaved => 'Personal details updated';

  @override
  String get editProfileTitle => 'Edit details';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPhone => 'Phone number';

  @override
  String get fieldGender => 'Gender';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get loginSuccess => 'Logged in';

  @override
  String get googleSignInFailed =>
      'Couldn\'t sign in with Google. Please try again.';

  @override
  String get googleAccountRejected =>
      'This Google account can\'t be used (email not verified or account disabled).';

  @override
  String get googleLoginDisabled =>
      'Google sign-in isn\'t enabled on the server.';

  @override
  String get loginWelcome => 'Welcome back!';

  @override
  String get loginSubtitle =>
      'Log in to sync your visit history\nand personalize your experience';

  @override
  String get invalidEmail => 'Please enter a valid email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orContinueWith => 'or continue with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get noAccount => 'Don\'t have an account? ';

  @override
  String get registerNow => 'Sign up now';

  @override
  String get agreeTermsRequired => 'Please accept the terms of use';

  @override
  String get registerSuccess => 'Account created';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Start your heritage journey with us';

  @override
  String get nameRequired => 'Please enter your full name';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get agreePrefix => 'I agree to the ';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get agreeAnd => ' and ';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get guest => 'Guest';

  @override
  String get invalidServerData => 'The server returned invalid data.';

  @override
  String get serverTimeout => 'The server took too long to respond.';

  @override
  String get serverUnreachable => 'Can\'t connect to the server.';

  @override
  String get error400 => 'The request was invalid.';

  @override
  String get error401 => 'Your session has expired.';

  @override
  String get error403 => 'You don\'t have permission to do this.';

  @override
  String get error404 => 'Not found.';

  @override
  String errorServer(int status) {
    return 'Server error ($status).';
  }

  @override
  String get helpGroup1 => 'iBeacon & artifact detection';

  @override
  String get helpGroup2 => 'Audio guide';

  @override
  String get helpGroup3 => 'Account';

  @override
  String get helpGroup4 => 'Map & location';

  @override
  String get helpGroup5 => 'Notifications & feedback';

  @override
  String get helpQ1 => 'What is iBeacon and what does the app use it for?';

  @override
  String get helpA1 =>
      'Each exhibition area has an iBeacon device that sends a short-range Bluetooth signal. When you get close, the app picks up the signal, works out which artifact you\'re next to, and opens its introduction. You don\'t need to scan a code or type in an artifact number.';

  @override
  String get helpQ2 => 'Where do I turn on scanning?';

  @override
  String get helpA2 =>
      'Open the sidebar with the menu button in the top-left corner of the Explore page, then turn on the \"iBeacon scanning\" switch. The switch applies to the whole app and you can turn it off at any time.';

  @override
  String get helpQ3 => 'Why isn\'t the app detecting any artifacts?';

  @override
  String get helpA3 =>
      'Check in this order: is the \"iBeacon scanning\" switch in the sidebar on, is your phone\'s Bluetooth on, and has the app been given Bluetooth permission in your system settings? iBeacon signals only reach a few meters, so you also need to stand near the exhibit.';

  @override
  String get helpQ4 => 'Does iBeacon scanning use a lot of battery?';

  @override
  String get helpA4 =>
      'iBeacon uses Bluetooth Low Energy, which uses very little battery compared to GPS or 4G. Still, once you\'ve finished your visit, turn the switch off in the sidebar to save even more.';

  @override
  String get helpQ5 => 'Does the audio guide play automatically?';

  @override
  String get helpA5 =>
      'Yes. When iBeacon detects that you\'re near an artifact, the app opens and plays that artifact\'s audio guide — you don\'t need to tap anything. To listen again or hear another artifact, open the artifact\'s page and tap \"Listen to the audio guide\" at the bottom of the About tab.';

  @override
  String get helpQ6 => 'How do I mute it somewhere I need to be quiet?';

  @override
  String get helpA6 =>
      'Tap the speaker button. It\'s in three places: the mini player at the bottom of the screen, the pop-up shown when a beacon detects an artifact, and the audio guide page. Muting only silences the sound — the guide keeps running and you can still read the text.';

  @override
  String get helpQ7 => 'Can I change the playback speed?';

  @override
  String get helpA7 =>
      'Yes. On the audio guide page, tap the speed button on the right of the controls to cycle through 0.75×, 1×, 1.25× and 1.5×.';

  @override
  String get helpQ8 => 'Where do I change the audio guide language?';

  @override
  String get helpA8 =>
      'Two ways: the translate button on the audio guide page, or My account → Language. The sidebar also has a Language item.';

  @override
  String get helpQ9 =>
      'Can I still read the content after walking away from the artifact?';

  @override
  String get helpA9 =>
      'Yes. Loaded content stays available even after you leave the beacon\'s range, so you can read it again after leaving the exhibition area.';

  @override
  String get helpQ10 => 'Do I have to log in to use the app?';

  @override
  String get helpA10 =>
      'No. Visitors can see all artifacts, the map, audio guides and notifications without an account.';

  @override
  String get helpQ11 => 'So what is logging in for?';

  @override
  String get helpA11 =>
      'To save your favorite artifacts and sync your data across devices. Your visit history is still saved on your phone even if you haven\'t logged in.';

  @override
  String get helpQ12 => 'Where do I log in or sign up?';

  @override
  String get helpA12 =>
      'Go to My account and use the \"Log in\" and \"Sign up\" buttons at the top of the page. The sidebar has the same shortcuts.';

  @override
  String get helpQ13 => 'The map is blank — I can\'t see anything?';

  @override
  String get helpA13 =>
      'The map needs an internet connection to load its background. Check your Wi-Fi or mobile data. Artifact pins still show in the right places even before the map background has loaded.';

  @override
  String get helpQ14 => 'Why does the app ask for my location?';

  @override
  String get helpA14 =>
      'Only to show your position on the heritage site map, so you know where you are relative to the artifacts. If you decline, the map and artifact pins still work normally.';

  @override
  String get helpQ15 => 'Can I filter artifacts by exhibition area?';

  @override
  String get helpA15 =>
      'Yes. On the Map tab there is a row of area buttons at the top; pick an area and the map only shows that area\'s pins.';

  @override
  String get helpQ16 => 'Where can I see notifications I\'ve received?';

  @override
  String get helpA16 =>
      'Tap the bell in the top-right corner of the Explore page. The red number on the bell is how many notifications you haven\'t read.';

  @override
  String get helpQ17 =>
      'I want to rate an artifact or give feedback about the site.';

  @override
  String get helpA17 =>
      'For an artifact: open its page and go to the \"Reviews\" tab. For general feedback about the site: go to My account → Rate this heritage site.';

  @override
  String get helpTitle => 'Help & FAQ';

  @override
  String get helpStillStuck => 'Still can\'t find an answer?';

  @override
  String get helpContactText =>
      'Contact the site\'s management team, or send feedback directly in the app.';

  @override
  String get helpEmailCopied => 'Support email copied';

  @override
  String get helpPhoneCopied => 'Support phone number copied';

  @override
  String get completePhoneTitle => 'Add your phone number';

  @override
  String get completePhoneSubtitle =>
      'Your Google account doesn\'t have a phone number. Please enter one to finish signing in.';

  @override
  String get completePhoneSubmit => 'Finish';

  @override
  String get completePhoneUseOtherAccount => 'Use another account';
}
