// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Smart Heritage';

  @override
  String get navScan => 'Quét mã QR hoặc beacon';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navExplore => 'Khám phá';

  @override
  String get navMap => 'Bản đồ';

  @override
  String get navFavorites => 'Yêu thích';

  @override
  String get navProfile => 'Cá nhân';

  @override
  String get navPlaylist => 'Danh sách nghe';

  @override
  String get navNotifications => 'Thông báo';

  @override
  String get inboxTitle => 'Thông báo';

  @override
  String get inboxMarkAllRead => 'Đánh dấu tất cả đã đọc';

  @override
  String get inboxEmpty =>
      'Chưa có thông báo nào. Tin tức và sự kiện mới từ ban quản lý sẽ hiện ở đây.';

  @override
  String get inboxLoginTitle => 'Đăng nhập để nhận thông báo';

  @override
  String get inboxLoginMessage =>
      'Tin tức và sự kiện mới từ ban quản lý sẽ được gửi tới bạn sau khi đăng nhập.';

  @override
  String get inboxNew => 'Mới';

  @override
  String get playlistTitle => 'Danh sách nghe';

  @override
  String playlistSummary(int count) {
    return '$count bản thuyết minh';
  }

  @override
  String get playlistPlayAll => 'Phát tất cả';

  @override
  String get playlistEmpty => 'Chưa có hiện vật nào có thuyết minh.';

  @override
  String get playerNext => 'Bài tiếp theo';

  @override
  String get playerPrevious => 'Bài trước';

  @override
  String get playerNarrationMuted => 'Thuyết minh · đã tắt tiếng';

  @override
  String get playerNarration => 'Thuyết minh âm thanh';

  @override
  String get playerUnmute => 'Bật tiếng';

  @override
  String get playerMute => 'Tắt tiếng';

  @override
  String get scanSheetTitle => 'Nhận diện hiện vật';

  @override
  String get scanQrTitle => 'Quét mã QR';

  @override
  String get scanQrSubtitle => 'Quét mã trên bảng giới thiệu cạnh hiện vật';

  @override
  String get scanBeaconTitle => 'Quét beacon';

  @override
  String get scanBeaconActive =>
      'Đang quét — app tự giới thiệu hiện vật khi bạn đến gần';

  @override
  String get scanBeaconIdle => 'Tự nhận hiện vật khi bạn đứng gần beacon';

  @override
  String get artifactImageComingSoon => 'Ảnh cập nhật sau';

  @override
  String get saveFailedRetry => 'Không lưu được thay đổi, vui lòng thử lại.';

  @override
  String get favoriteRemoved => 'Đã xoá khỏi danh sách yêu thích';

  @override
  String get favoriteAdded => 'Đã lưu vào danh sách yêu thích';

  @override
  String get seeAll => 'Xem tất cả';

  @override
  String get splashTagline => 'Trợ lý du lịch số cho khu di tích';

  @override
  String homeGreeting(String name) {
    return 'Xin chào, $name';
  }

  @override
  String get homeScanning => 'Đang quét';

  @override
  String get homeHistory => 'Lịch sử';

  @override
  String get homeFeedback => 'Góp ý';

  @override
  String get homeHelp => 'Trợ giúp';

  @override
  String get homeAccount => 'Tài khoản';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get accountInfoTitle => 'Thông tin tài khoản';

  @override
  String get accountNotSet => 'Chưa cập nhật';

  @override
  String get accountLoginTitle => 'Đăng nhập để xem thông tin tài khoản';

  @override
  String get homeFeatured => 'Nổi bật';

  @override
  String get homeNews => 'Tin tức';

  @override
  String get homeRecentVisits => 'Tham quan gần đây';

  @override
  String get homeOffline =>
      'Chưa kết nối được máy chủ — đang xem dữ liệu sẵn có.';

  @override
  String get retry => 'Thử lại';

  @override
  String get homeOfficialApp => 'Ứng dụng chính thức';

  @override
  String get homeAbout => 'Giới thiệu';

  @override
  String get aboutTagline => 'Người bạn đồng hành khi tham quan di sản';

  @override
  String get aboutIntroHeading => 'Về Smart Heritage';

  @override
  String get aboutIntroBody =>
      'Smart Heritage là ứng dụng hướng dẫn tham quan bảo tàng và khu di tích. Ứng dụng kể lại câu chuyện của từng hiện vật bằng hình ảnh, bài viết và thuyết minh âm thanh, giúp bạn tự khám phá theo nhịp của mình mà không cần chờ hướng dẫn viên.\n\nKhi bạn đến gần một hiện vật có gắn thiết bị iBeacon, ứng dụng tự nhận ra và mở phần giới thiệu, phát thuyết minh ngay tại chỗ. Mọi nội dung đều do ban quản lý khu di tích biên soạn và cập nhật.';

  @override
  String get aboutFeaturesHeading => 'Bạn có thể làm gì';

  @override
  String get aboutFeatureDiscover =>
      'Xem thông tin, hình ảnh và đánh giá của từng hiện vật.';

  @override
  String get aboutFeatureListen =>
      'Nghe thuyết minh âm thanh bằng nhiều ngôn ngữ, hoặc nghe lần lượt cả danh sách.';

  @override
  String get aboutFeatureScan =>
      'Quét mã QR trên bảng giới thiệu, hoặc bật quét iBeacon để ứng dụng tự nhận diện hiện vật gần bạn.';

  @override
  String get aboutFeatureMap =>
      'Xem bản đồ các địa điểm, sơ đồ từng tầng và khu vực trưng bày.';

  @override
  String get aboutFeatureNews =>
      'Nhận tin tức, sự kiện mới từ ban quản lý và lưu lại lịch sử tham quan của bạn.';

  @override
  String get aboutHowHeading => 'Bắt đầu thế nào';

  @override
  String get aboutHowBody =>
      'Đăng nhập để mở khoá thuyết minh, quét hiện vật và thông báo. Sau đó bấm nút quét ở giữa thanh điều hướng khi đứng trước hiện vật, hoặc mở Danh sách nghe để nghe trước ở nhà. Hãy bật Bluetooth và cho phép truy cập vị trí để tính năng iBeacon hoạt động.';

  @override
  String aboutVersion(String version) {
    return 'Phiên bản $version';
  }

  @override
  String get homeHeroSubtitle => 'Đến gần hiện vật, thuyết minh tự phát';

  @override
  String get langNameVi => 'Tiếng Việt';

  @override
  String get langNameEn => 'Tiếng Anh';

  @override
  String get langNameFr => 'Tiếng Pháp';

  @override
  String get langNameJa => 'Tiếng Nhật';

  @override
  String get langNameKo => 'Tiếng Hàn';

  @override
  String get langNameZh => 'Tiếng Trung';

  @override
  String get langScreenTitle => 'Chọn ngôn ngữ';

  @override
  String get langScreenIntro =>
      'Giao diện, nội dung giới thiệu, thuyết minh âm thanh và phụ đề video sẽ hiển thị theo ngôn ngữ bạn chọn.';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get langUpdated => 'Đã cập nhật ngôn ngữ hiển thị';

  @override
  String get langSavedLocalOnly =>
      'Đã đổi ngôn ngữ trên máy này nhưng chưa lưu được vào tài khoản.';

  @override
  String langUiFallbackNotice(String language) {
    return 'Giao diện app chưa có bản $language nên tạm hiển thị bằng tiếng Anh. Nội dung hiện vật vẫn theo $language khi có.';
  }

  @override
  String get mapPlacesTitle => 'Địa điểm tham quan';

  @override
  String mapAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count khu vực',
      zero: 'Chưa có khu vực',
    );
    return '$_temp0';
  }

  @override
  String mapArtifactCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hiện vật',
    );
    return '$_temp0';
  }

  @override
  String get mapNotPinned => 'chưa có vị trí trên bản đồ';

  @override
  String get mapScreenTitle => 'Bản đồ tham quan';

  @override
  String mapYouAreAt(String place) {
    return 'Bạn đang ở $place';
  }

  @override
  String get mapPlacesList => 'Danh sách địa điểm';

  @override
  String get mapNoPinnedPlaces =>
      'Chưa có địa điểm nào được đặt vị trí trên bản đồ. Chọn một địa điểm để xem các khu vực.';

  @override
  String mapYouAreHereWith(String details) {
    return 'Bạn đang ở đây · $details';
  }

  @override
  String get close => 'Đóng';

  @override
  String get mapViewAreas => 'Xem các khu vực';

  @override
  String get mapAllArtifacts => 'Tất cả hiện vật';

  @override
  String get mapPickArea => 'Chọn một khu vực để xem bản đồ';

  @override
  String get mapPickFloor => 'Chọn tầng để xem sơ đồ khu vực';

  @override
  String get mapOtherAreas => 'Khu vực khác';

  @override
  String get mapFloorPlan => 'Sơ đồ tầng';

  @override
  String get mapOnThisFloor => 'Bạn đang ở tầng này';

  @override
  String get mapNoArtifacts => 'Chưa có hiện vật';

  @override
  String get mapYouAreHere => 'Bạn đang ở đây';

  @override
  String get mapFloorNoPlan => 'Tầng này chưa có sơ đồ';

  @override
  String get mapPickAreaBelow =>
      'Chọn một khu vực bên dưới để xem bản đồ của nó.';

  @override
  String get mapFloorPlanLoadFailed => 'Không tải được sơ đồ tầng';

  @override
  String get mapFloorNoAreas => 'Tầng này chưa có khu vực nào.';

  @override
  String get mapPlanLoadFailed => 'Không tải được sơ đồ.';

  @override
  String get mapAttractionNoPlan => 'Điểm tham quan này chưa có sơ đồ tầng.';

  @override
  String get crowdQuiet => 'Đang vắng khách';

  @override
  String crowdAroundHere(int count) {
    return '~$count khách quanh đây';
  }

  @override
  String crowdAroundZone(int count, String zone) {
    return '~$count khách quanh khu vực $zone';
  }

  @override
  String crowdHere(int count) {
    return '~$count khách đang ở đây';
  }

  @override
  String crowdInArea(int count) {
    return '~$count khách đang ở khu này';
  }

  @override
  String get locationServiceOff =>
      'Vui lòng bật GPS/Vị trí trên thiết bị rồi thử lại.';

  @override
  String get locationDeniedForever =>
      'Quyền vị trí đang bị chặn. Hãy bật lại trong Cài đặt của máy.';

  @override
  String get locationNeeded =>
      'Ứng dụng cần quyền vị trí để định vị bạn trên bản đồ.';

  @override
  String get mapNoLocationTitle => 'Chưa có vị trí trên bản đồ';

  @override
  String get mapNoLocationText =>
      'Điểm tham quan này chưa có hiện vật hay beacon nào được đặt toạ độ.';

  @override
  String mapYouAreInZone(String zone) {
    return 'Bạn đang ở khu vực $zone';
  }

  @override
  String mapDistanceFromYou(String zone, String distance) {
    return '$zone · cách bạn ~$distance';
  }

  @override
  String get mapDirections => 'Chỉ đường';

  @override
  String get details => 'Chi tiết';

  @override
  String get mapNotReadyTitle => 'Bản đồ chưa sẵn sàng';

  @override
  String get mapNotReadyText =>
      'Bản build này chưa có token Mapbox. Chạy lại với --dart-define-from-file=mapbox.local.json.';

  @override
  String get artifactTabIntro => 'Giới thiệu';

  @override
  String get artifactTabPhotos => 'Hình ảnh';

  @override
  String get artifactTabVideo => 'Video';

  @override
  String get artifactTabReviews => 'Đánh giá';

  @override
  String get artifactSavedOffline =>
      'Nội dung đã được lưu — bạn có thể tiếp tục xem kể cả khi rời khỏi vùng phủ sóng beacon.';

  @override
  String get artifactOverview => 'Giới thiệu chung';

  @override
  String get artifactListen => 'Nghe thuyết minh âm thanh';

  @override
  String artifactNoLanguage(String language) {
    return 'Hiện vật này chưa có bản $language';
  }

  @override
  String get artifactNoLanguageText =>
      'Phần giới thiệu và thuyết minh âm thanh chưa được soạn cho ngôn ngữ bạn đang chọn. Hãy chọn ngôn ngữ khác để xem.';

  @override
  String get changeLanguage => 'Đổi ngôn ngữ';

  @override
  String artifactPhotoPlaceholder(int index, int total) {
    return 'Ảnh $index/$total';
  }

  @override
  String videoNarration(String name) {
    return 'Thuyết minh: $name';
  }

  @override
  String get videoDocumentary => 'Phim tư liệu: quá trình phát hiện và bảo tồn';

  @override
  String get videoSubtitles => 'Video có phụ đề tiếng Việt và tiếng Anh';

  @override
  String get audioViewArtifact => 'Xem chi tiết hiện vật';

  @override
  String get audioNoRecording => 'Hiện vật này chưa có bản thuyết minh.';

  @override
  String get audioLoading => 'Đang tải bản thuyết minh…';

  @override
  String get audioLanguage => 'Ngôn ngữ thuyết minh';

  @override
  String get share => 'Chia sẻ';

  @override
  String get audioTranscript => 'Nội dung thuyết minh';

  @override
  String get audioLinkCopied => 'Đã sao chép liên kết hiện vật';

  @override
  String get back => 'Quay lại';

  @override
  String get newsUnavailable =>
      'Bài viết này không còn hoặc chưa có bản cho ngôn ngữ bạn chọn.';

  @override
  String get newsLoadFailed => 'Không tải được nội dung bài viết.';

  @override
  String get newsEmpty => 'Bài viết chưa có nội dung.';

  @override
  String get reviewTagContentGood => 'Nội dung hấp dẫn';

  @override
  String get reviewTagNarrationClear => 'Thuyết minh rõ ràng';

  @override
  String get reviewTagWayfindingEasy => 'Dễ tìm vị trí';

  @override
  String get reviewTagImagesGood => 'Hình ảnh đẹp';

  @override
  String get reviewTagLanguagesMissing => 'Cần thêm ngôn ngữ';

  @override
  String get reviewTagAudioPoor => 'Âm thanh chưa tốt';

  @override
  String get feedbackTitle => 'Đánh giá & phản hồi';

  @override
  String get rating1 => 'Rất tệ';

  @override
  String get rating2 => 'Chưa hài lòng';

  @override
  String get rating3 => 'Bình thường';

  @override
  String get rating4 => 'Hài lòng';

  @override
  String get rating5 => 'Tuyệt vời';

  @override
  String get feedbackPickRating => 'Vui lòng chọn số sao đánh giá';

  @override
  String get feedbackThanks => 'Cảm ơn bạn! Phản hồi đã được gửi thành công.';

  @override
  String get feedbackHowWasVisit =>
      'Trải nghiệm tham quan của bạn hôm nay thế nào?';

  @override
  String get feedbackWhatImpressed => 'Điều gì khiến bạn ấn tượng?';

  @override
  String get feedbackTellUsMore => 'Chia sẻ thêm với chúng tôi';

  @override
  String get feedbackHint =>
      'Cảm nhận, góp ý của bạn giúp chúng tôi phục vụ tốt hơn...';

  @override
  String get feedbackAttachPhoto => 'Đính kèm hình ảnh';

  @override
  String get feedbackSend => 'Gửi phản hồi';

  @override
  String get reviewsLoadFailed => 'Chưa tải được danh sách đánh giá.';

  @override
  String get reviewsEmpty => 'Chưa có đánh giá nào. Hãy là người đầu tiên!';

  @override
  String reviewsHeader(int count) {
    return 'Đánh giá của khách tham quan ($count)';
  }

  @override
  String get qrNotOurs => 'Mã QR này không phải mã hiện vật của SmartHeritage.';

  @override
  String get qrTorch => 'Đèn pin';

  @override
  String get qrAimHint => 'Đưa mã QR trên bảng giới thiệu hiện vật vào khung';

  @override
  String get qrCameraDenied =>
      'Ứng dụng chưa được dùng camera. Hãy bật quyền Camera cho SmartHeritage trong Cài đặt của máy.';

  @override
  String get qrCameraFailed =>
      'Không mở được camera. Thử đóng màn này rồi mở lại.';

  @override
  String get beaconSearching => 'Đang dò beacon quanh bạn…';

  @override
  String get beaconTapToStart => 'Chạm để bắt đầu quét';

  @override
  String get beaconScanningHint =>
      'Hãy đứng gần hiện vật. Bắt được beacon là app tự giới thiệu hiện vật đó — bạn có thể rời trang này, app vẫn quét tiếp.';

  @override
  String get beaconIdleHint =>
      'App dùng Bluetooth để nhận tín hiệu beacon đặt cạnh hiện vật.';

  @override
  String get beaconStop => 'Tắt quét';

  @override
  String get beaconTurnOff => 'Tắt quét beacon';

  @override
  String get beaconTurnOn => 'Bật quét beacon';

  @override
  String beaconStartFailed(String detail) {
    return 'Không khởi động được bộ quét beacon ($detail).';
  }

  @override
  String get beaconLocationServiceOff =>
      'Hãy bật Dịch vụ định vị trong Cài đặt để quét beacon.';

  @override
  String get beaconLocationNeeded =>
      'Ứng dụng cần quyền vị trí để nhận tín hiệu beacon. Hãy bật trong Cài đặt.';

  @override
  String get beaconGpsOffAndroid =>
      'Hãy bật Dịch vụ vị trí (GPS) — Android cần nó để quét beacon.';

  @override
  String get beaconNotReady => 'Chưa khởi động được bộ quét beacon.';

  @override
  String get bluetoothOff => 'Hãy bật Bluetooth để quét beacon.';

  @override
  String get bluetoothUnauthorized =>
      'Ứng dụng chưa được phép dùng Bluetooth. Hãy bật trong Cài đặt.';

  @override
  String get bluetoothUnsupported =>
      'Thiết bị này không hỗ trợ Bluetooth Low Energy.';

  @override
  String get bluetoothNotReady =>
      'Bluetooth chưa sẵn sàng. Hãy thử bật quét lại.';

  @override
  String get beaconDetectedVia => 'Phát hiện qua iBeacon · cách bạn ~2m';

  @override
  String get beaconLater => 'Để sau';

  @override
  String get beaconExploreNow => 'Khám phá ngay';

  @override
  String get beaconAudioMuted => 'Thuyết minh đang tắt tiếng';

  @override
  String get beaconAudioPlaying => 'Đang phát thuyết minh âm thanh';

  @override
  String get beaconAudioLogin => 'Đăng nhập để nghe thuyết minh';

  @override
  String beaconChoiceTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Có $count hiện vật quanh đây',
    );
    return '$_temp0';
  }

  @override
  String get beaconChoiceMessage =>
      'Chọn hiện vật bạn muốn xem và nghe thuyết minh.';

  @override
  String get beaconChoiceHasAudio => 'Có thuyết minh';

  @override
  String get favTitle => 'Hiện vật yêu thích';

  @override
  String get favLoginTitle => 'Đăng nhập để lưu yêu thích';

  @override
  String get favLoginMessage =>
      'Đăng nhập để lưu và đồng bộ các hiện vật\nyêu thích của bạn trên mọi thiết bị';

  @override
  String get favEmptyTitle => 'Chưa có hiện vật yêu thích';

  @override
  String get favEmptyMessage =>
      'Nhấn ♥ trên hiện vật để lưu lại\nvà xem lại bất cứ lúc nào';

  @override
  String get loginOrRegister => 'Đăng nhập / Đăng ký';

  @override
  String get historyTitle => 'Lịch sử tham quan';

  @override
  String historyDetectedAt(String time) {
    return 'iBeacon phát hiện lúc $time';
  }

  @override
  String get historyClearTitle => 'Xoá lịch sử';

  @override
  String get historyClearAccount =>
      'Xoá toàn bộ lịch sử tham quan của tài khoản này?';

  @override
  String get historyClearDevice =>
      'Xoá toàn bộ lịch sử tham quan trên thiết bị này?';

  @override
  String get cancel => 'Huỷ';

  @override
  String get delete => 'Xoá';

  @override
  String get historyStatArtifacts => 'Hiện vật đã xem';

  @override
  String get historyStatDays => 'Ngày tham quan';

  @override
  String get historyStatAreas => 'Khu đã ghé';

  @override
  String get historyEmptyTitle => 'Chưa có lịch sử tham quan';

  @override
  String get historyEmptyMessage =>
      'Khi bạn đến gần một hiện vật, iBeacon sẽ\ntự động ghi lại vào đây';

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get audioPlayFailed => 'Không phát được bản thuyết minh.';

  @override
  String get profileTitle => 'Tài khoản của tôi';

  @override
  String get profileSectionPersonal => 'Cá nhân';

  @override
  String get profileEdit => 'Chỉnh sửa thông tin cá nhân';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get profileSectionDevice => 'Thiết bị';

  @override
  String get profileSectionSupport => 'Hỗ trợ';

  @override
  String get profileRateSite => 'Đánh giá khu di tích';

  @override
  String get profileNotifications => 'Thông báo';

  @override
  String get profileHelpFaq => 'Trợ giúp & câu hỏi thường gặp';

  @override
  String get profileAbout => 'Về ứng dụng';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get profileBadge => 'Nhà thám hiểm di sản';

  @override
  String get profileGuestTitle => 'Tham quan có tài khoản riêng';

  @override
  String get login => 'Đăng nhập';

  @override
  String get register => 'Đăng ký';

  @override
  String get profileBeaconScan => 'Quét iBeacon';

  @override
  String get profileScanOff => 'Đang tắt';

  @override
  String get logoutConfirm => 'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?';

  @override
  String get loggedOut => 'Đã đăng xuất';

  @override
  String get editProfileSaved => 'Đã cập nhật thông tin cá nhân';

  @override
  String get editProfileTitle => 'Chỉnh sửa thông tin';

  @override
  String get fieldFullName => 'Họ và tên';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPhone => 'Số điện thoại';

  @override
  String get fieldGender => 'Giới tính';

  @override
  String get genderMale => 'Nam';

  @override
  String get genderFemale => 'Nữ';

  @override
  String get genderOther => 'Khác';

  @override
  String get saveChanges => 'Lưu thay đổi';

  @override
  String get loginSuccess => 'Đăng nhập thành công';

  @override
  String get googleSignInFailed =>
      'Không đăng nhập được bằng Google. Vui lòng thử lại.';

  @override
  String get googleAccountRejected =>
      'Tài khoản Google này không dùng được (email chưa xác minh hoặc tài khoản đã bị khoá).';

  @override
  String get googleLoginDisabled => 'Máy chủ chưa bật đăng nhập Google.';

  @override
  String get loginWelcome => 'Chào mừng trở lại!';

  @override
  String get loginSubtitle =>
      'Đăng nhập để đồng bộ lịch sử tham quan\nvà cá nhân hoá trải nghiệm của bạn';

  @override
  String get invalidEmail => 'Vui lòng nhập email hợp lệ';

  @override
  String get fieldPassword => 'Mật khẩu';

  @override
  String get passwordTooShort => 'Mật khẩu tối thiểu 8 ký tự';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get orContinueWith => 'hoặc tiếp tục với';

  @override
  String get continueWithGoogle => 'Tiếp tục với Google';

  @override
  String get noAccount => 'Chưa có tài khoản? ';

  @override
  String get registerNow => 'Đăng ký ngay';

  @override
  String get agreeTermsRequired => 'Vui lòng đồng ý với điều khoản sử dụng';

  @override
  String get registerSuccess => 'Tạo tài khoản thành công';

  @override
  String get registerTitle => 'Tạo tài khoản';

  @override
  String get registerSubtitle =>
      'Bắt đầu hành trình khám phá di sản cùng chúng tôi';

  @override
  String get nameRequired => 'Vui lòng nhập họ tên';

  @override
  String get invalidPhone => 'Số điện thoại không hợp lệ';

  @override
  String get agreePrefix => 'Tôi đồng ý với ';

  @override
  String get termsOfUse => 'Điều khoản sử dụng';

  @override
  String get agreeAnd => ' và ';

  @override
  String get privacyPolicy => 'Chính sách bảo mật';

  @override
  String get haveAccount => 'Đã có tài khoản? ';

  @override
  String get guest => 'Khách';

  @override
  String get invalidServerData => 'Máy chủ trả về dữ liệu không hợp lệ.';

  @override
  String get serverTimeout => 'Máy chủ phản hồi quá lâu.';

  @override
  String get serverUnreachable => 'Không kết nối được máy chủ.';

  @override
  String get error400 => 'Dữ liệu gửi lên không hợp lệ.';

  @override
  String get error401 => 'Phiên đăng nhập đã hết hạn.';

  @override
  String get error403 => 'Bạn không có quyền thực hiện thao tác này.';

  @override
  String get error404 => 'Không tìm thấy dữ liệu.';

  @override
  String errorServer(int status) {
    return 'Máy chủ gặp sự cố ($status).';
  }

  @override
  String get helpGroup1 => 'iBeacon & phát hiện hiện vật';

  @override
  String get helpGroup2 => 'Thuyết minh âm thanh';

  @override
  String get helpGroup3 => 'Tài khoản';

  @override
  String get helpGroup4 => 'Bản đồ & vị trí';

  @override
  String get helpGroup5 => 'Thông báo & phản hồi';

  @override
  String get helpQ1 => 'iBeacon là gì và app dùng nó để làm gì?';

  @override
  String get helpA1 =>
      'Mỗi khu trưng bày được gắn một thiết bị iBeacon phát sóng Bluetooth tầm ngắn. Khi bạn đi tới gần, ứng dụng nhận được sóng và tự nhận ra bạn đang ở cạnh hiện vật nào, rồi mở phần giới thiệu tương ứng. Bạn không phải quét mã hay nhập số hiệu hiện vật.';

  @override
  String get helpQ2 => 'Bật tính năng quét ở đâu?';

  @override
  String get helpA2 =>
      'Mở sidebar bằng nút menu ở góc trên bên trái trang Khám phá, rồi bật công tắc \"Quét iBeacon\". Công tắc này áp dụng cho toàn ứng dụng, tắt lúc nào cũng được.';

  @override
  String get helpQ3 => 'Vì sao app không phát hiện được hiện vật nào?';

  @override
  String get helpA3 =>
      'Hãy kiểm tra theo thứ tự: đã bật công tắc \"Quét iBeacon\" trong sidebar chưa, Bluetooth của máy đã mở chưa, và ứng dụng đã được cấp quyền Bluetooth trong phần cài đặt của hệ điều hành chưa. Sóng iBeacon chỉ phủ vài mét, nên bạn cũng cần đứng gần khu trưng bày.';

  @override
  String get helpQ4 => 'Quét iBeacon có tốn pin nhiều không?';

  @override
  String get helpA4 =>
      'iBeacon dùng Bluetooth Low Energy, tiêu thụ pin rất thấp so với GPS hay 4G. Dù vậy, nếu bạn đã tham quan xong thì nên tắt công tắc trong sidebar để tiết kiệm thêm.';

  @override
  String get helpQ5 => 'Thuyết minh có tự phát không?';

  @override
  String get helpA5 =>
      'Có. Khi iBeacon phát hiện bạn ở gần một hiện vật, ứng dụng tự mở và phát thuyết minh của hiện vật đó, bạn không cần bấm gì. Nếu muốn nghe lại hoặc nghe hiện vật khác, vào trang chi tiết hiện vật và bấm \"Nghe thuyết minh âm thanh\" ở cuối tab Giới thiệu.';

  @override
  String get helpQ6 => 'Làm sao tắt tiếng khi đang ở nơi cần yên lặng?';

  @override
  String get helpA6 =>
      'Bấm nút hình loa. Nút này có ở ba nơi: thanh phát nhỏ phía dưới màn hình, khung thông báo khi beacon phát hiện hiện vật, và trang nghe thuyết minh. Tắt tiếng chỉ làm im âm thanh, phần thuyết minh vẫn chạy và bạn vẫn đọc được nội dung chữ.';

  @override
  String get helpQ7 => 'Đổi tốc độ đọc được không?';

  @override
  String get helpA7 =>
      'Được. Ở trang nghe thuyết minh, bấm nút tốc độ bên phải hàng điều khiển để chuyển lần lượt qua 0.75×, 1×, 1.25× và 1.5×.';

  @override
  String get helpQ8 => 'Đổi ngôn ngữ thuyết minh ở đâu?';

  @override
  String get helpA8 =>
      'Có hai đường: nút hình chữ dịch ở trang nghe thuyết minh, hoặc vào Tài khoản của tôi → Ngôn ngữ. Sidebar cũng có mục Ngôn ngữ.';

  @override
  String get helpQ9 => 'Đi ra xa hiện vật thì còn xem được nội dung không?';

  @override
  String get helpA9 =>
      'Còn. Nội dung đã tải sẽ tiếp tục xem được kể cả khi bạn ra ngoài vùng phủ sóng beacon, nên có thể đọc lại sau khi rời khu trưng bày.';

  @override
  String get helpQ10 => 'Có bắt buộc đăng nhập mới dùng được không?';

  @override
  String get helpA10 =>
      'Không. Khách tham quan xem được toàn bộ hiện vật, bản đồ, thuyết minh và nhận thông báo mà không cần tài khoản.';

  @override
  String get helpQ11 => 'Vậy đăng nhập để làm gì?';

  @override
  String get helpA11 =>
      'Để lưu danh sách hiện vật yêu thích và đồng bộ dữ liệu của bạn giữa các thiết bị. Lịch sử tham quan thì vẫn được lưu trên máy ngay cả khi bạn chưa đăng nhập.';

  @override
  String get helpQ12 => 'Đăng nhập và đăng ký ở đâu?';

  @override
  String get helpA12 =>
      'Vào Tài khoản của tôi, dùng hai nút \"Đăng nhập\" và \"Đăng ký\" ở đầu trang. Sidebar cũng có lối vào tương tự.';

  @override
  String get helpQ13 => 'Bản đồ trống, không thấy gì cả?';

  @override
  String get helpA13 =>
      'Bản đồ cần kết nối mạng để tải nền. Hãy kiểm tra Wi-Fi hoặc dữ liệu di động. Các ghim hiện vật vẫn hiện đúng vị trí dù nền bản đồ chưa tải xong.';

  @override
  String get helpQ14 => 'Vì sao app xin quyền vị trí?';

  @override
  String get helpA14 =>
      'Chỉ để hiển thị chấm vị trí của bạn trên bản đồ khu di tích, giúp bạn biết mình đang ở đâu so với các hiện vật. Từ chối quyền này thì bản đồ và ghim hiện vật vẫn dùng bình thường.';

  @override
  String get helpQ15 => 'Lọc hiện vật theo khu trưng bày được không?';

  @override
  String get helpA15 =>
      'Được. Ở tab Bản đồ có dải nút chọn khu vực phía trên; chọn một khu thì bản đồ chỉ hiện ghim của khu đó.';

  @override
  String get helpQ16 => 'Xem lại thông báo đã nhận ở đâu?';

  @override
  String get helpA16 =>
      'Bấm nút hình chuông ở góc trên bên phải trang Khám phá. Con số đỏ trên chuông là số thông báo chưa đọc.';

  @override
  String get helpQ17 =>
      'Tôi muốn đánh giá một hiện vật hoặc góp ý về khu di tích.';

  @override
  String get helpA17 =>
      'Với từng hiện vật: mở trang chi tiết rồi vào tab \"Đánh giá\". Với góp ý chung về khu di tích: vào Tài khoản của tôi → Đánh giá khu di tích.';

  @override
  String get helpTitle => 'Trợ giúp & FAQ';

  @override
  String get helpStillStuck => 'Vẫn chưa tìm được câu trả lời?';

  @override
  String get helpContactText =>
      'Liên hệ ban quản lý khu di tích, hoặc gửi phản hồi trực tiếp trong ứng dụng.';

  @override
  String get helpEmailCopied => 'Đã sao chép email hỗ trợ';

  @override
  String get helpPhoneCopied => 'Đã sao chép số hỗ trợ';

  @override
  String get completePhoneTitle => 'Thêm số điện thoại';

  @override
  String get completePhoneSubtitle =>
      'Tài khoản Google chưa có số điện thoại. Vui lòng nhập số điện thoại để hoàn tất đăng nhập.';

  @override
  String get completePhoneSubmit => 'Hoàn tất';

  @override
  String get completePhoneUseOtherAccount => 'Dùng tài khoản khác';
}
