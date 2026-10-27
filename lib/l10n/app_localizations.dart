import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Tên app
  ///
  /// In vi, this message translates to:
  /// **'Smart Heritage'**
  String get appTitle;

  /// No description provided for @navScan.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR hoặc beacon'**
  String get navScan;

  /// No description provided for @navHome.
  ///
  /// In vi, this message translates to:
  /// **'Trang chủ'**
  String get navHome;

  /// No description provided for @navExplore.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá'**
  String get navExplore;

  /// No description provided for @navMap.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ'**
  String get navMap;

  /// No description provided for @navFavorites.
  ///
  /// In vi, this message translates to:
  /// **'Yêu thích'**
  String get navFavorites;

  /// No description provided for @navProfile.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get navProfile;

  /// No description provided for @navPlaylist.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách nghe'**
  String get navPlaylist;

  /// No description provided for @navNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get navNotifications;

  /// No description provided for @inboxTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get inboxTitle;

  /// No description provided for @inboxMarkAllRead.
  ///
  /// In vi, this message translates to:
  /// **'Đánh dấu tất cả đã đọc'**
  String get inboxMarkAllRead;

  /// No description provided for @inboxEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thông báo nào. Tin tức và sự kiện mới từ ban quản lý sẽ hiện ở đây.'**
  String get inboxEmpty;

  /// No description provided for @inboxLoginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để nhận thông báo'**
  String get inboxLoginTitle;

  /// No description provided for @inboxLoginMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tin tức và sự kiện mới từ ban quản lý sẽ được gửi tới bạn sau khi đăng nhập.'**
  String get inboxLoginMessage;

  /// No description provided for @inboxNew.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get inboxNew;

  /// No description provided for @playlistTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách nghe'**
  String get playlistTitle;

  /// No description provided for @playlistSummary.
  ///
  /// In vi, this message translates to:
  /// **'{count} bản thuyết minh'**
  String playlistSummary(int count);

  /// No description provided for @playlistPlayAll.
  ///
  /// In vi, this message translates to:
  /// **'Phát tất cả'**
  String get playlistPlayAll;

  /// No description provided for @playlistEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hiện vật nào có thuyết minh.'**
  String get playlistEmpty;

  /// No description provided for @playerNext.
  ///
  /// In vi, this message translates to:
  /// **'Bài tiếp theo'**
  String get playerNext;

  /// No description provided for @playerPrevious.
  ///
  /// In vi, this message translates to:
  /// **'Bài trước'**
  String get playerPrevious;

  /// No description provided for @playerNarrationMuted.
  ///
  /// In vi, this message translates to:
  /// **'Thuyết minh · đã tắt tiếng'**
  String get playerNarrationMuted;

  /// No description provided for @playerNarration.
  ///
  /// In vi, this message translates to:
  /// **'Thuyết minh âm thanh'**
  String get playerNarration;

  /// No description provided for @playerUnmute.
  ///
  /// In vi, this message translates to:
  /// **'Bật tiếng'**
  String get playerUnmute;

  /// No description provided for @playerMute.
  ///
  /// In vi, this message translates to:
  /// **'Tắt tiếng'**
  String get playerMute;

  /// No description provided for @scanSheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận diện hiện vật'**
  String get scanSheetTitle;

  /// No description provided for @scanQrTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get scanQrTitle;

  /// No description provided for @scanQrSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã trên bảng giới thiệu cạnh hiện vật'**
  String get scanQrSubtitle;

  /// No description provided for @scanBeaconTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét beacon'**
  String get scanBeaconTitle;

  /// No description provided for @scanBeaconActive.
  ///
  /// In vi, this message translates to:
  /// **'Đang quét — app tự giới thiệu hiện vật khi bạn đến gần'**
  String get scanBeaconActive;

  /// No description provided for @scanBeaconIdle.
  ///
  /// In vi, this message translates to:
  /// **'Tự nhận hiện vật khi bạn đứng gần beacon'**
  String get scanBeaconIdle;

  /// No description provided for @artifactImageComingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh cập nhật sau'**
  String get artifactImageComingSoon;

  /// No description provided for @saveFailedRetry.
  ///
  /// In vi, this message translates to:
  /// **'Không lưu được thay đổi, vui lòng thử lại.'**
  String get saveFailedRetry;

  /// No description provided for @favoriteRemoved.
  ///
  /// In vi, this message translates to:
  /// **'Đã xoá khỏi danh sách yêu thích'**
  String get favoriteRemoved;

  /// No description provided for @favoriteAdded.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu vào danh sách yêu thích'**
  String get favoriteAdded;

  /// No description provided for @seeAll.
  ///
  /// In vi, this message translates to:
  /// **'Xem tất cả'**
  String get seeAll;

  /// No description provided for @splashTagline.
  ///
  /// In vi, this message translates to:
  /// **'Trợ lý du lịch số cho khu di tích'**
  String get splashTagline;

  /// No description provided for @homeGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào, {name}'**
  String homeGreeting(String name);

  /// No description provided for @homeScanning.
  ///
  /// In vi, this message translates to:
  /// **'Đang quét'**
  String get homeScanning;

  /// No description provided for @homeHistory.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử'**
  String get homeHistory;

  /// No description provided for @homeFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Góp ý'**
  String get homeFeedback;

  /// No description provided for @homeHelp.
  ///
  /// In vi, this message translates to:
  /// **'Trợ giúp'**
  String get homeHelp;

  /// No description provided for @homeAccount.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get homeAccount;

  /// No description provided for @settingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsTitle;

  /// No description provided for @accountInfoTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin tài khoản'**
  String get accountInfoTitle;

  /// No description provided for @accountNotSet.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cập nhật'**
  String get accountNotSet;

  /// No description provided for @accountLoginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để xem thông tin tài khoản'**
  String get accountLoginTitle;

  /// No description provided for @homeFeatured.
  ///
  /// In vi, this message translates to:
  /// **'Nổi bật'**
  String get homeFeatured;

  /// No description provided for @homeNews.
  ///
  /// In vi, this message translates to:
  /// **'Tin tức'**
  String get homeNews;

  /// No description provided for @homeRecentVisits.
  ///
  /// In vi, this message translates to:
  /// **'Tham quan gần đây'**
  String get homeRecentVisits;

  /// No description provided for @homeOffline.
  ///
  /// In vi, this message translates to:
  /// **'Chưa kết nối được máy chủ — đang xem dữ liệu sẵn có.'**
  String get homeOffline;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @homeOfficialApp.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng chính thức'**
  String get homeOfficialApp;

  /// No description provided for @homeAbout.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get homeAbout;

  /// No description provided for @aboutTagline.
  ///
  /// In vi, this message translates to:
  /// **'Người bạn đồng hành khi tham quan di sản'**
  String get aboutTagline;

  /// No description provided for @aboutIntroHeading.
  ///
  /// In vi, this message translates to:
  /// **'Về Smart Heritage'**
  String get aboutIntroHeading;

  /// No description provided for @aboutIntroBody.
  ///
  /// In vi, this message translates to:
  /// **'Smart Heritage là ứng dụng hướng dẫn tham quan bảo tàng và khu di tích. Ứng dụng kể lại câu chuyện của từng hiện vật bằng hình ảnh, bài viết và thuyết minh âm thanh, giúp bạn tự khám phá theo nhịp của mình mà không cần chờ hướng dẫn viên.\n\nKhi bạn đến gần một hiện vật có gắn thiết bị iBeacon, ứng dụng tự nhận ra và mở phần giới thiệu, phát thuyết minh ngay tại chỗ. Mọi nội dung đều do ban quản lý khu di tích biên soạn và cập nhật.'**
  String get aboutIntroBody;

  /// No description provided for @aboutFeaturesHeading.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có thể làm gì'**
  String get aboutFeaturesHeading;

  /// No description provided for @aboutFeatureDiscover.
  ///
  /// In vi, this message translates to:
  /// **'Xem thông tin, hình ảnh và đánh giá của từng hiện vật.'**
  String get aboutFeatureDiscover;

  /// No description provided for @aboutFeatureListen.
  ///
  /// In vi, this message translates to:
  /// **'Nghe thuyết minh âm thanh bằng nhiều ngôn ngữ, hoặc nghe lần lượt cả danh sách.'**
  String get aboutFeatureListen;

  /// No description provided for @aboutFeatureScan.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR trên bảng giới thiệu, hoặc bật quét iBeacon để ứng dụng tự nhận diện hiện vật gần bạn.'**
  String get aboutFeatureScan;

  /// No description provided for @aboutFeatureMap.
  ///
  /// In vi, this message translates to:
  /// **'Xem bản đồ các địa điểm, sơ đồ từng tầng và khu vực trưng bày.'**
  String get aboutFeatureMap;

  /// No description provided for @aboutFeatureNews.
  ///
  /// In vi, this message translates to:
  /// **'Nhận tin tức, sự kiện mới từ ban quản lý và lưu lại lịch sử tham quan của bạn.'**
  String get aboutFeatureNews;

  /// No description provided for @aboutHowHeading.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu thế nào'**
  String get aboutHowHeading;

  /// No description provided for @aboutHowBody.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để mở khoá thuyết minh, quét hiện vật và thông báo. Sau đó bấm nút quét ở giữa thanh điều hướng khi đứng trước hiện vật, hoặc mở Danh sách nghe để nghe trước ở nhà. Hãy bật Bluetooth và cho phép truy cập vị trí để tính năng iBeacon hoạt động.'**
  String get aboutHowBody;

  /// No description provided for @aboutVersion.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản {version}'**
  String aboutVersion(String version);

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đến gần hiện vật, thuyết minh tự phát'**
  String get homeHeroSubtitle;

  /// No description provided for @langNameVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get langNameVi;

  /// No description provided for @langNameEn.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Anh'**
  String get langNameEn;

  /// No description provided for @langNameFr.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Pháp'**
  String get langNameFr;

  /// No description provided for @langNameJa.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Nhật'**
  String get langNameJa;

  /// No description provided for @langNameKo.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Hàn'**
  String get langNameKo;

  /// No description provided for @langNameZh.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Trung'**
  String get langNameZh;

  /// No description provided for @langScreenTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ngôn ngữ'**
  String get langScreenTitle;

  /// No description provided for @langScreenIntro.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện, nội dung giới thiệu, thuyết minh âm thanh và phụ đề video sẽ hiển thị theo ngôn ngữ bạn chọn.'**
  String get langScreenIntro;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @langUpdated.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật ngôn ngữ hiển thị'**
  String get langUpdated;

  /// No description provided for @langSavedLocalOnly.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi ngôn ngữ trên máy này nhưng chưa lưu được vào tài khoản.'**
  String get langSavedLocalOnly;

  /// No description provided for @langUiFallbackNotice.
  ///
  /// In vi, this message translates to:
  /// **'Giao diện app chưa có bản {language} nên tạm hiển thị bằng tiếng Anh. Nội dung hiện vật vẫn theo {language} khi có.'**
  String langUiFallbackNotice(String language);

  /// No description provided for @mapPlacesTitle.
  ///
  /// In vi, this message translates to:
  /// **'Địa điểm tham quan'**
  String get mapPlacesTitle;

  /// No description provided for @mapAreaCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, =0{Chưa có khu vực} other{{count} khu vực}}'**
  String mapAreaCount(int count);

  /// No description provided for @mapArtifactCount.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{{count} hiện vật}}'**
  String mapArtifactCount(int count);

  /// No description provided for @mapNotPinned.
  ///
  /// In vi, this message translates to:
  /// **'chưa có vị trí trên bản đồ'**
  String get mapNotPinned;

  /// No description provided for @mapScreenTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ tham quan'**
  String get mapScreenTitle;

  /// No description provided for @mapYouAreAt.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ở {place}'**
  String mapYouAreAt(String place);

  /// No description provided for @mapPlacesList.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách địa điểm'**
  String get mapPlacesList;

  /// No description provided for @mapNoPinnedPlaces.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có địa điểm nào được đặt vị trí trên bản đồ. Chọn một địa điểm để xem các khu vực.'**
  String get mapNoPinnedPlaces;

  /// No description provided for @mapYouAreHereWith.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ở đây · {details}'**
  String mapYouAreHereWith(String details);

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @mapViewAreas.
  ///
  /// In vi, this message translates to:
  /// **'Xem các khu vực'**
  String get mapViewAreas;

  /// No description provided for @mapAllArtifacts.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả hiện vật'**
  String get mapAllArtifacts;

  /// No description provided for @mapPickArea.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một khu vực để xem bản đồ'**
  String get mapPickArea;

  /// No description provided for @mapPickFloor.
  ///
  /// In vi, this message translates to:
  /// **'Chọn tầng để xem sơ đồ khu vực'**
  String get mapPickFloor;

  /// No description provided for @mapOtherAreas.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực khác'**
  String get mapOtherAreas;

  /// No description provided for @mapFloorPlan.
  ///
  /// In vi, this message translates to:
  /// **'Sơ đồ tầng'**
  String get mapFloorPlan;

  /// No description provided for @mapOnThisFloor.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ở tầng này'**
  String get mapOnThisFloor;

  /// No description provided for @mapNoArtifacts.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hiện vật'**
  String get mapNoArtifacts;

  /// No description provided for @mapYouAreHere.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ở đây'**
  String get mapYouAreHere;

  /// No description provided for @mapFloorNoPlan.
  ///
  /// In vi, this message translates to:
  /// **'Tầng này chưa có sơ đồ'**
  String get mapFloorNoPlan;

  /// No description provided for @mapPickAreaBelow.
  ///
  /// In vi, this message translates to:
  /// **'Chọn một khu vực bên dưới để xem bản đồ của nó.'**
  String get mapPickAreaBelow;

  /// No description provided for @mapFloorPlanLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được sơ đồ tầng'**
  String get mapFloorPlanLoadFailed;

  /// No description provided for @mapFloorNoAreas.
  ///
  /// In vi, this message translates to:
  /// **'Tầng này chưa có khu vực nào.'**
  String get mapFloorNoAreas;

  /// No description provided for @mapPlanLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được sơ đồ.'**
  String get mapPlanLoadFailed;

  /// No description provided for @mapAttractionNoPlan.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tham quan này chưa có sơ đồ tầng.'**
  String get mapAttractionNoPlan;

  /// No description provided for @crowdQuiet.
  ///
  /// In vi, this message translates to:
  /// **'Đang vắng khách'**
  String get crowdQuiet;

  /// No description provided for @crowdAroundHere.
  ///
  /// In vi, this message translates to:
  /// **'~{count} khách quanh đây'**
  String crowdAroundHere(int count);

  /// No description provided for @crowdAroundZone.
  ///
  /// In vi, this message translates to:
  /// **'~{count} khách quanh khu vực {zone}'**
  String crowdAroundZone(int count, String zone);

  /// No description provided for @crowdHere.
  ///
  /// In vi, this message translates to:
  /// **'~{count} khách đang ở đây'**
  String crowdHere(int count);

  /// No description provided for @crowdInArea.
  ///
  /// In vi, this message translates to:
  /// **'~{count} khách đang ở khu này'**
  String crowdInArea(int count);

  /// No description provided for @locationServiceOff.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng bật GPS/Vị trí trên thiết bị rồi thử lại.'**
  String get locationServiceOff;

  /// No description provided for @locationDeniedForever.
  ///
  /// In vi, this message translates to:
  /// **'Quyền vị trí đang bị chặn. Hãy bật lại trong Cài đặt của máy.'**
  String get locationDeniedForever;

  /// No description provided for @locationNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng cần quyền vị trí để định vị bạn trên bản đồ.'**
  String get locationNeeded;

  /// No description provided for @mapNoLocationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có vị trí trên bản đồ'**
  String get mapNoLocationTitle;

  /// No description provided for @mapNoLocationText.
  ///
  /// In vi, this message translates to:
  /// **'Điểm tham quan này chưa có hiện vật hay beacon nào được đặt toạ độ.'**
  String get mapNoLocationText;

  /// No description provided for @mapYouAreInZone.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đang ở khu vực {zone}'**
  String mapYouAreInZone(String zone);

  /// No description provided for @mapDistanceFromYou.
  ///
  /// In vi, this message translates to:
  /// **'{zone} · cách bạn ~{distance}'**
  String mapDistanceFromYou(String zone, String distance);

  /// No description provided for @mapDirections.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ đường'**
  String get mapDirections;

  /// No description provided for @details.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết'**
  String get details;

  /// No description provided for @mapNotReadyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ chưa sẵn sàng'**
  String get mapNotReadyTitle;

  /// No description provided for @mapNotReadyText.
  ///
  /// In vi, this message translates to:
  /// **'Bản build này chưa có token Mapbox. Chạy lại với --dart-define-from-file=mapbox.local.json.'**
  String get mapNotReadyText;

  /// No description provided for @artifactTabIntro.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu'**
  String get artifactTabIntro;

  /// No description provided for @artifactTabPhotos.
  ///
  /// In vi, this message translates to:
  /// **'Hình ảnh'**
  String get artifactTabPhotos;

  /// No description provided for @artifactTabVideo.
  ///
  /// In vi, this message translates to:
  /// **'Video'**
  String get artifactTabVideo;

  /// No description provided for @artifactTabReviews.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá'**
  String get artifactTabReviews;

  /// No description provided for @artifactSavedOffline.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung đã được lưu — bạn có thể tiếp tục xem kể cả khi rời khỏi vùng phủ sóng beacon.'**
  String get artifactSavedOffline;

  /// No description provided for @artifactOverview.
  ///
  /// In vi, this message translates to:
  /// **'Giới thiệu chung'**
  String get artifactOverview;

  /// No description provided for @artifactListen.
  ///
  /// In vi, this message translates to:
  /// **'Nghe thuyết minh âm thanh'**
  String get artifactListen;

  /// No description provided for @artifactNoLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Hiện vật này chưa có bản {language}'**
  String artifactNoLanguage(String language);

  /// No description provided for @artifactNoLanguageText.
  ///
  /// In vi, this message translates to:
  /// **'Phần giới thiệu và thuyết minh âm thanh chưa được soạn cho ngôn ngữ bạn đang chọn. Hãy chọn ngôn ngữ khác để xem.'**
  String get artifactNoLanguageText;

  /// No description provided for @changeLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngôn ngữ'**
  String get changeLanguage;

  /// No description provided for @artifactPhotoPlaceholder.
  ///
  /// In vi, this message translates to:
  /// **'Ảnh {index}/{total}'**
  String artifactPhotoPlaceholder(int index, int total);

  /// No description provided for @videoNarration.
  ///
  /// In vi, this message translates to:
  /// **'Thuyết minh: {name}'**
  String videoNarration(String name);

  /// No description provided for @videoDocumentary.
  ///
  /// In vi, this message translates to:
  /// **'Phim tư liệu: quá trình phát hiện và bảo tồn'**
  String get videoDocumentary;

  /// No description provided for @videoSubtitles.
  ///
  /// In vi, this message translates to:
  /// **'Video có phụ đề tiếng Việt và tiếng Anh'**
  String get videoSubtitles;

  /// No description provided for @audioViewArtifact.
  ///
  /// In vi, this message translates to:
  /// **'Xem chi tiết hiện vật'**
  String get audioViewArtifact;

  /// No description provided for @audioNoRecording.
  ///
  /// In vi, this message translates to:
  /// **'Hiện vật này chưa có bản thuyết minh.'**
  String get audioNoRecording;

  /// No description provided for @audioLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải bản thuyết minh…'**
  String get audioLoading;

  /// No description provided for @audioLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ thuyết minh'**
  String get audioLanguage;

  /// No description provided for @share.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ'**
  String get share;

  /// No description provided for @audioTranscript.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung thuyết minh'**
  String get audioTranscript;

  /// No description provided for @audioLinkCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết hiện vật'**
  String get audioLinkCopied;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @newsUnavailable.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết này không còn hoặc chưa có bản cho ngôn ngữ bạn chọn.'**
  String get newsUnavailable;

  /// No description provided for @newsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được nội dung bài viết.'**
  String get newsLoadFailed;

  /// No description provided for @newsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bài viết chưa có nội dung.'**
  String get newsEmpty;

  /// No description provided for @reviewTagContentGood.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung hấp dẫn'**
  String get reviewTagContentGood;

  /// No description provided for @reviewTagNarrationClear.
  ///
  /// In vi, this message translates to:
  /// **'Thuyết minh rõ ràng'**
  String get reviewTagNarrationClear;

  /// No description provided for @reviewTagWayfindingEasy.
  ///
  /// In vi, this message translates to:
  /// **'Dễ tìm vị trí'**
  String get reviewTagWayfindingEasy;

  /// No description provided for @reviewTagImagesGood.
  ///
  /// In vi, this message translates to:
  /// **'Hình ảnh đẹp'**
  String get reviewTagImagesGood;

  /// No description provided for @reviewTagLanguagesMissing.
  ///
  /// In vi, this message translates to:
  /// **'Cần thêm ngôn ngữ'**
  String get reviewTagLanguagesMissing;

  /// No description provided for @reviewTagAudioPoor.
  ///
  /// In vi, this message translates to:
  /// **'Âm thanh chưa tốt'**
  String get reviewTagAudioPoor;

  /// No description provided for @feedbackTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá & phản hồi'**
  String get feedbackTitle;

  /// No description provided for @rating1.
  ///
  /// In vi, this message translates to:
  /// **'Rất tệ'**
  String get rating1;

  /// No description provided for @rating2.
  ///
  /// In vi, this message translates to:
  /// **'Chưa hài lòng'**
  String get rating2;

  /// No description provided for @rating3.
  ///
  /// In vi, this message translates to:
  /// **'Bình thường'**
  String get rating3;

  /// No description provided for @rating4.
  ///
  /// In vi, this message translates to:
  /// **'Hài lòng'**
  String get rating4;

  /// No description provided for @rating5.
  ///
  /// In vi, this message translates to:
  /// **'Tuyệt vời'**
  String get rating5;

  /// No description provided for @feedbackPickRating.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng chọn số sao đánh giá'**
  String get feedbackPickRating;

  /// No description provided for @feedbackThanks.
  ///
  /// In vi, this message translates to:
  /// **'Cảm ơn bạn! Phản hồi đã được gửi thành công.'**
  String get feedbackThanks;

  /// No description provided for @feedbackHowWasVisit.
  ///
  /// In vi, this message translates to:
  /// **'Trải nghiệm tham quan của bạn hôm nay thế nào?'**
  String get feedbackHowWasVisit;

  /// No description provided for @feedbackWhatImpressed.
  ///
  /// In vi, this message translates to:
  /// **'Điều gì khiến bạn ấn tượng?'**
  String get feedbackWhatImpressed;

  /// No description provided for @feedbackTellUsMore.
  ///
  /// In vi, this message translates to:
  /// **'Chia sẻ thêm với chúng tôi'**
  String get feedbackTellUsMore;

  /// No description provided for @feedbackHint.
  ///
  /// In vi, this message translates to:
  /// **'Cảm nhận, góp ý của bạn giúp chúng tôi phục vụ tốt hơn...'**
  String get feedbackHint;

  /// No description provided for @feedbackAttachPhoto.
  ///
  /// In vi, this message translates to:
  /// **'Đính kèm hình ảnh'**
  String get feedbackAttachPhoto;

  /// No description provided for @feedbackSend.
  ///
  /// In vi, this message translates to:
  /// **'Gửi phản hồi'**
  String get feedbackSend;

  /// No description provided for @reviewsLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Chưa tải được danh sách đánh giá.'**
  String get reviewsLoadFailed;

  /// No description provided for @reviewsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có đánh giá nào. Hãy là người đầu tiên!'**
  String get reviewsEmpty;

  /// No description provided for @reviewsHeader.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá của khách tham quan ({count})'**
  String reviewsHeader(int count);

  /// No description provided for @qrNotOurs.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR này không phải mã hiện vật của SmartHeritage.'**
  String get qrNotOurs;

  /// No description provided for @qrTorch.
  ///
  /// In vi, this message translates to:
  /// **'Đèn pin'**
  String get qrTorch;

  /// No description provided for @qrAimHint.
  ///
  /// In vi, this message translates to:
  /// **'Đưa mã QR trên bảng giới thiệu hiện vật vào khung'**
  String get qrAimHint;

  /// No description provided for @qrCameraDenied.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng chưa được dùng camera. Hãy bật quyền Camera cho SmartHeritage trong Cài đặt của máy.'**
  String get qrCameraDenied;

  /// No description provided for @qrCameraFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không mở được camera. Thử đóng màn này rồi mở lại.'**
  String get qrCameraFailed;

  /// No description provided for @beaconSearching.
  ///
  /// In vi, this message translates to:
  /// **'Đang dò beacon quanh bạn…'**
  String get beaconSearching;

  /// No description provided for @beaconTapToStart.
  ///
  /// In vi, this message translates to:
  /// **'Chạm để bắt đầu quét'**
  String get beaconTapToStart;

  /// No description provided for @beaconScanningHint.
  ///
  /// In vi, this message translates to:
  /// **'Hãy đứng gần hiện vật. Bắt được beacon là app tự giới thiệu hiện vật đó — bạn có thể rời trang này, app vẫn quét tiếp.'**
  String get beaconScanningHint;

  /// No description provided for @beaconIdleHint.
  ///
  /// In vi, this message translates to:
  /// **'App dùng Bluetooth để nhận tín hiệu beacon đặt cạnh hiện vật.'**
  String get beaconIdleHint;

  /// No description provided for @beaconStop.
  ///
  /// In vi, this message translates to:
  /// **'Tắt quét'**
  String get beaconStop;

  /// No description provided for @beaconTurnOff.
  ///
  /// In vi, this message translates to:
  /// **'Tắt quét beacon'**
  String get beaconTurnOff;

  /// No description provided for @beaconTurnOn.
  ///
  /// In vi, this message translates to:
  /// **'Bật quét beacon'**
  String get beaconTurnOn;

  /// No description provided for @beaconStartFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không khởi động được bộ quét beacon ({detail}).'**
  String beaconStartFailed(String detail);

  /// No description provided for @beaconLocationServiceOff.
  ///
  /// In vi, this message translates to:
  /// **'Hãy bật Dịch vụ định vị trong Cài đặt để quét beacon.'**
  String get beaconLocationServiceOff;

  /// No description provided for @beaconLocationNeeded.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng cần quyền vị trí để nhận tín hiệu beacon. Hãy bật trong Cài đặt.'**
  String get beaconLocationNeeded;

  /// No description provided for @beaconGpsOffAndroid.
  ///
  /// In vi, this message translates to:
  /// **'Hãy bật Dịch vụ vị trí (GPS) — Android cần nó để quét beacon.'**
  String get beaconGpsOffAndroid;

  /// No description provided for @beaconNotReady.
  ///
  /// In vi, this message translates to:
  /// **'Chưa khởi động được bộ quét beacon.'**
  String get beaconNotReady;

  /// No description provided for @bluetoothOff.
  ///
  /// In vi, this message translates to:
  /// **'Hãy bật Bluetooth để quét beacon.'**
  String get bluetoothOff;

  /// No description provided for @bluetoothUnauthorized.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng chưa được phép dùng Bluetooth. Hãy bật trong Cài đặt.'**
  String get bluetoothUnauthorized;

  /// No description provided for @bluetoothUnsupported.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này không hỗ trợ Bluetooth Low Energy.'**
  String get bluetoothUnsupported;

  /// No description provided for @bluetoothNotReady.
  ///
  /// In vi, this message translates to:
  /// **'Bluetooth chưa sẵn sàng. Hãy thử bật quét lại.'**
  String get bluetoothNotReady;

  /// No description provided for @beaconDetectedVia.
  ///
  /// In vi, this message translates to:
  /// **'Phát hiện qua iBeacon · cách bạn ~2m'**
  String get beaconDetectedVia;

  /// No description provided for @beaconLater.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get beaconLater;

  /// No description provided for @beaconExploreNow.
  ///
  /// In vi, this message translates to:
  /// **'Khám phá ngay'**
  String get beaconExploreNow;

  /// No description provided for @beaconAudioMuted.
  ///
  /// In vi, this message translates to:
  /// **'Thuyết minh đang tắt tiếng'**
  String get beaconAudioMuted;

  /// No description provided for @beaconAudioPlaying.
  ///
  /// In vi, this message translates to:
  /// **'Đang phát thuyết minh âm thanh'**
  String get beaconAudioPlaying;

  /// No description provided for @beaconAudioLogin.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để nghe thuyết minh'**
  String get beaconAudioLogin;

  /// No description provided for @beaconChoiceTitle.
  ///
  /// In vi, this message translates to:
  /// **'{count, plural, other{Có {count} hiện vật quanh đây}}'**
  String beaconChoiceTitle(int count);

  /// No description provided for @beaconChoiceMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chọn hiện vật bạn muốn xem và nghe thuyết minh.'**
  String get beaconChoiceMessage;

  /// No description provided for @beaconChoiceHasAudio.
  ///
  /// In vi, this message translates to:
  /// **'Có thuyết minh'**
  String get beaconChoiceHasAudio;

  /// No description provided for @favTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hiện vật yêu thích'**
  String get favTitle;

  /// No description provided for @favLoginTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để lưu yêu thích'**
  String get favLoginTitle;

  /// No description provided for @favLoginMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để lưu và đồng bộ các hiện vật\nyêu thích của bạn trên mọi thiết bị'**
  String get favLoginMessage;

  /// No description provided for @favEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có hiện vật yêu thích'**
  String get favEmptyTitle;

  /// No description provided for @favEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Nhấn ♥ trên hiện vật để lưu lại\nvà xem lại bất cứ lúc nào'**
  String get favEmptyMessage;

  /// No description provided for @loginOrRegister.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập / Đăng ký'**
  String get loginOrRegister;

  /// No description provided for @historyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử tham quan'**
  String get historyTitle;

  /// No description provided for @historyDetectedAt.
  ///
  /// In vi, this message translates to:
  /// **'iBeacon phát hiện lúc {time}'**
  String historyDetectedAt(String time);

  /// No description provided for @historyClearTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xoá lịch sử'**
  String get historyClearTitle;

  /// No description provided for @historyClearAccount.
  ///
  /// In vi, this message translates to:
  /// **'Xoá toàn bộ lịch sử tham quan của tài khoản này?'**
  String get historyClearAccount;

  /// No description provided for @historyClearDevice.
  ///
  /// In vi, this message translates to:
  /// **'Xoá toàn bộ lịch sử tham quan trên thiết bị này?'**
  String get historyClearDevice;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Huỷ'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In vi, this message translates to:
  /// **'Xoá'**
  String get delete;

  /// No description provided for @historyStatArtifacts.
  ///
  /// In vi, this message translates to:
  /// **'Hiện vật đã xem'**
  String get historyStatArtifacts;

  /// No description provided for @historyStatDays.
  ///
  /// In vi, this message translates to:
  /// **'Ngày tham quan'**
  String get historyStatDays;

  /// No description provided for @historyStatAreas.
  ///
  /// In vi, this message translates to:
  /// **'Khu đã ghé'**
  String get historyStatAreas;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có lịch sử tham quan'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Khi bạn đến gần một hiện vật, iBeacon sẽ\ntự động ghi lại vào đây'**
  String get historyEmptyMessage;

  /// No description provided for @today.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua'**
  String get yesterday;

  /// No description provided for @audioPlayFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không phát được bản thuyết minh.'**
  String get audioPlayFailed;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản của tôi'**
  String get profileTitle;

  /// No description provided for @profileSectionPersonal.
  ///
  /// In vi, this message translates to:
  /// **'Cá nhân'**
  String get profileSectionPersonal;

  /// No description provided for @profileEdit.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa thông tin cá nhân'**
  String get profileEdit;

  /// No description provided for @profileLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get profileLanguage;

  /// No description provided for @profileSectionDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị'**
  String get profileSectionDevice;

  /// No description provided for @profileSectionSupport.
  ///
  /// In vi, this message translates to:
  /// **'Hỗ trợ'**
  String get profileSectionSupport;

  /// No description provided for @profileRateSite.
  ///
  /// In vi, this message translates to:
  /// **'Đánh giá khu di tích'**
  String get profileRateSite;

  /// No description provided for @profileNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get profileNotifications;

  /// No description provided for @profileHelpFaq.
  ///
  /// In vi, this message translates to:
  /// **'Trợ giúp & câu hỏi thường gặp'**
  String get profileHelpFaq;

  /// No description provided for @profileAbout.
  ///
  /// In vi, this message translates to:
  /// **'Về ứng dụng'**
  String get profileAbout;

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @profileBadge.
  ///
  /// In vi, this message translates to:
  /// **'Nhà thám hiểm di sản'**
  String get profileBadge;

  /// No description provided for @profileGuestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham quan có tài khoản riêng'**
  String get profileGuestTitle;

  /// No description provided for @login.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập'**
  String get login;

  /// No description provided for @register.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký'**
  String get register;

  /// No description provided for @profileBeaconScan.
  ///
  /// In vi, this message translates to:
  /// **'Quét iBeacon'**
  String get profileBeaconScan;

  /// No description provided for @profileScanOff.
  ///
  /// In vi, this message translates to:
  /// **'Đang tắt'**
  String get profileScanOff;

  /// No description provided for @logoutConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn đăng xuất khỏi ứng dụng?'**
  String get logoutConfirm;

  /// No description provided for @loggedOut.
  ///
  /// In vi, this message translates to:
  /// **'Đã đăng xuất'**
  String get loggedOut;

  /// No description provided for @editProfileSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật thông tin cá nhân'**
  String get editProfileSaved;

  /// No description provided for @editProfileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chỉnh sửa thông tin'**
  String get editProfileTitle;

  /// No description provided for @fieldFullName.
  ///
  /// In vi, this message translates to:
  /// **'Họ và tên'**
  String get fieldFullName;

  /// No description provided for @fieldEmail.
  ///
  /// In vi, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// No description provided for @fieldPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại'**
  String get fieldPhone;

  /// No description provided for @fieldGender.
  ///
  /// In vi, this message translates to:
  /// **'Giới tính'**
  String get fieldGender;

  /// No description provided for @genderMale.
  ///
  /// In vi, this message translates to:
  /// **'Nam'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In vi, this message translates to:
  /// **'Nữ'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In vi, this message translates to:
  /// **'Khác'**
  String get genderOther;

  /// No description provided for @saveChanges.
  ///
  /// In vi, this message translates to:
  /// **'Lưu thay đổi'**
  String get saveChanges;

  /// No description provided for @loginSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập thành công'**
  String get loginSuccess;

  /// No description provided for @googleSignInFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đăng nhập được bằng Google. Vui lòng thử lại.'**
  String get googleSignInFailed;

  /// No description provided for @googleAccountRejected.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản Google này không dùng được (email chưa xác minh hoặc tài khoản đã bị khoá).'**
  String get googleAccountRejected;

  /// No description provided for @googleLoginDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ chưa bật đăng nhập Google.'**
  String get googleLoginDisabled;

  /// No description provided for @loginWelcome.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng trở lại!'**
  String get loginWelcome;

  /// No description provided for @loginSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập để đồng bộ lịch sử tham quan\nvà cá nhân hoá trải nghiệm của bạn'**
  String get loginSubtitle;

  /// No description provided for @invalidEmail.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập email hợp lệ'**
  String get invalidEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get fieldPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu tối thiểu 8 ký tự'**
  String get passwordTooShort;

  /// No description provided for @forgotPassword.
  ///
  /// In vi, this message translates to:
  /// **'Quên mật khẩu?'**
  String get forgotPassword;

  /// No description provided for @orContinueWith.
  ///
  /// In vi, this message translates to:
  /// **'hoặc tiếp tục với'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục với Google'**
  String get continueWithGoogle;

  /// No description provided for @noAccount.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có tài khoản? '**
  String get noAccount;

  /// No description provided for @registerNow.
  ///
  /// In vi, this message translates to:
  /// **'Đăng ký ngay'**
  String get registerNow;

  /// No description provided for @agreeTermsRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng đồng ý với điều khoản sử dụng'**
  String get agreeTermsRequired;

  /// No description provided for @registerSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản thành công'**
  String get registerSuccess;

  /// No description provided for @registerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo tài khoản'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu hành trình khám phá di sản cùng chúng tôi'**
  String get registerSubtitle;

  /// No description provided for @nameRequired.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập họ tên'**
  String get nameRequired;

  /// No description provided for @invalidPhone.
  ///
  /// In vi, this message translates to:
  /// **'Số điện thoại không hợp lệ'**
  String get invalidPhone;

  /// No description provided for @agreePrefix.
  ///
  /// In vi, this message translates to:
  /// **'Tôi đồng ý với '**
  String get agreePrefix;

  /// No description provided for @termsOfUse.
  ///
  /// In vi, this message translates to:
  /// **'Điều khoản sử dụng'**
  String get termsOfUse;

  /// No description provided for @agreeAnd.
  ///
  /// In vi, this message translates to:
  /// **' và '**
  String get agreeAnd;

  /// No description provided for @privacyPolicy.
  ///
  /// In vi, this message translates to:
  /// **'Chính sách bảo mật'**
  String get privacyPolicy;

  /// No description provided for @haveAccount.
  ///
  /// In vi, this message translates to:
  /// **'Đã có tài khoản? '**
  String get haveAccount;

  /// No description provided for @guest.
  ///
  /// In vi, this message translates to:
  /// **'Khách'**
  String get guest;

  /// No description provided for @invalidServerData.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả về dữ liệu không hợp lệ.'**
  String get invalidServerData;

  /// No description provided for @serverTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ phản hồi quá lâu.'**
  String get serverTimeout;

  /// No description provided for @serverUnreachable.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ.'**
  String get serverUnreachable;

  /// No description provided for @error400.
  ///
  /// In vi, this message translates to:
  /// **'Dữ liệu gửi lên không hợp lệ.'**
  String get error400;

  /// No description provided for @error401.
  ///
  /// In vi, this message translates to:
  /// **'Phiên đăng nhập đã hết hạn.'**
  String get error401;

  /// No description provided for @error403.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không có quyền thực hiện thao tác này.'**
  String get error403;

  /// No description provided for @error404.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy dữ liệu.'**
  String get error404;

  /// No description provided for @errorServer.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ gặp sự cố ({status}).'**
  String errorServer(int status);

  /// No description provided for @helpGroup1.
  ///
  /// In vi, this message translates to:
  /// **'iBeacon & phát hiện hiện vật'**
  String get helpGroup1;

  /// No description provided for @helpGroup2.
  ///
  /// In vi, this message translates to:
  /// **'Thuyết minh âm thanh'**
  String get helpGroup2;

  /// No description provided for @helpGroup3.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản'**
  String get helpGroup3;

  /// No description provided for @helpGroup4.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ & vị trí'**
  String get helpGroup4;

  /// No description provided for @helpGroup5.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo & phản hồi'**
  String get helpGroup5;

  /// No description provided for @helpQ1.
  ///
  /// In vi, this message translates to:
  /// **'iBeacon là gì và app dùng nó để làm gì?'**
  String get helpQ1;

  /// No description provided for @helpA1.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi khu trưng bày được gắn một thiết bị iBeacon phát sóng Bluetooth tầm ngắn. Khi bạn đi tới gần, ứng dụng nhận được sóng và tự nhận ra bạn đang ở cạnh hiện vật nào, rồi mở phần giới thiệu tương ứng. Bạn không phải quét mã hay nhập số hiệu hiện vật.'**
  String get helpA1;

  /// No description provided for @helpQ2.
  ///
  /// In vi, this message translates to:
  /// **'Bật tính năng quét ở đâu?'**
  String get helpQ2;

  /// No description provided for @helpA2.
  ///
  /// In vi, this message translates to:
  /// **'Mở sidebar bằng nút menu ở góc trên bên trái trang Khám phá, rồi bật công tắc \"Quét iBeacon\". Công tắc này áp dụng cho toàn ứng dụng, tắt lúc nào cũng được.'**
  String get helpA2;

  /// No description provided for @helpQ3.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao app không phát hiện được hiện vật nào?'**
  String get helpQ3;

  /// No description provided for @helpA3.
  ///
  /// In vi, this message translates to:
  /// **'Hãy kiểm tra theo thứ tự: đã bật công tắc \"Quét iBeacon\" trong sidebar chưa, Bluetooth của máy đã mở chưa, và ứng dụng đã được cấp quyền Bluetooth trong phần cài đặt của hệ điều hành chưa. Sóng iBeacon chỉ phủ vài mét, nên bạn cũng cần đứng gần khu trưng bày.'**
  String get helpA3;

  /// No description provided for @helpQ4.
  ///
  /// In vi, this message translates to:
  /// **'Quét iBeacon có tốn pin nhiều không?'**
  String get helpQ4;

  /// No description provided for @helpA4.
  ///
  /// In vi, this message translates to:
  /// **'iBeacon dùng Bluetooth Low Energy, tiêu thụ pin rất thấp so với GPS hay 4G. Dù vậy, nếu bạn đã tham quan xong thì nên tắt công tắc trong sidebar để tiết kiệm thêm.'**
  String get helpA4;

  /// No description provided for @helpQ5.
  ///
  /// In vi, this message translates to:
  /// **'Thuyết minh có tự phát không?'**
  String get helpQ5;

  /// No description provided for @helpA5.
  ///
  /// In vi, this message translates to:
  /// **'Có. Khi iBeacon phát hiện bạn ở gần một hiện vật, ứng dụng tự mở và phát thuyết minh của hiện vật đó, bạn không cần bấm gì. Nếu muốn nghe lại hoặc nghe hiện vật khác, vào trang chi tiết hiện vật và bấm \"Nghe thuyết minh âm thanh\" ở cuối tab Giới thiệu.'**
  String get helpA5;

  /// No description provided for @helpQ6.
  ///
  /// In vi, this message translates to:
  /// **'Làm sao tắt tiếng khi đang ở nơi cần yên lặng?'**
  String get helpQ6;

  /// No description provided for @helpA6.
  ///
  /// In vi, this message translates to:
  /// **'Bấm nút hình loa. Nút này có ở ba nơi: thanh phát nhỏ phía dưới màn hình, khung thông báo khi beacon phát hiện hiện vật, và trang nghe thuyết minh. Tắt tiếng chỉ làm im âm thanh, phần thuyết minh vẫn chạy và bạn vẫn đọc được nội dung chữ.'**
  String get helpA6;

  /// No description provided for @helpQ7.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tốc độ đọc được không?'**
  String get helpQ7;

  /// No description provided for @helpA7.
  ///
  /// In vi, this message translates to:
  /// **'Được. Ở trang nghe thuyết minh, bấm nút tốc độ bên phải hàng điều khiển để chuyển lần lượt qua 0.75×, 1×, 1.25× và 1.5×.'**
  String get helpA7;

  /// No description provided for @helpQ8.
  ///
  /// In vi, this message translates to:
  /// **'Đổi ngôn ngữ thuyết minh ở đâu?'**
  String get helpQ8;

  /// No description provided for @helpA8.
  ///
  /// In vi, this message translates to:
  /// **'Có hai đường: nút hình chữ dịch ở trang nghe thuyết minh, hoặc vào Tài khoản của tôi → Ngôn ngữ. Sidebar cũng có mục Ngôn ngữ.'**
  String get helpA8;

  /// No description provided for @helpQ9.
  ///
  /// In vi, this message translates to:
  /// **'Đi ra xa hiện vật thì còn xem được nội dung không?'**
  String get helpQ9;

  /// No description provided for @helpA9.
  ///
  /// In vi, this message translates to:
  /// **'Còn. Nội dung đã tải sẽ tiếp tục xem được kể cả khi bạn ra ngoài vùng phủ sóng beacon, nên có thể đọc lại sau khi rời khu trưng bày.'**
  String get helpA9;

  /// No description provided for @helpQ10.
  ///
  /// In vi, this message translates to:
  /// **'Có bắt buộc đăng nhập mới dùng được không?'**
  String get helpQ10;

  /// No description provided for @helpA10.
  ///
  /// In vi, this message translates to:
  /// **'Không. Khách tham quan xem được toàn bộ hiện vật, bản đồ, thuyết minh và nhận thông báo mà không cần tài khoản.'**
  String get helpA10;

  /// No description provided for @helpQ11.
  ///
  /// In vi, this message translates to:
  /// **'Vậy đăng nhập để làm gì?'**
  String get helpQ11;

  /// No description provided for @helpA11.
  ///
  /// In vi, this message translates to:
  /// **'Để lưu danh sách hiện vật yêu thích và đồng bộ dữ liệu của bạn giữa các thiết bị. Lịch sử tham quan thì vẫn được lưu trên máy ngay cả khi bạn chưa đăng nhập.'**
  String get helpA11;

  /// No description provided for @helpQ12.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập và đăng ký ở đâu?'**
  String get helpQ12;

  /// No description provided for @helpA12.
  ///
  /// In vi, this message translates to:
  /// **'Vào Tài khoản của tôi, dùng hai nút \"Đăng nhập\" và \"Đăng ký\" ở đầu trang. Sidebar cũng có lối vào tương tự.'**
  String get helpA12;

  /// No description provided for @helpQ13.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ trống, không thấy gì cả?'**
  String get helpQ13;

  /// No description provided for @helpA13.
  ///
  /// In vi, this message translates to:
  /// **'Bản đồ cần kết nối mạng để tải nền. Hãy kiểm tra Wi-Fi hoặc dữ liệu di động. Các ghim hiện vật vẫn hiện đúng vị trí dù nền bản đồ chưa tải xong.'**
  String get helpA13;

  /// No description provided for @helpQ14.
  ///
  /// In vi, this message translates to:
  /// **'Vì sao app xin quyền vị trí?'**
  String get helpQ14;

  /// No description provided for @helpA14.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ để hiển thị chấm vị trí của bạn trên bản đồ khu di tích, giúp bạn biết mình đang ở đâu so với các hiện vật. Từ chối quyền này thì bản đồ và ghim hiện vật vẫn dùng bình thường.'**
  String get helpA14;

  /// No description provided for @helpQ15.
  ///
  /// In vi, this message translates to:
  /// **'Lọc hiện vật theo khu trưng bày được không?'**
  String get helpQ15;

  /// No description provided for @helpA15.
  ///
  /// In vi, this message translates to:
  /// **'Được. Ở tab Bản đồ có dải nút chọn khu vực phía trên; chọn một khu thì bản đồ chỉ hiện ghim của khu đó.'**
  String get helpA15;

  /// No description provided for @helpQ16.
  ///
  /// In vi, this message translates to:
  /// **'Xem lại thông báo đã nhận ở đâu?'**
  String get helpQ16;

  /// No description provided for @helpA16.
  ///
  /// In vi, this message translates to:
  /// **'Bấm nút hình chuông ở góc trên bên phải trang Khám phá. Con số đỏ trên chuông là số thông báo chưa đọc.'**
  String get helpA16;

  /// No description provided for @helpQ17.
  ///
  /// In vi, this message translates to:
  /// **'Tôi muốn đánh giá một hiện vật hoặc góp ý về khu di tích.'**
  String get helpQ17;

  /// No description provided for @helpA17.
  ///
  /// In vi, this message translates to:
  /// **'Với từng hiện vật: mở trang chi tiết rồi vào tab \"Đánh giá\". Với góp ý chung về khu di tích: vào Tài khoản của tôi → Đánh giá khu di tích.'**
  String get helpA17;

  /// No description provided for @helpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Trợ giúp & FAQ'**
  String get helpTitle;

  /// No description provided for @helpStillStuck.
  ///
  /// In vi, this message translates to:
  /// **'Vẫn chưa tìm được câu trả lời?'**
  String get helpStillStuck;

  /// No description provided for @helpContactText.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ ban quản lý khu di tích, hoặc gửi phản hồi trực tiếp trong ứng dụng.'**
  String get helpContactText;

  /// No description provided for @helpEmailCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép email hỗ trợ'**
  String get helpEmailCopied;

  /// No description provided for @helpPhoneCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép số hỗ trợ'**
  String get helpPhoneCopied;

  /// No description provided for @completePhoneTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm số điện thoại'**
  String get completePhoneTitle;

  /// No description provided for @completePhoneSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản Google chưa có số điện thoại. Vui lòng nhập số điện thoại để hoàn tất đăng nhập.'**
  String get completePhoneSubtitle;

  /// No description provided for @completePhoneSubmit.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get completePhoneSubmit;

  /// No description provided for @completePhoneUseOtherAccount.
  ///
  /// In vi, this message translates to:
  /// **'Dùng tài khoản khác'**
  String get completePhoneUseOtherAccount;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
