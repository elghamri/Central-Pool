import 'package:flutter/material.dart';

/// Comprehensive Localization Dictionary for English and Arabic (RTL) Game'ya surfaces.
class GameyaStrings {
  final String locale;

  const GameyaStrings({this.locale = 'en'});

  bool get isRtl => locale == 'ar';
  TextDirection get textDirection => isRtl ? TextDirection.rtl : TextDirection.ltr;

  static const GameyaStrings en = GameyaStrings(locale: 'en');
  static const GameyaStrings ar = GameyaStrings(locale: 'ar');

  static GameyaStrings of(String? languageCode) {
    if (languageCode == 'ar') return ar;
    return en;
  }

  // General & Navigation
  String get appTitle => locale == 'ar' ? 'منصة الجمعية الرقمية' : 'Digital Game\'ya Platform';
  String get tabHome => locale == 'ar' ? 'جمعياتي' : 'My Game\'yas';
  String get tabDiscover => locale == 'ar' ? 'استكشف' : 'Discover';
  String get tabActivity => locale == 'ar' ? 'النشاط' : 'Activity';
  String get tabProfile => locale == 'ar' ? 'حسابي' : 'Profile';

  // Surface A: Home
  String greeting(String name) => locale == 'ar' ? 'أهلاً، $name 👋' : 'Hello, $name 👋';
  String get homeSubtitle => locale == 'ar' ? 'نظرة عامة على دوائر الادخار الخاصة بك' : 'Your community savings circles at a glance';
  String get totalMonthlyObligation => locale == 'ar' ? 'إجمالي الالتزام الشهري' : 'TOTAL MONTHLY OBLIGATION';
  String get activeCirclesCountLabel => locale == 'ar' ? 'جمعيات نشطة' : 'Active Circles';
  String nextPaymentDueIn(int days, String circle) => locale == 'ar' ? 'القسط القادم خلال $days أيام ($circle)' : 'Next payment due in $days days ($circle)';
  String get nextUpcomingPayout => locale == 'ar' ? 'دور القبض القادم' : 'NEXT UPCOMING PAYOUT';
  String arrivingInDays(int days, String circle) => locale == 'ar' ? 'خلال $days يوماً • $circle' : 'Arriving in $days Days • $circle';
  String get myActiveGameyas => locale == 'ar' ? 'جمعياتي النشطة' : 'My Active Game\'yas';
  String get discoverMore => locale == 'ar' ? 'استكشف المزيد ←' : 'Discover More →';
  String get discoverCirclesBtn => locale == 'ar' ? 'استكشف جمعيات' : 'Discover Circles';
  String get createGameyaBtn => locale == 'ar' ? '+ إنشاء جمعية جديدة' : '+ Create Game\'ya';

  // Surface B: Discovery
  String get discoverTitle => locale == 'ar' ? 'استكشف الجمعيات' : 'Discover Game\'yas';
  String get discoverSubtitle => locale == 'ar' ? 'انضم إلى دوائر ادخار مجتمعية أنشأها منظمون موثوقون.' : 'Join open community savings circles formed by trusted organizers.';
  String get joinPrivateCode => locale == 'ar' ? 'انضمام بكود الجمعية الخاص' : 'Join with Private Circle Code';
  String get privateCodeHint => locale == 'ar' ? 'لديك كود دعوة خاص؟ مثلاً FAM-882' : 'Have a private invite code? e.g. FAM-882';
  String get joinBtn => locale == 'ar' ? 'انضمام' : 'Join';
  String get openCirclesForming => locale == 'ar' ? 'جمعيات قيد التشكيل' : 'Open Circles Forming';
  String positionsAvailable(int count) => locale == 'ar' ? '$count أدوار قبض متاحة' : '$count Payout Positions Available';
  String get pickMonth => locale == 'ar' ? 'اختر دورك ←' : 'Pick Month →';
  String get choosePayoutMonth => locale == 'ar' ? 'اختر شهر استلام القبض' : 'CHOOSE YOUR PAYOUT MONTH';

  // Surface C: Circle Room & Rotation Wheel
  String get rotationWheelTitle => locale == 'ar' ? 'عجلة التدوير التفاعلية' : 'INTERACTIVE ROTATION WHEEL';
  String get wheelSubtitle => locale == 'ar' ? 'اضغط على أي دور لعرض بيانات العضو والدفع' : 'Tap any slot node to view member & payment details';
  String get monthlyDue => locale == 'ar' ? 'القسط الشهري' : 'Monthly Due';
  String get totalPayout => locale == 'ar' ? 'إجمالي القبض' : 'Total Payout';
  String get pairPayout => locale == 'ar' ? 'قبض الزوج' : 'Pair Payout';
  String get cycleProgress => locale == 'ar' ? 'تقدم الدورة' : 'Cycle Progress';
  String monthProgress(int current, int total) => locale == 'ar' ? 'الشهر $current من $total' : 'Month $current of $total';
  String get circleMembers => locale == 'ar' ? 'أعضاء الجمعية' : 'Circle Members';
  String get repayingAdvancePayout => locale == 'ar' ? 'سداد الدفعة المقدمة' : 'Repaying Advance Payout';
  String get accumulatingSavings => locale == 'ar' ? 'ادخار تراكمي' : 'Accumulating Savings';
  String get claimPayoutNow => locale == 'ar' ? 'استلم مبلغ القبض الآن' : 'Claim Your Payout Now';
  String payMonthlyDue(String amount) => locale == 'ar' ? 'ادفع القسط الشهري ($amount)' : 'Pay $amount Monthly Contribution';

  // Surface D: Activity & Profile
  String get activityTitle => locale == 'ar' ? 'سجل المعاملات والنشاط المالي' : 'Financial Activity & History';
  String get activitySubtitle => locale == 'ar' ? 'سجل موحد لجميع أقساط ودفعات جمعياتك' : 'Unified timeline across all your active and past circles';
  String get profileTitle => locale == 'ar' ? 'الملف الشخصي والإعدادات' : 'Member Profile & Settings';
  String get identityVerified => locale == 'ar' ? 'الهوية موثقة بالكامل ✓' : 'Identity Fully Verified ✓';
  String get payoutDestination => locale == 'ar' ? 'حساب استلام القبض' : 'Payout Destination Account';
  String get languagePreference => locale == 'ar' ? 'لغة التطبيق' : 'Language Preference';
  String get notificationsSettings => locale == 'ar' ? 'تفضيلات الإشعارات' : 'Notification Preferences';
  String get trustScoreLabel => locale == 'ar' ? 'درجة الثقة والمصداقية' : 'Member Trust Score';
  String get completedCirclesLabel => locale == 'ar' ? 'جمعيات مكتملة بنجاح' : 'Successfully Completed Circles';

  // Create Game'ya Wizard
  String get createWizardTitle => locale == 'ar' ? 'إنشاء جمعية جديدة' : 'Create New Game\'ya';
  String get stepGoalName => locale == 'ar' ? '١. اسم وهدف الجمعية' : '1. Goal & Circle Name';
  String get stepMonthlyAmount => locale == 'ar' ? '٢. القسط الشهري' : '2. Monthly Contribution';
  String get stepDuration => locale == 'ar' ? '٣. مدة الجمعية وعدد الأعضاء' : '3. Duration & Member Capacity';
  String get stepAllocationMode => locale == 'ar' ? '٤. نظام توزيع الأدوار' : '4. Allocation & Rotation Mode';
  String get stepCreatorPosition => locale == 'ar' ? '٥. دور المنظم (أنت)' : '5. Organizer Payout Turn';
  String get stepReviewRules => locale == 'ar' ? '٦. مراجعة القواعد واللائحة' : '6. Review Rules & Bylaws';
  String get stepPublish => locale == 'ar' ? '٧. نشر الجمعية ودعوة الأعضاء' : '7. Launch Circle & Invite';

  // Phase 47.2.5: Contribution & Payout Financial Action Flows
  String get reviewContribution => locale == 'ar' ? 'مراجعة المساهمة' : 'Review Contribution';
  String get confirmContribution => locale == 'ar' ? 'تأكيد المساهمة' : 'Confirm Contribution';
  String get reviewPayout => locale == 'ar' ? 'مراجعة الاستحقاق' : 'Review Payout';
  String get claimPayout => locale == 'ar' ? 'صرف الاستحقاق' : 'Claim Payout';
  String get continueAction => locale == 'ar' ? 'متابعة' : 'Continue';
  String get cancelAction => locale == 'ar' ? 'إلغاء' : 'Cancel';
  String get returnToCircle => locale == 'ar' ? 'العودة للجمعية' : 'Return to Game\'ya';
  String get pairedPayoutExplanation => locale == 'ar'
      ? 'يتم تقسيم مستحقاتك إلى نصفين متساويين على الدورين المرتبطين بك.'
      : 'Your payout is split into two equal halves across your paired positions.';
  String get financialTransactionsDisabledNotice => locale == 'ar'
      ? 'المعاملات المالية الحقيقية معطلة حاليًا (وضع المحاكاة نشط).'
      : 'Financial transactions are currently disabled (Simulation Mode Active).';
  String get financialSafetyLockNotice => locale == 'ar'
      ? 'المعاملات المالية متوقفة مؤقتًا لأسباب تتعلق بالسلامة.'
      : 'Financial actions are temporarily locked for safety.';
  String get offlineNotice => locale == 'ar'
      ? 'أنت غير متصل بالإنترنت. قد تظل المعلومات التي تم تحميلها سابقًا ظاهرة.'
      : 'You\'re offline. Previously loaded information may still be visible.';
}
