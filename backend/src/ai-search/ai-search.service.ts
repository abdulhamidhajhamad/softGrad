// src/ai-search/ai-search.service.ts

import { Injectable, Logger } from '@nestjs/common';
import { GoogleGenAI } from '@google/genai';
import { AiSearchFilters } from './ai-search.interface'; 
import { AiSearchBlueprint } from './ai-search.interface'; 

@Injectable()
export class AiSearchService {
  private readonly logger = new Logger(AiSearchService.name);
  private readonly ai: GoogleGenAI;

  constructor() {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      this.logger.error('GEMINI_API_KEY is not set.');
      throw new Error('AI Search Service failed to initialize.');
    }
    this.ai = new GoogleGenAI({ apiKey });
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
    endTime?: string
  ): Promise<AiSearchBlueprint> {
    
    this.logger.log(`AI Search: ${eventType} in ${city}, Tags: [${userTags.join(', ')}]`);

    // 🆕 تحضير النص الخاص بتفضيلات المستخدم لإضافته للبرومبت
    const userPreferencesText = `
      USER PREFERENCES (MUST BE RESPECTED):
      - Specific Style/Requirement Tags: [${userTags.join(', ')}]
      - Additional Notes: "${additionalNotes || 'None'}"
    `;

    // حساب البدجت المتوسط والباكجات الثلاثة
    const averageBudget = (budgetMin + budgetMax) / 2;
    const budgetMinus15 = Math.round(averageBudget * 0.85);
    const budgetPlus15 = Math.round(averageBudget * 1.15);

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

      CRITICAL INSTRUCTIONS:

      1. **Budget Distribution (VERY IMPORTANT)**:
         - Package 1 (Budget-Friendly): Target price = ${budgetMinus15} (15% BELOW average budget)
         - Package 2 (Standard): Target price = ${Math.round(averageBudget)} (Within the budget range)
         - Package 3 (Premium): Target price = ${budgetPlus15} (15% ABOVE average budget)

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

    try {
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
        
        return blueprint;

    } catch (error) {
        this.logger.error(`AI Search API Error:`, error);
        throw new Error(`Failed to extract search filters using AI: ${error.message}`);
    }
  }
}