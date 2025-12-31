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

**Budget Distribution**:
   - Package 1 (Economy): Around the minimum budget (${budgetMin})
   - Package 2 (Standard): Around the middle of range (${(budgetMin + budgetMax) / 2})
   - Package 3 (Premium): Around the maximum budget (${budgetMax})

      2. **Service Priority**:
         - Adjust service priorities based on "${eventType}".
         - If user tags emphasize a specific service (e.g., "Great Food"), increase priority and budget weight for Catering.

      3. **AI Tags Logic (CRITICAL)**:
         - You MUST include relevant tags from the user's "Specific Style/Requirement Tags" in the 'aiTags' list for the appropriate services.
         - EXAMPLE: If user tag is "Outdoor", add "Outdoor" to the Venue service tags.
         - EXAMPLE: If user tag is "Buffet", add "Buffet" to the Catering service tags.
         - **HYBRID APPROACH**: Mix user tags with quality-level tags:
           * Economy: Combine [User Tags] + ["Basic", "Affordable", "Simple"]
           * Standard: Combine [User Tags] + ["Professional", "Reliable", "Good Value"]
           * Premium: Combine [User Tags] + ["Luxury", "High-End", "Exclusive"]
         - If the user tags are not sufficient for search, intelligently ADD related tags to ensure good search results.

      4. **Required Services Structure**:
         Return ONLY a valid JSON object matching the AiSearchBlueprint schema.
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
        const blueprint: AiSearchBlueprint = JSON.parse(jsonText);
        return blueprint;

    } catch (error) {
        this.logger.error(`AI Search API Error:`, error);
        throw new Error(`Failed to extract search filters using AI: ${error.message}`);
    }
  }
}