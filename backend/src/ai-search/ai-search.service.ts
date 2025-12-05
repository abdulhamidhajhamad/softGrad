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

    async extractSearchFilters(userPrompt: string): Promise<AiSearchBlueprint> {    this.logger.log(`Starting AI filter extraction for prompt: ${userPrompt.substring(0, 50)}...`);

        const prompt = `
            You are an expert Event Planner AI. Your task is to analyze the user's request
            (which is in English) and design THREE comprehensive event package blueprints.

            User Request: "${userPrompt}"

            INSTRUCTIONS:
            1. **Budget Calculation**: Based on the price range mentioned (e.g., 30,000 to 45,000), use the HIGHEST value (e.g., 45000) as the base 'Original Budget'.
            2. **Design Packages**: Create three distinct packages based on this base budget:
            * **Package 1 (Essential)**: Target Price is 10% LESS than the base budget. Tags should focus on "Value" and "Efficiency".
            * **Package 2 (Standard)**: Target Price is EQUAL to the base budget. Tags should focus on "Quality" and "Atmosphere".
            * **Package 3 (Premium)**: Target Price is 10% MORE than the base budget. Tags should focus on "Luxury" and "High-End".
            3. **Required Services**: For the determined event type (e.g., Wedding), each package MUST specify the required services in order of priority (Venue, Photography, Catering, etc.) and assign specific AI search tags for each service based on the package's quality level.

            Return the result as a raw JSON object ONLY, adhering to the required schema: AiSearchBlueprint.
        `;

        try {
            const response = await this.ai.models.generateContent({
                model: 'gemini-2.5-flash',
                contents: prompt,
                config: {
                    responseMimeType: "application/json",
                    // 🛑 تحديث الـ Schema هنا ليتطابق مع AiSearchBlueprint
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
                                                    categoryName: { type: "string", description: "e.g., Venue, Photography, Catering" },
                                                    priority: { type: "number", description: "1 is highest priority" },
                                                    budgetWeight: { type: "number", description: "Approximate percentage of total price this service should consume (e.g., 0.5 for venue)" },
                                                    aiTags: { type: "array", items: { type: "string" }, description: "Specific tags to search for (e.g., 'Grand Hall', 'Professional Team')" }
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
                this.logger.error(`Gemini returned empty response for prompt: ${userPrompt.substring(0, 50)}...`);
                throw new Error('Gemini API returned an empty or invalid text response.');
            }

            const jsonText = response.text.trim();
            const filters: AiSearchFilters = JSON.parse(jsonText);
            
            this.logger.log(`AI Filters extracted successfully: ${JSON.stringify(filters)}`);

            if (filters.priceRange) {
                filters.priceRange.min = Number(filters.priceRange.min);
                filters.priceRange.max = Number(filters.priceRange.max);
            }

            const blueprint: AiSearchBlueprint = JSON.parse(jsonText);
            return blueprint

        } catch (error) {
            this.logger.error(`AI Search API Error:`, error);
            throw new Error(`Failed to extract search filters using AI: ${error.message}`);
        }
    }
}