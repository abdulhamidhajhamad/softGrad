// compliance.constants.ts
// ثوابت وأنماط نظام التوثيق والامتثال

/**
 * حالات التحقق من المزود
 */
export enum VerificationStatus {
  /** لم يتم رفع أي وثائق بعد */
  PENDING = 'pending',
  
  /** الوثائق قيد المراجعة من قبل النظام */
  UNDER_REVIEW = 'under_review',
  
  /** تم التحقق بنجاح */
  VERIFIED = 'verified',
  
  /** يحتاج مراجعة يدوية من المشرف */
  ADMIN_REVIEW = 'admin_review',
  
  /** تم رفض الوثائق */
  REJECTED = 'rejected',
  
  /** انتهت صلاحية الوثائق */
  EXPIRED = 'expired',
  
  /** تم تعطيل الحساب بسبب عدم التجديد */
  DEACTIVATED = 'deactivated',
}

/**
 * أنواع الوثائق المدعومة
 */
export enum DocumentType {
  /** بطاقة الهوية الشخصية */
  NATIONAL_ID = 'national_id',
  
  /** شهادة تسجيل المنشأة / السجل التجاري */
  BUSINESS_LICENSE = 'business_license',
  
  /** رخصة مزاولة المهنة */
  PROFESSIONAL_LICENSE = 'professional_license',
}

/**
 * أنواع المزودين
 */
export enum ProviderType {
  /** فرد / شخص طبيعي */
  INDIVIDUAL = 'individual',
  
  /** مؤسسة / شركة */
  BUSINESS = 'business',
}

/**
 * أسباب الرفض
 */
export enum RejectionReason {
  /** وثيقة منتهية الصلاحية */
  EXPIRED_DOCUMENT = 'expired_document',
  
  /** وثيقة غير واضحة */
  UNCLEAR_DOCUMENT = 'unclear_document',
  
  /** عدم تطابق البيانات */
  DATA_MISMATCH = 'data_mismatch',
  
  /** وثيقة غير صالحة */
  INVALID_DOCUMENT = 'invalid_document',
  
  /** رقم الهوية غير صحيح */
  INVALID_ID_NUMBER = 'invalid_id_number',
}

/**
 * الأنماط المستخدمة لاستخراج البيانات من الوثائق العربية
 */
export const ARABIC_PATTERNS = {
  // نمط تاريخ الإصدار: صدرت هذه الشهادة بتاريخ YYYY/MM/DD
  ISSUE_DATE: /صدرت\s*(?:هذه\s*)?(?:الشهادة|الوثيقة)?\s*بتاريخ\s*(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/i,
  
  // نمط تاريخ بديل: تاريخ الإصدار: YYYY/MM/DD
  ISSUE_DATE_ALT: /تاريخ\s*(?:الإصدار|الاصدار)\s*[:\s]*(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/i,
  
  // نمط تاريخ الانتهاء (إن وجد)
  EXPIRY_DATE: /(?:تاريخ\s*(?:الانتهاء|الإنتهاء|صلاحية)|صالحة?\s*(?:حتى|لغاية))\s*[:\s]*(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/i,
  
  // نمط رقم الهوية الفلسطينية (9 أرقام)
  PALESTINIAN_ID: /(?:رقم\s*(?:الهوية|الهويه|البطاقة)|هوية\s*رقم)\s*[:\s]*(\d{9})/i,
  
  // نمط رقم الهوية المباشر (9 أرقام متتالية)
  ID_NUMBER_DIRECT: /\b(\d{9})\b/g,
  
  // نمط اسم المنشأة
  BUSINESS_NAME: /(?:اسم\s*(?:المنشأة|الشركة|المؤسسة)|المنشأة\s*[:\s])\s*(.+?)(?:\n|$)/i,
  
  // نمط رقم السجل التجاري
  COMMERCIAL_REG: /(?:رقم\s*(?:السجل\s*التجاري|التسجيل)|سجل\s*تجاري\s*رقم)\s*[:\s]*(\d+)/i,
};

/**
 * إعدادات نظام التحقق
 */
export const VERIFICATION_CONFIG = {
  /** الحد الأدنى لنسبة تشابه الاسم (50%) */
  NAME_SIMILARITY_THRESHOLD: 0.5,
  
  /** الحد الأدنى لتشابه الاسم الأول فقط (60%) */
  FIRST_NAME_SIMILARITY_THRESHOLD: 0.6,
  
  /** طول رقم الهوية الفلسطينية */
  PALESTINIAN_ID_LENGTH: 9,
  
  /** عدد الأيام قبل الانتهاء لإرسال التنبيه الأول */
  EXPIRY_WARNING_DAYS: 30,
  
  /** مدة صلاحية الشهادة بالأيام (سنة واحدة) */
  LICENSE_VALIDITY_DAYS: 365,
  
  /** فترة التذكير الأسبوعي بالأيام */
  WEEKLY_REMINDER_INTERVAL: 7,
  
  /** الحد الأقصى للتذكيرات (4 أسابيع) */
  MAX_REMINDERS_COUNT: 4,
  
  /** عدد الأيام بعد الانتهاء قبل تعطيل الحساب */
  DEACTIVATION_GRACE_PERIOD_DAYS: 30,
};

/**
 * رسائل الإشعارات
 */
export const NOTIFICATION_MESSAGES = {
  // تنبيه قبل الانتهاء
  EXPIRY_WARNING: {
    title: 'تنبيه: اقتراب انتهاء صلاحية الوثائق',
    body: 'ستنتهي صلاحية وثائقك خلال {days} يوم. يرجى تجديدها لتجنب تعطيل خدماتك.',
  },
  
  // إشعار انتهاء الصلاحية
  EXPIRED: {
    title: 'انتهت صلاحية وثائقك',
    body: 'انتهت صلاحية وثائق التحقق الخاصة بك. تم تعطيل خدماتك مؤقتاً حتى التجديد.',
  },
  
  // تذكير أسبوعي
  WEEKLY_REMINDER: {
    title: 'تذكير بتجديد الوثائق',
    body: 'لا تزال وثائقك منتهية الصلاحية. يرجى التجديد لاستعادة خدماتك. ({remaining} تذكيرات متبقية)',
  },
  
  // تعطيل الحساب
  DEACTIVATED: {
    title: 'تم تعطيل حسابك',
    body: 'تم تعطيل حسابك بسبب عدم تجديد الوثائق. تواصل مع الدعم لإعادة التفعيل.',
  },
  
  // التحقق الناجح
  VERIFIED: {
    title: 'تم التحقق من وثائقك بنجاح',
    body: 'تهانينا! تم التحقق من وثائقك بنجاح. يمكنك الآن إضافة خدماتك.',
  },
  
  // قيد المراجعة
  ADMIN_REVIEW: {
    title: 'وثائقك قيد المراجعة',
    body: 'تم تحويل وثائقك للمراجعة اليدوية. سيتم إعلامك بالنتيجة قريباً.',
  },
  
  // الرفض
  REJECTED: {
    title: 'تم رفض وثائقك',
    body: 'للأسف تم رفض وثائقك. السبب: {reason}. يرجى إعادة الرفع بوثائق صحيحة.',
  },
};

/**
 * أسماء مجلدات التخزين في Supabase
 */
export const STORAGE_FOLDERS = {
  COMPLIANCE_DOCUMENTS: 'compliance-documents',
  NATIONAL_IDS: 'compliance-documents/national-ids',
  BUSINESS_LICENSES: 'compliance-documents/business-licenses',
};

/**
 * قائمة الأسماء العربية الشائعة للمطابقة
 * يمكن توسيعها حسب الحاجة
 */
export const ARABIC_NAME_MAPPINGS: Record<string, string[]> = {
  // الأسماء الذكورية الشائعة
  'mohammed': ['محمد', 'محمود', 'أحمد'],
  'ahmad': ['أحمد', 'احمد'],
  'mahmoud': ['محمود', 'محمد'],
  'ali': ['علي', 'علاء'],
  'omar': ['عمر', 'عمار'],
  'khaled': ['خالد', 'خليل'],
  'hassan': ['حسن', 'حسين'],
  'hussein': ['حسين', 'حسن'],
  'ibrahim': ['ابراهيم', 'إبراهيم'],
  'youssef': ['يوسف', 'يوسُف'],
  'abdulrahman': ['عبدالرحمن', 'عبد الرحمن'],
  'abdullah': ['عبدالله', 'عبد الله'],
  
  // الأسماء الأنثوية الشائعة
  'fatima': ['فاطمة', 'فاطمه'],
  'aisha': ['عائشة', 'عايشة'],
  'maryam': ['مريم', 'مريام'],
  'sara': ['سارة', 'ساره'],
  'hana': ['هناء', 'هنا'],
  'noor': ['نور', 'نورا'],
  'layla': ['ليلى', 'ليلة'],
  'reem': ['ريم', 'ريما'],
};
