// ocr-parser.util.ts
import { Logger } from '@nestjs/common';
import { 
  ARABIC_PATTERNS, 
  VERIFICATION_CONFIG,
  ARABIC_NAME_MAPPINGS 
} from '../constants/compliance.constants';

const logger = new Logger('OCRParser');

/**
 * نتيجة تحليل الوثيقة
 */
export interface ParsedDocumentData {
  idNumber: string | null;
  extractedName?: string;
  issueDate: Date | null;
  expiryDate: Date | null;
  businessName: string | null;
  commercialRegNumber: string | null;
  rawText: string;
  confidence: number;
  allFoundIdNumbers: string[];
  allFoundDates: Date[];
}

/**
 * نتيجة مطابقة الاسم
 */
export interface NameMatchResult {
  isMatch: boolean;
  similarityScore: number;
  firstNameMatch: boolean;
  matchedArabicName?: string;
}

/**
 * Extract issue date from Arabic text
 * Enhanced for Tesseract OCR - tries multiple patterns
 * Supports formats: 2025/6/30, 30/06/2025, etc.
 */
export function extractIssueDate(text: string): Date | null {
  try {
    // Pattern 1: صدرت هذه الشهادة بتاريخ 2025/6/30 (YYYY/M/DD)
    let match = text.match(ARABIC_PATTERNS.ISSUE_DATE);
    
    if (match) {
      const year = parseInt(match[1], 10);
      const month = parseInt(match[2], 10) - 1;
      const day = parseInt(match[3], 10);
      
      const date = new Date(year, month, day);
      
      if (isValidDate(date)) {
        logger.log(`✅ Issue date extracted (صدرت بتاريخ): ${date.toISOString()}`);
        return date;
      }
    }
    
    // Pattern 2: تاريخ التحرير: 30/06/2025 (DD/MM/YYYY)
    match = text.match(ARABIC_PATTERNS.ISSUE_DATE_ALT);
    if (match) {
      const day = parseInt(match[1], 10);
      const month = parseInt(match[2], 10) - 1;
      const year = parseInt(match[3], 10);
      
      const date = new Date(year, month, day);
      
      if (isValidDate(date)) {
        logger.log(`✅ Issue date extracted (تاريخ التحرير): ${date.toISOString()}`);
        return date;
      }
    }
    
    // Fallback: Try generic YYYY/M/DD format anywhere in text
    const genericMatches = [...text.matchAll(ARABIC_PATTERNS.DATE_GENERIC)];
    for (const genericMatch of genericMatches) {
      const year = parseInt(genericMatch[1], 10);
      const month = parseInt(genericMatch[2], 10) - 1;
      const day = parseInt(genericMatch[3], 10);
      
      if (year >= 2020 && year <= 2030) {
        const date = new Date(year, month, day);
        if (isValidDate(date)) {
          logger.log(`✅ Issue date extracted (generic YYYY/M/DD): ${date.toISOString()}`);
          return date;
        }
      }
    }
    
    // Fallback: Try DD/MM/YYYY format (like 30/06/2025)
    const reverseMatches = [...text.matchAll(ARABIC_PATTERNS.DATE_REVERSE)];
    for (const reverseMatch of reverseMatches) {
      const day = parseInt(reverseMatch[1], 10);
      const month = parseInt(reverseMatch[2], 10) - 1;
      const year = parseInt(reverseMatch[3], 10);
      
      if (year >= 2020 && year <= 2030 && day <= 31 && month <= 11) {
        const date = new Date(year, month, day);
        if (isValidDate(date)) {
          logger.log(`✅ Issue date extracted (DD/MM/YYYY): ${date.toISOString()}`);
          return date;
        }
      }
    }
    
    logger.warn('⚠️ No issue date found in expected format');
    return null;
  } catch (error) {
    logger.error(`❌ Error extracting issue date: ${error.message}`);
    return null;
  }
}

/**
 * حساب تاريخ انتهاء الصلاحية
 * يضيف سنة كاملة (365 يوم) إلى تاريخ الإصدار
 */
export function calculateExpiryDate(issueDate: Date): Date {
  const expiryDate = new Date(issueDate);
  expiryDate.setDate(expiryDate.getDate() + VERIFICATION_CONFIG.LICENSE_VALIDITY_DAYS);
  logger.log(`📅 تاريخ الانتهاء المحسوب: ${expiryDate.toISOString()}`);
  return expiryDate;
}

/**
 * استخراج تاريخ الانتهاء من النص (إن وجد)
 */
export function extractExpiryDate(text: string): Date | null {
  try {
    const match = text.match(ARABIC_PATTERNS.EXPIRY_DATE);
    
    if (match) {
      const year = parseInt(match[1], 10);
      const month = parseInt(match[2], 10) - 1;
      const day = parseInt(match[3], 10);
      
      const date = new Date(year, month, day);
      
      if (isValidDate(date)) {
        logger.log(`✅ تم استخراج تاريخ الانتهاء: ${date.toISOString()}`);
        return date;
      }
    }
    
    return null;
  } catch (error) {
    logger.error(`❌ خطأ في استخراج تاريخ الانتهاء: ${error.message}`);
    return null;
  }
}

/**
 * استخراج رقم الهوية الفلسطينية (9 أرقام)
 */
export function extractIdNumber(text: string): { primary: string | null; all: string[] } {
  const allIds: string[] = [];
  
  try {
    // البحث عن النمط المحدد أولاً
    const specificMatch = text.match(ARABIC_PATTERNS.PALESTINIAN_ID);
    if (specificMatch) {
      allIds.push(specificMatch[1]);
    }
    
    // البحث عن أي 9 أرقام متتالية
    const directMatches = text.matchAll(ARABIC_PATTERNS.ID_NUMBER_DIRECT);
    for (const match of directMatches) {
      if (!allIds.includes(match[1])) {
        allIds.push(match[1]);
      }
    }
    
    // إزالة الأرقام التي تبدو كتواريخ (مثل 20240115)
    const filteredIds = allIds.filter(id => {
      // استبعاد الأرقام التي تبدأ بـ 20 أو 19 (سنوات)
      if (id.startsWith('20') || id.startsWith('19')) {
        return false;
      }
      return true;
    });
    
    if (filteredIds.length > 0) {
      logger.log(`✅ تم العثور على ${filteredIds.length} رقم هوية محتمل`);
      return { primary: filteredIds[0], all: filteredIds };
    }
    
    // إذا لم نجد أرقام مفلترة، نعيد الأرقام الأصلية
    if (allIds.length > 0) {
      return { primary: allIds[0], all: allIds };
    }
    
    logger.warn('⚠️ لم يتم العثور على رقم هوية');
    return { primary: null, all: [] };
  } catch (error) {
    logger.error(`❌ خطأ في استخراج رقم الهوية: ${error.message}`);
    return { primary: null, all: [] };
  }
}

/**
 * استخراج اسم المنشأة
 */
export function extractBusinessName(text: string): string | null {
  try {
    const match = text.match(ARABIC_PATTERNS.BUSINESS_NAME);
    if (match) {
      const name = match[1].trim();
      logger.log(`✅ تم استخراج اسم المنشأة: ${name}`);
      return name;
    }
    return null;
  } catch (error) {
    logger.error(`❌ خطأ في استخراج اسم المنشأة: ${error.message}`);
    return null;
  }
}

/**
 * استخراج رقم السجل التجاري
 */
export function extractCommercialRegNumber(text: string): string | null {
  try {
    const match = text.match(ARABIC_PATTERNS.COMMERCIAL_REG);
    if (match) {
      logger.log(`✅ تم استخراج رقم السجل التجاري: ${match[1]}`);
      return match[1];
    }
    return null;
  } catch (error) {
    logger.error(`❌ خطأ في استخراج رقم السجل التجاري: ${error.message}`);
    return null;
  }
}

/**
 * تحليل كامل للوثيقة
 */
export function parseDocument(text: string, isBusinessDocument: boolean = false): ParsedDocumentData {
  logger.log('🔍 بدء تحليل الوثيقة...');
  
  const idResult = extractIdNumber(text);
  const issueDate = extractIssueDate(text);
  let expiryDate = extractExpiryDate(text);
  
  // إذا لم نجد تاريخ انتهاء، نحسبه من تاريخ الإصدار
  if (!expiryDate && issueDate) {
    expiryDate = calculateExpiryDate(issueDate);
  }
  
  const result: ParsedDocumentData = {
    idNumber: idResult.primary,
    issueDate,
    expiryDate,
    rawText: text,
    confidence: calculateConfidence(text, issueDate, idResult.primary),
    allFoundIdNumbers: idResult.all,
    allFoundDates: issueDate ? [issueDate] : [],
    businessName: null,
    commercialRegNumber: null,
  };
  
  if (isBusinessDocument) {
    result.businessName = extractBusinessName(text);
    result.commercialRegNumber = extractCommercialRegNumber(text);
  }
  
  logger.log(`📊 نتيجة التحليل - الثقة: ${result.confidence}`);
  return result;
}

/**
 * حساب مستوى الثقة في الاستخراج
 */
function calculateConfidence(text: string, issueDate: Date | null, idNumber: string | null): number {
  let confidence = 0.3; // قاعدة أساسية للنص
  
  if (text.length > 50) confidence += 0.1;
  if (text.length > 200) confidence += 0.1;
  if (issueDate) confidence += 0.25;
  if (idNumber) confidence += 0.25;
  
  return Math.min(confidence, 1.0);
}

/**
 * التحقق من صحة التاريخ
 */
function isValidDate(date: Date): boolean {
  if (!(date instanceof Date) || isNaN(date.getTime())) {
    return false;
  }
  
  const year = date.getFullYear();
  // التاريخ يجب أن يكون بين 1990 و 2050
  return year >= 1990 && year <= 2050;
}

/**
 * التحقق من صلاحية الوثيقة
 */
export function isDocumentValid(expiryDate: Date): { isValid: boolean; daysRemaining: number } {
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  const expiry = new Date(expiryDate);
  expiry.setHours(0, 0, 0, 0);
  
  const diffTime = expiry.getTime() - today.getTime();
  const daysRemaining = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  
  return {
    isValid: daysRemaining > 0,
    daysRemaining,
  };
}

/**
 * مطابقة الاسم الإنجليزي مع العربي
 * يستخدم مكتبة string-similarity
 */
export async function matchNames(
  englishName: string, 
  arabicText: string
): Promise<NameMatchResult> {
  try {
    // استيراد المكتبة ديناميكياً
    const stringSimilarity = await import('string-similarity');
    
    const englishNameLower = englishName.toLowerCase().trim();
    const englishParts = englishNameLower.split(/\s+/);
    const englishFirstName = englishParts[0];
    
    // استخراج الأسماء المحتملة من النص العربي
    const arabicNames = extractArabicNames(arabicText);
    
    let bestScore = 0;
    let bestMatch = '';
    let firstNameMatch = false;
    
    // البحث في الأسماء المستخرجة
    for (const arabicName of arabicNames) {
      // المقارنة المباشرة (للأسماء المتشابهة)
      const directScore = stringSimilarity.compareTwoStrings(
        englishNameLower, 
        transliterateArabicToEnglish(arabicName)
      );
      
      if (directScore > bestScore) {
        bestScore = directScore;
        bestMatch = arabicName;
      }
    }
    
    // التحقق من تطابق الاسم الأول
    const mappedArabicNames = ARABIC_NAME_MAPPINGS[englishFirstName] || [];
    for (const arabicName of arabicNames) {
      for (const mappedName of mappedArabicNames) {
        if (arabicName.includes(mappedName)) {
          firstNameMatch = true;
          break;
        }
      }
    }
    
    // إذا لم نجد تطابق في القاموس، نستخدم التحويل الصوتي
    if (!firstNameMatch && arabicNames.length > 0) {
      const firstArabicPart = arabicNames[0].split(/\s+/)[0];
      const transliterated = transliterateArabicToEnglish(firstArabicPart);
      const firstNameScore = stringSimilarity.compareTwoStrings(
        englishFirstName,
        transliterated
      );
      firstNameMatch = firstNameScore >= VERIFICATION_CONFIG.FIRST_NAME_SIMILARITY_THRESHOLD;
    }
    
    const isMatch = bestScore >= VERIFICATION_CONFIG.NAME_SIMILARITY_THRESHOLD;
    
    logger.log(`📝 نتيجة مطابقة الاسم - النسبة: ${bestScore}, تطابق: ${isMatch}`);
    
    return {
      isMatch,
      similarityScore: bestScore,
      firstNameMatch,
      matchedArabicName: bestMatch || undefined,
    };
  } catch (error) {
    logger.error(`❌ خطأ في مطابقة الأسماء: ${error.message}`);
    return {
      isMatch: false,
      similarityScore: 0,
      firstNameMatch: false,
    };
  }
}

/**
 * استخراج الأسماء العربية من النص
 */
function extractArabicNames(text: string): string[] {
  const names: string[] = [];
  
  // أنماط الأسماء العربية
  const namePatterns = [
    /(?:الاسم|اسم)\s*[:\s]*(.+?)(?:\n|$)/gi,
    /(?:السيد|السيدة|الأستاذ|الأستاذة)\s*[:\s]*(.+?)(?:\n|$)/gi,
  ];
  
  for (const pattern of namePatterns) {
    const matches = text.matchAll(pattern);
    for (const match of matches) {
      if (match[1]) {
        names.push(match[1].trim());
      }
    }
  }
  
  // إذا لم نجد أسماء بالأنماط، نبحث عن كلمات عربية متتالية
  if (names.length === 0) {
    const arabicWords = text.match(/[\u0600-\u06FF]+(?:\s+[\u0600-\u06FF]+){1,4}/g);
    if (arabicWords) {
      names.push(...arabicWords.slice(0, 5)); // أول 5 نتائج فقط
    }
  }
  
  return names;
}

/**
 * تحويل صوتي بسيط من العربية للإنجليزية
 */
function transliterateArabicToEnglish(arabicText: string): string {
  const translitMap: Record<string, string> = {
    'ا': 'a', 'أ': 'a', 'إ': 'i', 'آ': 'aa',
    'ب': 'b', 'ت': 't', 'ث': 'th',
    'ج': 'j', 'ح': 'h', 'خ': 'kh',
    'د': 'd', 'ذ': 'th', 'ر': 'r', 'ز': 'z',
    'س': 's', 'ش': 'sh', 'ص': 's', 'ض': 'd',
    'ط': 't', 'ظ': 'z', 'ع': 'a', 'غ': 'gh',
    'ف': 'f', 'ق': 'q', 'ك': 'k', 'ل': 'l',
    'م': 'm', 'ن': 'n', 'ه': 'h', 'ة': 'a',
    'و': 'w', 'ي': 'y', 'ى': 'a',
    'ء': '', 'ئ': 'e', 'ؤ': 'o',
  };
  
  let result = '';
  for (const char of arabicText) {
    result += translitMap[char] || char;
  }
  
  return result.toLowerCase().replace(/\s+/g, ' ').trim();
}

/**
 * مقارنة أرقام الهوية
 */
export function compareIdNumbers(systemId: string, extractedIds: string[]): boolean {
  const normalizedSystemId = systemId.replace(/\D/g, '');
  
  for (const extractedId of extractedIds) {
    const normalizedExtractedId = extractedId.replace(/\D/g, '');
    if (normalizedSystemId === normalizedExtractedId) {
      logger.log('✅ تطابق رقم الهوية');
      return true;
    }
  }
  
  logger.warn('⚠️ لم يتطابق رقم الهوية');
  return false;
}

/**
 * إخفاء جزء من رقم الهوية للعرض
 */
export function maskIdNumber(idNumber: string): string {
  if (!idNumber || idNumber.length < 4) {
    return '***';
  }
  return '***' + idNumber.slice(-6);
}
