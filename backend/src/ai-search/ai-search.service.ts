// src/ai-search/ai-search.service.ts

import { Injectable, Logger } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { AiSearchFilters } from './ai-search.interface'; 
import { AiSearchBlueprint } from './ai-search.interface'; 

// Interface for service priority with budget
interface ServicePriority {
  name: string;
  priority: number;
  budgetPercent?: number;
}

@Injectable()
export class AiSearchService {
  private readonly logger = new Logger(AiSearchService.name);
  private readonly ai: GoogleGenAI;
  private readonly MAX_RETRIES = 3;  // 🆕 Maximum retry attempts
  private readonly RETRY_DELAY = 2000; // 🆕 Delay between retries (2 seconds)

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      this.logger.error('GEMINI_API_KEY is not set.');
      throw new Error('AI Search Service failed to initialize.');
    }
    this.ai = new GoogleGenAI({ apiKey });
  }

  // 🆕 Helper function to delay execution
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * 🧠 استخلاص 3 باكجات بناءً على مدخلات اليوزر وتفضيلاته
   */
  async extractSearchFilters(
    city: string,
    guestCount: number,
    budgetMin: number,
    budgetMax: number,
    eventType: string,
    eventDate: string,
    userTags: string[],      // 🆕 قائمة التاجز من اليوزر
    additionalNotes?: string, // 🆕 ملاحظات إضافية
    startTime?: string,
    endTime?: string,
    servicePriorities?: ServicePriority[], // 🆕 أولويات الخدمات مع النسب
    budgetFlexibility?: number, // 🆕 نسبة المرونة في الميزانية
  ): Promise<AiSearchBlueprint> {
    
    this.logger.log(`AI Search: ${eventType} in ${city}, Tags: [${userTags.join(', ')}]`);

    // 🆕 تحضير النص الخاص بتفضيلات المستخدم لإضافته للبرومبت
    const userPreferencesText = `
      USER PREFERENCES (MUST BE RESPECTED):
      - Specific Style/Requirement Tags: [${userTags.join(', ')}]
      - Additional Notes: "${additionalNotes || 'None'}"
    `;

    // 🆕 NEW: Check if user provided budget percentages for services
    const hasUserBudgetPercentages = servicePriorities?.some(s => s.budgetPercent && s.budgetPercent > 0);
    
    // Build service constraints text if user provided percentages
    let serviceConstraintsText = '';
    if (hasUserBudgetPercentages && servicePriorities) {
      const servicesBudgetText = servicePriorities
        .filter(s => s.budgetPercent && s.budgetPercent > 0)
        .map(s => `  - ${s.name}: ~${s.budgetPercent}% of total budget (±5% tolerance)`)
        .join('\n');
      
      serviceConstraintsText = `
      USER-DEFINED BUDGET ALLOCATION (CRITICAL - MUST FOLLOW):
      The user has specified approximate budget percentages for each service type.
      You MUST respect these allocations with ±5% tolerance:
${servicesBudgetText}

      IMPORTANT: Convert these percentages to budgetWeight values (percentage/100).
      `;
    }

    // حساب البدجت المتوسط والباكجات الثلاثة
    const flexibility = budgetFlexibility || 15;
    const averageBudget = (budgetMin + budgetMax) / 2;
    const budgetMinus = Math.round(averageBudget * (1 - flexibility/100));
    const budgetPlus = Math.round(averageBudget * (1 + flexibility/100));

    const prompt = `
      You are an expert Event Planning AI. Your task is to create THREE comprehensive event packages based on the user's requirements.

      USER REQUIREMENTS:
      - City: "${city}"
      - Number of Guests: ${guestCount}
      - Budget Range: ${budgetMin} - ${budgetMax}
      - Event Type: "${eventType}"
      - Event Date: "${eventDate}"
      ${startTime && endTime ? `- Time: ${startTime} to ${endTime}` : ''}

      ${userPreferencesText}

      ${serviceConstraintsText}

      CRITICAL INSTRUCTIONS:

      1. **Budget Distribution (VERY IMPORTANT)**:
         - Package 1 (Budget-Friendly): Target price = ${budgetMinus} (${flexibility}% BELOW average budget)
         - Package 2 (Standard): Target price = ${Math.round(averageBudget)} (Within the budget range)
         - Package 3 (Premium): Target price = ${budgetPlus} (${flexibility}% ABOVE average budget)

      2. **Service Priority Based on Event Type (CRITICAL)**:
         - You MUST adjust service priorities based on the event type "${eventType}".
         - EXAMPLES:
           * "Business Lunch/Corporate Event": Venue (priority 1), Catering (priority 2), maybe Photography. NO DJ needed.
           * "Wedding": Venue (priority 1), Catering (priority 2), Photography (priority 3), DJ/Music (priority 4), Decoration (priority 5)
           * "Birthday Party": Venue (priority 1), Catering (priority 2), DJ/Music (priority 3), Decoration (priority 4)
           * "Conference": Venue (priority 1), Catering (priority 2), Audio/Visual Equipment (priority 3)
         - DO NOT include irrelevant services (e.g., DJ for a business meeting).
         - Higher priority = lower number (1 is highest priority).
         - Budget weight should reflect priority (higher priority services get more budget).

      3. **Location Filtering (MANDATORY)**:
         - ALL services MUST be available in the city: "${city}".
         - This is the MOST IMPORTANT filter - never suggest services from other cities.

      4. **AI Tags Logic (CRITICAL)**:
         - You MUST include relevant tags from the user's "Specific Style/Requirement Tags" in the 'aiTags' list for the appropriate services.
         - EXAMPLE: If user tag is "Outdoor", add "Outdoor" to the Venue service tags.
         - EXAMPLE: If user tag is "Indoor", add "Indoor" to the Venue service tags.
         - EXAMPLE: If user tag is "Buffet", add "Buffet" to the Catering service tags.
         - **HYBRID APPROACH**: Mix user tags with quality-level tags:
           * Budget-Friendly: Combine [User Tags] + ["Basic", "Affordable", "Simple", "Value"]
           * Standard: Combine [User Tags] + ["Professional", "Reliable", "Good Quality"]
           * Premium: Combine [User Tags] + ["Luxury", "High-End", "Exclusive", "Premium"]
         - Intelligently ADD related tags to ensure good search results.

      5. **Required Services Structure**:
         - Each service needs: categoryName, priority (1-10), budgetWeight (0.0-1.0, sum should be ~1.0), aiTags
         - Return ONLY a valid JSON object matching the AiSearchBlueprint schema.
    `;

    // 🆕 Retry logic for network issues
    let lastError: Error | null = null;
    
    for (let attempt = 1; attempt <= this.MAX_RETRIES; attempt++) {
      try {
        this.logger.log(`🤖 AI Request attempt ${attempt}/${this.MAX_RETRIES}...`);
        
        const response = await this.ai.models.generateContent({
            model: 'gemini-2.5-flash',
            contents: prompt,
            config: {
                responseMimeType: "application/json",
                responseSchema: {
                    type: "object",
                    properties: {
                        city: { type: "string" },
                        originalBudget: { type: "number" },
                        eventCategory: { type: "string" },
                        packages: { 
                            type: "array", 
                            items: {
                                type: "object",
                                properties: {
                                    packageName: { type: "string" },
                                    description: { type: "string" },
                                    targetPrice: { type: "number" },
                                    requiredServices: { 
                                        type: "array", 
                                        items: {
                                            type: "object",
                                            properties: {
                                                categoryName: { type: "string" },
                                                priority: { type: "number" },
                                                budgetWeight: { type: "number" },
                                                aiTags: { type: "array", items: { type: "string" } }
                                            },
                                            required: ["categoryName", "priority", "budgetWeight", "aiTags"]
                                        }
                                    }
                                },
                                required: ["packageName", "description", "targetPrice", "requiredServices"]
                            }
                        }
                    },
                    required: ["city", "originalBudget", "eventCategory", "packages"]
                }
            }
        });

        if (!response || !response.text) {
            throw new Error('Gemini API returned an empty or invalid text response.');
        }

        const jsonText = response.text.trim();
        const aiResponse = JSON.parse(jsonText);
        
        // 🆕 إضافة البيانات المهمة التي لا يرجعها الـ AI
        const blueprint: AiSearchBlueprint = {
            ...aiResponse,
            guestCount: guestCount,
            eventDate: eventDate,
            startTime: startTime,
            endTime: endTime,
        };
        
        this.logger.log(`✅ AI Request successful on attempt ${attempt}`);
        return blueprint;

      } catch (error) {
        lastError = error;
        this.logger.error(`❌ AI Request attempt ${attempt} failed:`, error.message);
        
        // Check if it's a network/fetch error and we should retry
        const isNetworkError = error.message?.includes('fetch') || 
                               error.message?.includes('network') ||
                               error.message?.includes('timeout') ||
                               error.message?.includes('ECONNRESET');
        
        if (isNetworkError && attempt < this.MAX_RETRIES) {
          this.logger.log(`⏳ Waiting ${this.RETRY_DELAY}ms before retry...`);
          await this.delay(this.RETRY_DELAY);
        } else if (!isNetworkError) {
          // Non-network error, don't retry
          break;
        }
      }
    }

    // All retries failed
    this.logger.error(`AI Search API Error after ${this.MAX_RETRIES} attempts:`, lastError);
    throw new Error(`Failed to extract search filters using AI: ${lastError?.message || 'Unknown error'}`);
  }
}