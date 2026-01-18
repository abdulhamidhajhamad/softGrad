// compliance.constants.ts
// Compliance and verification system constants and patterns

/**
 * Provider verification statuses
 */
export enum VerificationStatus {
  /** No documents uploaded yet */
  PENDING = 'pending',
  
  /** Documents are being reviewed by the system */
  UNDER_REVIEW = 'under_review',
  
  /** Successfully verified */
  VERIFIED = 'verified',
  
  /** Requires manual review by admin */
  ADMIN_REVIEW = 'admin_review',
  
  /** Documents were rejected */
  REJECTED = 'rejected',
  
  /** Documents have expired */
  EXPIRED = 'expired',
  
  /** Account deactivated due to non-renewal */
  DEACTIVATED = 'deactivated',
}

/**
 * Supported document types
 */
export enum DocumentType {
  /** National ID card */
  NATIONAL_ID = 'national_id',
  
  /** Business registration certificate / Commercial register */
  BUSINESS_LICENSE = 'business_license',
  
  /** Professional practice license */
  PROFESSIONAL_LICENSE = 'professional_license',
}

/**
 * Provider types
 */
export enum ProviderType {
  /** Individual / Natural person */
  INDIVIDUAL = 'individual',
  
  /** Business / Company */
  BUSINESS = 'business',
}

/**
 * Rejection reasons
 */
export enum RejectionReason {
  /** Expired document */
  EXPIRED_DOCUMENT = 'expired_document',
  
  /** Unclear document */
  UNCLEAR_DOCUMENT = 'unclear_document',
  
  /** Data mismatch */
  DATA_MISMATCH = 'data_mismatch',
  
  /** Invalid document */
  INVALID_DOCUMENT = 'invalid_document',
  
  /** Invalid ID number */
  INVALID_ID_NUMBER = 'invalid_id_number',
}

/**
 * Patterns used to extract data from Arabic documents
 * Enhanced patterns for Tesseract OCR compatibility
 */
export const ARABIC_PATTERNS = {
  // Issue date pattern: صدرت هذه الشهادة بتاريخ 2025/6/30 or 2025/06/30
  ISSUE_DATE: /صدرت\s*(?:هذه\s*)?(?:الشهادة|الوثيقة)?\s*بتاريخ\s*(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/i,
  
  // Alternative: تاريخ الإصدار: or تاريخ التحرير:
  ISSUE_DATE_ALT: /تاريخ\s*(?:الإصدار|الاصدار|التسجيل|التحرير)\s*[:\s]*(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/i,
  
  // Generic date patterns YYYY/M/DD or YYYY/MM/DD (Arabic documents)
  DATE_GENERIC: /(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/g,
  
  // Pattern: DD/MM/YYYY (common in Arabic docs like 30/06/2025)
  DATE_REVERSE: /(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})/g,
  
  // Expiry date pattern
  EXPIRY_DATE: /(?:تاريخ\s*(?:الانتهاء|الإنتهاء|صلاحية)|صالحة?\s*(?:حتى|لغاية))\s*[:\s]*(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})/i,
  
  // Palestinian ID number pattern (9 digits)
  PALESTINIAN_ID: /(?:رقم\s*(?:الهوية|الهويه|البطاقة)|هوية\s*رقم)\s*[:\s]*(\d{9})/i,
  
  // Direct ID number pattern (9 consecutive digits)
  ID_NUMBER_DIRECT: /\b(\d{9})\b/g,
  
  // Business name pattern
  BUSINESS_NAME: /(?:اسم\s*(?:المنشأة|الشركة|المؤسسة)|المنشأة\s*[:\s])\s*(.+?)(?:\n|$)/i,
  
  // Commercial registration number pattern
  COMMERCIAL_REG: /(?:رقم\s*(?:السجل\s*التجاري|التسجيل)|سجل\s*تجاري\s*رقم)\s*[:\s]*(\d+)/i,
};

/**
 * Verification system settings
 */
export const VERIFICATION_CONFIG = {
  /** Minimum name similarity threshold (50%) */
  NAME_SIMILARITY_THRESHOLD: 0.5,
  
  /** Minimum first name similarity threshold (60%) */
  FIRST_NAME_SIMILARITY_THRESHOLD: 0.6,
  
  /** Palestinian ID number length */
  PALESTINIAN_ID_LENGTH: 9,
  
  /** Days before expiry to send first warning */
  EXPIRY_WARNING_DAYS: 30,
  
  /** License validity period in days (one year) */
  LICENSE_VALIDITY_DAYS: 365,
  
  /** Weekly reminder interval in days */
  WEEKLY_REMINDER_INTERVAL: 7,
  
  /** Maximum number of reminders (4 weeks) */
  MAX_REMINDERS_COUNT: 4,
  
  /** Days after expiry before account deactivation */
  DEACTIVATION_GRACE_PERIOD_DAYS: 30,
};

/**
 * Notification messages
 */
export const NOTIFICATION_MESSAGES = {
  // Warning before expiry
  EXPIRY_WARNING: {
    title: 'Warning: Documents Expiring Soon',
    body: 'Your documents will expire in {days} days. Please renew them to avoid service interruption.',
  },
  
  // Expiry notification
  EXPIRED: {
    title: 'Your Documents Have Expired',
    body: 'Your verification documents have expired. Your services are temporarily disabled until renewal.',
  },
  
  // Weekly reminder
  WEEKLY_REMINDER: {
    title: 'Document Renewal Reminder',
    body: 'Your documents are still expired. Please renew them to restore your services. ({remaining} reminders remaining)',
  },
  
  // Account deactivation
  DEACTIVATED: {
    title: 'Your Account Has Been Deactivated',
    body: 'Your account has been deactivated due to document non-renewal. Contact support for reactivation.',
  },
  
  // Successful verification
  VERIFIED: {
    title: 'Documents Verified Successfully',
    body: 'Congratulations! Your documents have been verified successfully. You can now add your services.',
  },
  
  // Under review
  ADMIN_REVIEW: {
    title: 'Documents Under Review',
    body: 'Your documents have been forwarded for manual review. You will be notified of the result soon.',
  },
  
  // Rejection
  REJECTED: {
    title: 'Documents Rejected',
    body: 'Unfortunately, your documents were rejected. Reason: {reason}. Please re-upload valid documents.',
  },
};

/**
 * Supabase storage folder names
 */
export const STORAGE_FOLDERS = {
  COMPLIANCE_DOCUMENTS: 'compliance-documents',
  NATIONAL_IDS: 'compliance-documents/national-ids',
  BUSINESS_LICENSES: 'compliance-documents/business-licenses',
};

/**
 * Common Arabic name mappings for matching
 * Can be extended as needed
 */
export const ARABIC_NAME_MAPPINGS: Record<string, string[]> = {
  // Common male names
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
  
  // Common female names
  'fatima': ['فاطمة', 'فاطمه'],
  'aisha': ['عائشة', 'عايشة'],
  'maryam': ['مريم', 'مريام'],
  'sara': ['سارة', 'ساره'],
  'hana': ['هناء', 'هنا'],
  'noor': ['نور', 'نورا'],
  'layla': ['ليلى', 'ليلة'],
  'reem': ['ريم', 'ريما'],
};
