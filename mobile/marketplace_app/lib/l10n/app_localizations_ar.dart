// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'السوق المراقب';

  @override
  String get myProfile => 'حسابي';

  @override
  String get language => 'اللغة';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get saveTheme => 'حفظ المظهر على هذا الجهاز';

  @override
  String get home => 'الرئيسية';

  @override
  String get search => 'بحث';

  @override
  String get publish => 'نشر';

  @override
  String get messages => 'الرسائل';

  @override
  String get marketplaceListing => 'إعلان Marketplace';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get moreOptions => 'خيارات أكثر';

  @override
  String get listingAvailable => 'الإعلان متاح';

  @override
  String get noMessages => 'لا توجد رسائل';

  @override
  String get sendFirstMessage => 'أرسل أول رسالة';

  @override
  String get chatMessageHint => 'اكتب رسالة...';

  @override
  String get startConversation => 'ابدأ المحادثة';

  @override
  String get profile => 'البروفايل';

  @override
  String get myAnnonces => 'إعلاناتي';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get discover => 'اكتشف';

  @override
  String get exploreByCategory => 'استكشف حسب الفئة';

  @override
  String get noAnnoncesAvailable => 'لا توجد إعلانات متاحة حاليا.';

  @override
  String get noCategoriesAvailable => 'لا توجد فئات متاحة.';

  @override
  String get reload => 'إعادة تحميل';

  @override
  String get viewAnnonces => 'عرض الإعلانات';

  @override
  String get goodDeal => 'صفقة جيدة';

  @override
  String price(String amount) {
    return '$amount د.ج';
  }

  @override
  String get call => 'اتصل';

  @override
  String get contact => 'تواصل';

  @override
  String get descriptionTitle => 'الوصف';

  @override
  String get seller => 'البائع';

  @override
  String get rateSeller => 'تقييم هذا البائع';

  @override
  String get ratingSentSuccess => 'تم إرسال التقييم بنجاح!';

  @override
  String get cannotOpenPhoneApp => 'تعذر فتح تطبيق الهاتف';

  @override
  String get mustBeLoggedInToMessage => 'يجب تسجيل الدخول لإرسال رسالة';

  @override
  String get cannotChatWithSelf => 'لا يمكنك الدردشة على إعلانك الخاص';

  @override
  String get mustBeLoggedInToRate => 'يجب تسجيل الدخول لتقييم البائع';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get send => 'إرسال';

  @override
  String get commentOptional => 'تعليق (اختياري)';

  @override
  String rate(String name) {
    return 'تقييم $name';
  }

  @override
  String get filters => 'الفلاتر';

  @override
  String get reset => 'إعادة ضبط';

  @override
  String get category => 'الفئة';

  @override
  String get allCategories => 'كل الفئات';

  @override
  String get all => 'الكل';

  @override
  String get subCategory => 'الفئة الفرعية';

  @override
  String get wilayas => 'الولايات';

  @override
  String get selectWilayas => 'اختر الولايات';

  @override
  String get allWilayas => 'كل الولايات';

  @override
  String get communes => 'البلديات';

  @override
  String get selectCommunes => 'اختر البلديات';

  @override
  String get allCommunes => 'كل البلديات';

  @override
  String selectedCount(int count) {
    return '$count محددة';
  }

  @override
  String get min => 'الأدنى';

  @override
  String get max => 'الأقصى';

  @override
  String get apply => 'تطبيق';

  @override
  String get searchHint => 'ابحث...';

  @override
  String get noAnnoncesFound => 'لم يتم العثور على إعلانات';

  @override
  String get newAnnonce => 'إعلان جديد';

  @override
  String photosCount(int count) {
    return 'الصور ($count/5)';
  }

  @override
  String get mainCategory => 'الفئة الرئيسية';

  @override
  String get condition => 'الحالة';

  @override
  String get newCondition => 'جديد';

  @override
  String get usedCondition => 'مستعمل';

  @override
  String get title => 'العنوان';

  @override
  String get priceDa => 'السعر (د.ج)';

  @override
  String get invalidPrice => 'السعر غير صالح';

  @override
  String get exchangePossible => 'إمكانية التبادل';

  @override
  String get exchangeSubtitle => 'يمكن استبدال هذا المنتج بمنتج آخر';

  @override
  String get phone => 'الهاتف';

  @override
  String get gallery => 'المعرض';

  @override
  String get photo => 'صورة';

  @override
  String get showPhone => 'إظهار رقمي';

  @override
  String get showPhoneSubtitle =>
      'عند تعطيله، لن يتمكن المستخدمون من الاتصال بك مباشرة';

  @override
  String get wilaya => 'الولاية';

  @override
  String get commune => 'البلدية';

  @override
  String get publishAnnonce => 'نشر الإعلان';

  @override
  String get compressingAndSending => 'ضغط وإرسال...';

  @override
  String get maxFivePhotos => 'الحد الأقصى 5 صور';

  @override
  String get addAtLeastOnePhoto => 'يرجى إضافة صورة واحدة على الأقل';

  @override
  String get selectCategoryValidation => 'يرجى اختيار فئة';

  @override
  String get selectSubCategoryValidation => 'يرجى اختيار فئة فرعية';

  @override
  String get enterTitle => 'يرجى إدخال عنوان';

  @override
  String get titleMinLength => 'يجب أن يحتوي العنوان على 5 أحرف على الأقل';

  @override
  String get enterDescription => 'يرجى إدخال وصف';

  @override
  String get descriptionMinLength => 'يجب أن يحتوي الوصف على 20 حرفا على الأقل';

  @override
  String get enterPrice => 'يرجى إدخال السعر';

  @override
  String get enterPhone => 'يرجى إدخال رقم الهاتف';

  @override
  String get annonceCreatedPending => 'تم إنشاء الإعلان! في انتظار المراجعة.';

  @override
  String get creationError => 'خطأ أثناء إنشاء الإعلان';

  @override
  String imageCompressionError(String error) {
    return 'خطأ أثناء ضغط الصور: $error';
  }

  @override
  String get verificationRequired => 'التحقق مطلوب';

  @override
  String get phoneVerificationRequiredMessage =>
      'يجب التحقق من رقم هاتفك قبل نشر إعلان.';

  @override
  String get verify => 'تحقق';

  @override
  String errorWithMessage(String error) {
    return 'خطأ: $error';
  }

  @override
  String get annonces => 'الإعلانات';

  @override
  String get avis => 'التقييمات';

  @override
  String get noAnnoncesYet => 'لا توجد إعلانات حتى الآن';

  @override
  String get noReviewsYet => 'لا توجد تقييمات حتى الآن';

  @override
  String get reservationMode => 'وضع الحجز';

  @override
  String get reservationModeSubtitle => 'يمكن للمشترين حجز هذا الإعلان';

  @override
  String get disabledInReservationMode => 'معطّل في وضع الحجز';

  @override
  String get topVerifiedSellers => 'أفضل البائعين الموثوقين';

  @override
  String get conversationSearchHint => 'ابحث بالاسم أو عنوان الإعلان...';

  @override
  String get noConversationsFound => 'لا توجد محادثات مطابقة';

  @override
  String get noConversationsFoundHint =>
      'جرّب البحث باسم البائع أو المشتري أو عنوان الإعلان.';
}
